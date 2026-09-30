//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 24  Brian Frank  Creation
//
package fan.sql;

import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;
import java.sql.*;
import fan.sys.*;

public class SqlConnPoolPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static SqlConnPoolPeer make(SqlConnPool fan)
  {
    return new SqlConnPoolPeer();
  }

  // Daemon threads, named so a stack dump identifies the pool and role
  private ThreadFactory threadFactory(final String role)
  {
    return new ThreadFactory()
    {
      public Thread newThread(Runnable r)
      {
        Thread t = new Thread(r, "sqlConnPool-" + poolNum + "-" + role);
        t.setDaemon(true);
        return t;
      }
    };
  }

  // Must run after the Fantom it-block, which is where houseKeepingInterval
  // is set; the peer itself is constructed before that
  public void startHouseKeeping(final SqlConnPool self)
  {
    this.bookkeeper = Executors.newSingleThreadScheduledExecutor(threadFactory("houseKeeping"));

    long ms = self.houseKeepingInterval.millis();
    // fixed delay, not fixed rate, so a slow pass cannot let passes pile up
    this.bookkeeper.scheduleWithFixedDelay(new Runnable()
    {
      public void run()
      {
        // an uncaught throwable would cancel the schedule
        try { onHouseKeeping(self); }
        catch (Throwable e) { self.log.err("SqlConnPool houseKeeping failed", Err.make(e)); }
      }
    }, ms, ms, TimeUnit.MILLISECONDS);
  }

//////////////////////////////////////////////////////////////////////////
// SqlConnPool
//////////////////////////////////////////////////////////////////////////

  public void execute(SqlConnPool self, Func f)
    throws Throwable
  {
    Entry entry = allocate(self);
    synchronized (this) { checkouts++; }
    try
    {
      f.call(entry.conn);
    }
    catch (Throwable e)
    {
      // if the error left the connection broken then evict it
      // from the pool instead of releasing it back for reuse
      if (validate(self, entry)) release(self, entry);
      else
      {
        self.log.warn("SqlConnPool evicting broken connection: " + entry.conn);
        evict(self, entry);
      }
      throw e;
    }
    release(self, entry);
  }

  public boolean isClosed(SqlConnPool self)
  {
    return closed;
  }

  public void close(SqlConnPool self)
  {
    // remove all entries under the lock, then close them outside
    // the lock since closing may block on network I/O; wake any
    // blocked allocators so they fail fast instead of timing out
    ArrayList<Entry> toClose;
    synchronized (this)
    {
      if (closed) return;
      closed = true;
      toClose = entries;
      entries = new ArrayList<>();
      notifyAll();
    }

    // outside the lock: a pass blocked on the monitor would deadlock
    // shutdown.  Connects still in flight are closed by openReserved,
    // which discards them once the pool is closed.
    if (bookkeeper != null) bookkeeper.shutdownNow();
    connector.shutdownNow();

    for (int i=0; i<toClose.size(); ++i)
      close(self, toClose.get(i));
  }

  public void onHouseKeeping(SqlConnPool self)
  {
    // remove expired entries under the lock, then close them
    // outside the lock since closing may block on network I/O
    ArrayList<Entry> expired = new ArrayList<>();
    ArrayList<Entry> toPing = new ArrayList<>();
    synchronized (this)
    {
      // close has already taken the entries
      if (closed) return;

      long now = Duration.nowTicks();
      long linger = self.linger.ticks();
      long maxLifetime = self.maxLifetime.ticks();

      // warn once per checkout for connections held in-use
      // suspiciously long; likely a stuck query or hung callback
      long leakWarn = self.leakWarn.ticks();
      for (int i=0; i<entries.size(); ++i)
      {
        Entry entry = entries.get(i);
        // a slot still opening is not a checkout
        if (entry.inUse && !entry.opening && !entry.leakWarned && (now - entry.useStart) > leakWarn)
        {
          entry.leakWarned = true;
          leakWarnings++;
          String msg = "SqlConnPool connection held in-use longer than " + self.leakWarn + ": " + entry.conn;
          if (entry.checkoutTrace == null) self.log.warn(msg);
          else self.log.warn(msg, Err.make(entry.checkoutTrace));
        }
      }

      // check common case efficiently just to see if we have any to close
      boolean anyToClose = false;
      for (int i=0; i<entries.size(); ++i)
      {
        Entry entry = entries.get(i);
        if (isExpired(entry, now, linger, maxLifetime)) { anyToClose = true; break; }
      }

      if (anyToClose)
      {
        // build new lists of entries to close and keep
        ArrayList<Entry> keep = new ArrayList<>(entries.size());
        for (int i=0; i<entries.size(); ++i)
        {
          Entry entry = entries.get(i);
          if (isExpired(entry, now, linger, maxLifetime)) { expired.add(entry); retired++; }
          else keep.add(entry);
        }
        this.entries = keep;
      }

      // reserve under the lock so a ping cannot race a checkout; the ping
      // itself runs below, outside the lock.  Expiry ran first, so
      // anything already past linger is gone rather than pinged.
      if (self.keepAliveInterval != null)
      {
        long keepAlive = self.keepAliveInterval.ticks();
        for (int i=0; i<entries.size(); ++i)
        {
          Entry entry = entries.get(i);
          if (entry.inUse || entry.opening || entry.pinging) continue;
          if ((now - entry.lastUse) < keepAlive) continue;
          entry.pinging = true;
          toPing.add(entry);
        }
      }
    }

    for (int i=0; i<expired.size(); ++i)
      close(self, expired.get(i));

    if (!toPing.isEmpty()) keepAlive(self, toPing);
  }

  // Ping reserved idle connections, outside the pool lock.  Must not
  // touch lastUse: a ping is not a use, and counting it as one would hold
  // connections open past linger indefinitely.
  private void keepAlive(SqlConnPool self, ArrayList<Entry> toPing)
  {
    ArrayList<Entry> dead = new ArrayList<>();
    for (int i=0; i<toPing.size(); ++i)
    {
      Entry entry = toPing.get(i);
      boolean ok = validate(self, entry);
      synchronized (this)
      {
        entry.pinging = false;

        // pool closed during the ping; close already took this connection
        if (closed) continue;

        if (!ok) { entries.remove(entry); dead.add(entry); evicted++; notifyAll(); }
      }
    }

    for (int i=0; i<dead.size(); ++i)
    {
      Entry entry = dead.get(i);
      self.log.warn("SqlConnPool keepAlive evicting dead connection: " + entry.conn);
      close(self, entry);
    }
  }

  private static boolean isExpired(Entry entry, long now, long linger, long maxLifetime)
  {
    if (entry.inUse || entry.pinging) return false;
    return (now - entry.lastUse) > linger ||
           (now - entry.created) > maxLifetime;
  }

  private Entry allocate(SqlConnPool self)
    throws InterruptedException
  {
    long deadline = System.nanoTime()/1000000L + self.checkoutTimeout.millis();
    while (true)
    {
      Entry entry = allocateEntry(self, deadline);

      // a reserved slot has no connection yet; open it here, holding no
      // lock.  A failed open must release the slot or the pool leaks
      // capacity permanently.
      if (entry.opening)
      {
        try { openReserved(self, entry); }
        catch (Throwable e) { releaseReserved(self, entry); throw e; }
        return entry;
      }

      // skip the ping if disabled, or if the entry was used recently
      Duration validateAfterIdle = self.validateAfterIdle;
      if (validateAfterIdle == null) return entry;
      long idle = Duration.nowTicks() - entry.lastUse;
      if (idle < validateAfterIdle.ticks()) return entry;

      // ping connection to verify it is still alive; if not then
      // close it, discard it from the pool, and allocate again
      if (validate(self, entry)) return entry;
      self.log.warn("SqlConnPool evicting broken connection: " + entry.conn);
      evict(self, entry);
    }
  }

  private synchronized Entry allocateEntry(SqlConnPool self, long deadline)
    throws InterruptedException
  {
    while (true)
    {
      // check that we aren't closed
      if (closed) throw Err.make("SqlConnPool is closed");

      // try to find an available entry or open a new one
      Entry entry = doAllocate(self);
      if (entry != null) return entry;

      // check if we have waited past our deadline
      long toSleep = deadline - System.nanoTime()/1000000L;
      if (toSleep <= 0)
      {
        checkoutTimeouts++;
        throw TimeoutErr.make("SqlConn cannot be acquired (" + self.checkoutTimeout + ")");
      }

      // sleep until we get a notify
      waiting++;
      try { wait(toSleep); }
      finally { waiting--; }
    }
  }

  private boolean validate(SqlConnPool self, Entry entry)
  {
    try
    {
      return entry.conn.isValid(self.validationTimeout);
    }
    catch (Throwable e)
    {
      return false;
    }
  }

  private void evict(SqlConnPool self, Entry entry)
  {
    // remove from pool under lock, but close outside the
    // lock since closing may block on network I/O
    synchronized (this) { entries.remove(entry); evicted++; notifyAll(); }
    close(self, entry);
  }

  private Entry doAllocate(SqlConnPool self)
  {
    // find most recently used entry that is not currently in use
    Entry entry = null;
    for (int i=0; i<entries.size(); ++i)
    {
      Entry x = entries.get(i);
      if (x.inUse || x.pinging) continue;
      if (entry == null || x.lastUse > entry.lastUse) entry = x;
    }

    // if we found one, mark it used and allocate
    if (entry != null)
    {
      entry.inUse = true;
      entry.useStart = Duration.nowTicks();
      if (self.leakTrace) entry.checkoutTrace = new Throwable("checked out here");
      return entry;
    }

    // reserve a slot without opening it: this runs under the pool lock,
    // which every release and allocate needs, and opening blocks on
    // network I/O.  The caller opens outside the lock via openReserved.
    // Reserving under the lock bounds maxConns while an open is in
    // flight.
    if (entries.size() < self.maxConns)
    {
      entry = new Entry();
      entry.inUse = true;
      entry.opening = true;
      entry.created = Duration.nowTicks();
      entry.lastUse = entry.created;
      entry.useStart = entry.created;
      if (self.leakTrace) entry.checkoutTrace = new Throwable("checked out here");
      entries.add(entry);
      return entry;
    }

    // no joy
    return null;
  }

  // Open the connection for a reserved slot, outside the pool lock, and
  // publish it into the entry.  The entry is already in the pool marked
  // inUse, so no other thread can hand it out while this runs.
  private void openReserved(SqlConnPool self, Entry entry)
  {
    SqlConn conn = open(self);

    boolean stale = false;
    synchronized (this)
    {
      // pool closed during the open; close() already took the entry list
      if (closed) stale = true;
      else
      {
        entry.conn = conn;
        entry.opening = false;
        opened++;
      }
    }

    if (stale)
    {
      close(self, conn);
      throw Err.make("SqlConnPool is closed");
    }
  }

  // Release a reserved slot whose open failed
  private void releaseReserved(SqlConnPool self, Entry entry)
  {
    // notify: the slot a waiter was blocked on is free again
    synchronized (this) { entries.remove(entry); notifyAll(); }
  }

  private void release(SqlConnPool self, Entry entry)
  {
    // reset the connection so the next borrower gets a clean
    // slate; if the reset fails then evict the connection
    try
    {
      // roll back any uncommitted work first; must happen before
      // restoring auto-commit since setAutoCommit(true) on a
      // dangling transaction would commit it
      if (!entry.conn.autoCommit()) entry.conn.rollback();

      // restore pool's auto-commit mode in case callback changed it
      boolean poolMode = self.autoCommit();
      if (entry.conn.autoCommit() != poolMode) entry.conn.autoCommit(poolMode);
    }
    catch (Throwable e)
    {
      self.log.warn("SqlConnPool evicting broken connection: " + entry.conn);
      evict(self, entry);
      return;
    }

    synchronized (this)
    {
      entry.inUse = false;
      entry.leakWarned = false;
      entry.checkoutTrace = null;
      entry.lastUse = Duration.nowTicks();
      notifyAll();
    }
  }

  private SqlConn open(SqlConnPool self)
  {
    SqlConn c = connect(self);
    try
    {
      // set auto-commit based on connection pool property
      c.autoCommit(self.autoCommit());

      // statements created on this connection inherit the pool's timeout
      c.setQueryTimeout(self.queryTimeout);

      self.onOpen(c);
    }
    // nothing else holds a reference to this connection; onOpen did not
    // complete, so onClose is not called
    catch (RuntimeException e) { closeQuietly(c); throw e; }
    catch (Error e)            { closeQuietly(c); throw e; }
    return c;
  }

  // Open the JDBC connection on the connect executor so connectTimeout
  // can bound it without driver support
  private SqlConn connect(final SqlConnPool self)
  {
    final AtomicReference<Object> holder = new AtomicReference<Object>();
    Future<?> future = connector.submit(new Runnable()
    {
      public void run()
      {
        SqlConn c = SqlConnImpl.openDefault(self.uri, self.username, self.password);

        // the caller may have given up while we were connecting
        if (!holder.compareAndSet(null, c)) closeQuietly(c);
      }
    });

    try
    {
      if (self.connectTimeout == null) future.get();
      else future.get(self.connectTimeout.millis(), TimeUnit.MILLISECONDS);
    }
    catch (TimeoutException e)
    {
      // best effort only: a driver blocked in a socket connect does not
      // answer an interrupt, so abandon must handle a late arrival
      future.cancel(true);
      abandon(holder);
      throw TimeoutErr.make("SqlConn open exceeded connectTimeout (" + self.connectTimeout + ")");
    }
    catch (ExecutionException e)
    {
      Throwable cause = e.getCause();
      if (cause instanceof RuntimeException) throw (RuntimeException)cause;
      if (cause instanceof Error) throw (Error)cause;
      throw Err.make(cause);
    }
    catch (InterruptedException e)
    {
      future.cancel(true);
      abandon(holder);
      Thread.currentThread().interrupt();
      throw Err.make(e);
    }

    Object v = holder.get();
    if (v instanceof SqlConn) return (SqlConn)v;
    throw Err.make("SqlConn open produced no connection");
  }

  // Give up on an in flight connect.  Exactly one of the two parties
  // claims the holder: if this call wins, the connect task closes the
  // connection when it lands; if the task won, close it here.
  private void abandon(AtomicReference<Object> holder)
  {
    if (holder.compareAndSet(null, ABANDONED)) return;
    Object v = holder.get();
    if (v instanceof SqlConn) closeQuietly((SqlConn)v);
  }

  private static void closeQuietly(SqlConn c)
  {
    try { c.close(); } catch (Throwable e) {}
  }

  private void close(SqlConnPool self, Entry entry)
  {
    // a reserved slot whose open never completed
    if (entry.conn == null) return;
    close(self, entry.conn);
  }

  private void close(SqlConnPool self, SqlConn conn)
  {
    self.onClose(conn);
    conn.close();
  }

  public synchronized SqlConnPoolStats stats(SqlConnPool self)
  {
    int total = entries.size();
    int active = 0;
    for (int i=0; i<entries.size(); ++i)
      if (entries.get(i).inUse) active++;

    return SqlConnPoolStats.make(total, active, total-active, waiting, self.maxConns,
      checkouts, checkoutTimeouts, opened, retired, evicted, leakWarnings);
  }

  public synchronized String debug(SqlConnPool self)
  {
    int idle = 0;
    int inUse = 0;
    for (int i=0; i<entries.size(); ++i)
      if (entries.get(i).inUse) inUse++; else idle++;

    StringBuilder s = new StringBuilder();
    s.append("SqlConnPool\n");
    s.append("  uri:      ").append(self.uri).append("\n");
    s.append("  maxConns: ").append(self.maxConns).append("\n");
    s.append("  linger:   ").append(self.linger).append("\n");
    s.append("  maxLifetime: ").append(self.maxLifetime).append("\n");
    s.append("  idle:     ").append(idle).append("\n");
    s.append("  inUse:    ").append(inUse).append("\n");
    s.append("  entries:  ").append(entries.size()).append("\n");
    s.append("  waiting:  ").append(waiting).append("\n");
    s.append("  checkouts: ").append(checkouts).append("\n");
    s.append("  checkoutTimeouts: ").append(checkoutTimeouts).append("\n");
    s.append("  opened:   ").append(opened).append("\n");
    s.append("  retired:  ").append(retired).append("\n");
    s.append("  evicted:  ").append(evicted).append("\n");
    s.append("  leakWarnings: ").append(leakWarnings).append("\n");
    for (int i=0; i<entries.size(); ++i)
      s.append("    ").append(entries.get(i)).append("\n");
    return s.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Entry
//////////////////////////////////////////////////////////////////////////

  static class Entry
  {
    SqlConn conn;         // open connection; null while opening
    long created;         // Duration.ticks when the slot was reserved
    boolean inUse;        // is this entry currently being used
    boolean opening;      // slot reserved, connection not yet opened
    boolean pinging;      // held by a keepAlive ping; not available
    long lastUse;         // Duration.ticks of last execute
    long useStart;        // Duration.ticks when current use began
    boolean leakWarned;   // have we warned about current use being stuck
    Throwable checkoutTrace; // checkout site, captured when leakTrace is on

    public String toString()
    {
      if (opening) return "Entry opening";
      Duration age = Duration.make(Duration.nowTicks() - lastUse);
      return "Entry " + conn + " inUse=" + inUse + " age=" + age.toLocale();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // names the threads of each pool in this JVM
  private static final AtomicInteger poolCounter = new AtomicInteger();

  // holder sentinel: the caller stopped waiting for an in flight connect
  private static final Object ABANDONED = new Object();


  private final int poolNum = poolCounter.incrementAndGet();

  // cached, not single threaded: opens run concurrently up to maxConns,
  // and a single thread would re-serialize them
  private final ExecutorService connector =
    Executors.newCachedThreadPool(threadFactory("connect"));

  private ArrayList<Entry> entries = new ArrayList<>();
  private ScheduledExecutorService bookkeeper;
  private boolean closed;

  // written and read under the pool lock, so a stats snapshot is
  // consistent without atomics
  private int waiting;
  private long checkouts;
  private long checkoutTimeouts;
  private long opened;
  private long retired;
  private long evicted;
  private long leakWarnings;
}

