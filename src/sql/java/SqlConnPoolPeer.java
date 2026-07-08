//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 24  Brian Frank  Creation
//
package fan.sql;

import java.util.*;
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

//////////////////////////////////////////////////////////////////////////
// SqlConnPool
//////////////////////////////////////////////////////////////////////////

  public void execute(SqlConnPool self, Func f)
    throws Throwable
  {
    Entry entry = allocate(self);
    try
    {
      f.call(entry.conn);
    }
    catch (Throwable e)
    {
      // if the error left the connection broken then evict it
      // from the pool instead of releasing it back for reuse
      if (validate(entry)) release(self, entry);
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
    for (int i=0; i<toClose.size(); ++i)
      close(self, toClose.get(i));
  }

  public void checkLinger(SqlConnPool self)
  {
    // remove expired entries under the lock, then close them
    // outside the lock since closing may block on network I/O
    ArrayList<Entry> expired;
    synchronized (this)
    {
      long now = Duration.nowTicks();
      long linger = self.linger.ticks();
      long maxLifetime = self.maxLifetime.ticks();

      // warn once per checkout for connections held in-use
      // suspiciously long; likely a stuck query or hung callback
      long leakWarn = self.leakWarn.ticks();
      for (int i=0; i<entries.size(); ++i)
      {
        Entry entry = entries.get(i);
        if (entry.inUse && !entry.leakWarned && (now - entry.useStart) > leakWarn)
        {
          entry.leakWarned = true;
          self.log.warn("SqlConnPool connection held in-use longer than " + self.leakWarn + ": " + entry.conn);
        }
      }

      // check common case efficiently just to see if we have any to close
      boolean anyToClose = false;
      for (int i=0; i<entries.size(); ++i)
      {
        Entry entry = entries.get(i);
        if (isExpired(entry, now, linger, maxLifetime)) { anyToClose = true; break; }
      }
      if (!anyToClose) return;

      // build new lists of entries to close and keep
      ArrayList<Entry> keep = new ArrayList<>(entries.size());
      expired = new ArrayList<>();
      for (int i=0; i<entries.size(); ++i)
      {
        Entry entry = entries.get(i);
        if (isExpired(entry, now, linger, maxLifetime)) expired.add(entry);
        else keep.add(entry);
      }
      this.entries = keep;
    }
    for (int i=0; i<expired.size(); ++i)
      close(self, expired.get(i));
  }

  private static boolean isExpired(Entry entry, long now, long linger, long maxLifetime)
  {
    if (entry.inUse) return false;
    return (now - entry.lastUse) > linger ||
           (now - entry.created) > maxLifetime;
  }

  private Entry allocate(SqlConnPool self)
    throws InterruptedException
  {
    long deadline = System.nanoTime()/1000000L + self.timeout.millis();
    while (true)
    {
      Entry entry = allocateEntry(self, deadline);

      // skip validation if entry was used recently, which
      // includes connections just opened by doAllocate
      long idle = Duration.nowTicks() - entry.lastUse;
      if (idle < validateThreshold) return entry;

      // ping connection to verify it is still alive; if not then
      // close it, discard it from the pool, and allocate again
      if (validate(entry)) return entry;
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
        throw TimeoutErr.make("SqlConn cannot be acquired (" + self.timeout + ")");

      // sleep until we get a notify
      wait(toSleep);
    }
  }

  private boolean validate(Entry entry)
  {
    // pool only creates SqlConnImpl; treat anything else as valid
    if (!(entry.conn instanceof SqlConnImpl)) return true;
    try
    {
      return ((SqlConnImpl)entry.conn).peer.jconn.isValid(validateTimeout);
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
    synchronized (this) { entries.remove(entry); notifyAll(); }
    close(self, entry);
  }

  private Entry doAllocate(SqlConnPool self)
  {
    // find most recently used entry that is not currently in use
    Entry entry = null;
    for (int i=0; i<entries.size(); ++i)
    {
      Entry x = entries.get(i);
      if (x.inUse) continue;
      if (entry == null || x.lastUse > entry.lastUse) entry = x;
    }

    // if we found one, mark it used and allocate
    if (entry != null)
    {
      entry.inUse = true;
      entry.useStart = Duration.nowTicks();
      return entry;
    }

    // allocate a new entry
    if (entries.size() < self.maxConns)
    {
      entry = new Entry(open(self));
      entry.inUse = true;
      entry.useStart = entry.created;
      entries.add(entry);
      return entry;
    }

    // no joy
    return null;
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
      entry.lastUse = Duration.nowTicks();
      notifyAll();
    }
  }

  private SqlConn open(SqlConnPool self)
  {
    // bound how long a connect may block; note this is a JVM
    // wide setting on DriverManager (see SqlConnPool fandoc)
    if (self.connectTimeout != null)
      DriverManager.setLoginTimeout((int)self.connectTimeout.toSec());

    SqlConn c = SqlConnImpl.openDefault(self.uri, self.username, self.password);

    // set auto-commit based on connection pool property
    c.autoCommit(self.autoCommit());

    self.onOpen(c);
    return c;
  }

  private void close(SqlConnPool self, Entry entry)
  {
    self.onClose(entry.conn);
    entry.conn.close();
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
    for (int i=0; i<entries.size(); ++i)
      s.append("    ").append(entries.get(i)).append("\n");
    return s.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Entry
//////////////////////////////////////////////////////////////////////////

  static class Entry
  {
    Entry(SqlConn conn)
    {
      this.conn    = conn;
      this.created = Duration.nowTicks();
      this.lastUse = this.created;
    }

    final SqlConn conn;   // open connection
    final long created;   // Duration.ticks when connection was opened
    boolean inUse;        // is this entry currently being used
    long lastUse;         // Duration.ticks of last execute
    long useStart;        // Duration.ticks when current use began
    boolean leakWarned;   // have we warned about current use being stuck

    public String toString()
    {
      Duration age = Duration.make(Duration.nowTicks() - lastUse);
      return "Entry " + conn + " inUse=" + inUse + " age=" + age.toLocale();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // only validate a connection on borrow if it has been idle
  // longer than this threshold (in Duration ticks)
  private static final long validateThreshold = 500L * 1000000L;  // 500ms

  // seconds passed to java.sql.Connection.isValid on borrow
  private static final int validateTimeout = 3;

  private ArrayList<Entry> entries = new ArrayList<>();
  private boolean closed;
}

