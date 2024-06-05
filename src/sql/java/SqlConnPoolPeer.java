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
    Throwable err = null;
    try
    {
      f.call(entry.conn);
    }
    catch (Throwable e)
    {
      err = e;
    }
    release(self, entry);
    if (err != null) throw err;
  }

  public boolean isClosed(SqlConnPool self)
  {
    return closed;
  }

  public synchronized void close(SqlConnPool self)
  {
    if (closed) return;
    closed = true;
    for (int i=0; i<entries.size(); ++i)
      close(self, entries.get(i));
    entries.clear();
  }

  public synchronized void checkLinger(SqlConnPool self)
  {
    long now = Duration.nowTicks();
    long linger = self.linger.ticks();

    // check common case efficiently just to see if we have any to close
    boolean anyToClose = false;
    for (int i=0; i<entries.size(); ++i)
    {
      Entry entry = entries.get(i);
      boolean expired = (now - entry.lastUse) > linger;
      if (expired) { anyToClose = true; break; }
    }
    if (!anyToClose) return;

    // close expired entries and build new list of entries to keep
    ArrayList<Entry> keep = new ArrayList<>(entries.size());
    for (int i=0; i<entries.size(); ++i)
    {
      Entry entry = entries.get(i);
      boolean expired = (now - entry.lastUse) > linger;
      if (expired) close(self, entry);
      else keep.add(entry);
    }
    this.entries = keep;
  }

  private synchronized Entry allocate(SqlConnPool self)
    throws InterruptedException
  {
    // try top find an available entry
    Entry entry = doAllocate(self);
    if (entry != null) return entry;

    // block until one frees up
    long msTimeout = self.timeout.millis();
    long deadline = System.nanoTime()/1000000L + msTimeout;
    while (true)
    {
      // check if we have waited past our deadline
      long toSleep = deadline - System.nanoTime()/1000000L;
      if (toSleep <= 0) break;

      // sleep until we get a notify
      wait(toSleep);

      // try again
      entry = doAllocate(self);
      if (entry != null) return entry;
    }

    // raise timeout error
    throw TimeoutErr.make("SqlConn cannot be acquired (" + self.timeout + ")");
  }

  private Entry doAllocate(SqlConnPool self)
  {
    // check that we aren't closed
    if (closed) throw Err.make("SqlConnPool is closed");

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
      return entry;
    }

    // allocate a new entry
    if (entries.size() < self.maxConns)
    {
      entry = new Entry(open(self));
      entry.inUse = true;
      entries.add(entry);
      return entry;
    }

    // no joy
    return null;
  }

  private synchronized void release(SqlConnPool self, Entry entry)
  {
    entry.inUse = false;
    entry.lastUse = Duration.nowTicks();
    notifyAll();
  }

  private SqlConn open(SqlConnPool self)
  {
    return SqlConnImpl.openDefault(self.uri, self.username, self.password);
  }

  private void close(SqlConnPool self, Entry entry)
  {
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
    s.append("  linger:   ").append(self.maxConns).append("\n");
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
      this.lastUse = Duration.nowTicks();
    }

    final SqlConn conn;   // open connection
    boolean inUse;        // is this entry currently being used
    long lastUse;         // Duration.ticks of last execute

    public String toString()
    {
      Duration age = Duration.make(Duration.nowTicks() - lastUse);
      return "Entry " + conn + " inUse=" + inUse + " age=" + age.toLocale();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private ArrayList<Entry> entries = new ArrayList<>();
  private boolean closed;
}

