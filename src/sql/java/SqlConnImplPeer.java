//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jun 07  Brian Frank  Creation
//
package fan.sql;

import java.sql.*;
import java.util.Enumeration;
import java.util.Properties;
import java.util.StringTokenizer;
import fan.sys.*;

public class SqlConnImplPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static SqlConnImplPeer make(SqlConnImpl fan)
  {
    return new SqlConnImplPeer();
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public static SqlConn openDefault(String uri, String user, String pass)
  {
    return open(uri, user, pass, null);
  }

  // Open with an optional timeout enforced by the driver on its own
  // socket: connectTimeout bounds the TCP connect, socketTimeout bounds
  // the handshake and is then cleared so it cannot cut off a query.  Not
  // loginTimeout: pgjdbc runs that on a thread it abandons on timeout.
  static SqlConn open(String uri, String user, String pass, Duration timeout)
  {
    try
    {
      SqlConnImpl self = SqlConnImpl.make();
      if (uri.equals("test")) return TestSqlConn.make();

      // test hook "test:<millis>": a slow connect
      if (uri.startsWith("test:"))
      {
        long end = System.currentTimeMillis() + Long.parseLong(uri.substring(5));
        while (System.currentTimeMillis() < end)
          { try { Thread.sleep(10); } catch (InterruptedException e) {} }
        return TestSqlConn.make();
      }

      // no user is certificate auth
      Properties props = new Properties();
      if (user != null) props.setProperty("user", user);
      if (pass != null) props.setProperty("password", pass);
      if (timeout != null)
      {
        // whole seconds, rounded up; 0 would mean no timeout
        String secs = String.valueOf(Math.max(1L, (timeout.millis() + 999L) / 1000L));
        props.setProperty("connectTimeout", secs);
        props.setProperty("socketTimeout", secs);
      }

      try
      {
        self.peer.jconn = DriverManager.getConnection(uri, props);
      }
      catch (SQLException e)
      {
        if (timeout != null && isTimeout(e))
          throw TimeoutErr.make("SqlConn open exceeded connectTimeout (" + timeout + ")");
        throw e;
      }

      try
      {
        if (timeout != null) self.peer.jconn.setNetworkTimeout(DIRECT, 0);
      }
      catch (SQLFeatureNotSupportedException e) {}
      catch (SQLException e) { self.peer.jconn.close(); throw e; }

      self.peer.supportsGetGenKeys = self.peer.jconn.getMetaData().supportsGetGeneratedKeys();
      return self;
    }
    catch (SQLException e)
    {
      throw err(e);
    }
  }

  // setNetworkTimeout requires an executor; clearing the timeout needs none
  private static final java.util.concurrent.Executor DIRECT = new java.util.concurrent.Executor()
  {
    public void execute(Runnable r) { r.run(); }
  };

  private static boolean isTimeout(Throwable e)
  {
    for (; e != null; e = e.getCause())
      if (e instanceof java.net.SocketTimeoutException) return true;
    return false;
  }

  public static SqlConn wrapConnection(java.sql.Connection jconn)
  {
    try
    {
        SqlConnImpl self = SqlConnImpl.make();
        self.peer.jconn = jconn;
        self.peer.supportsGetGenKeys = self.peer.jconn.getMetaData().supportsGetGeneratedKeys();
        return self;
    }
    catch (SQLException e)
    {
        throw err(e);
    }
  }

  public boolean isClosed(SqlConnImpl self)
  {
    try
    {
      return jconn.isClosed();
    }
    catch (SQLException e)
    {
      throw err(e);
    }
  }

  public boolean isValid(SqlConnImpl self, Duration timeout)
  {
    try
    {
      int secs = SqlUtil.toJdbcSeconds(timeout.millis());
      return jconn.isValid(secs);
    }
    catch (Throwable e)
    {
      return false;
    }
  }

  public boolean close(SqlConnImpl self)
  {
    try
    {
      jconn.close();
      return true;
    }
    catch (Throwable e)
    {
      e.printStackTrace();
      return false;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Data
//////////////////////////////////////////////////////////////////////////

  public SqlMeta meta(SqlConnImpl self)
  {
    try
    {
      SqlMeta meta = new SqlMeta();
      meta.peer.jmeta = jconn.getMetaData();
      return meta;
    }
    catch (SQLException ex)
    {
      throw err(ex);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  public boolean autoCommit(SqlConnImpl self)
  {
    try
    {
      return jconn.getAutoCommit();
    }
    catch (SQLException e)
    {
      throw err(e);
    }
  }

  public void autoCommit(SqlConnImpl self, boolean b)
  {
    try
    {
      jconn.setAutoCommit(b);
    }
    catch (SQLException e)
    {
      throw err(e);
    }
  }

  public void commit(SqlConnImpl self)
  {
    try
    {
      jconn.commit();
    }
    catch (SQLException e)
    {
      throw err(e);
    }
  }

  public void rollback(SqlConnImpl self)
  {
    try
    {
      jconn.rollback();
    }
    catch (SQLException e)
    {
      throw err(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Load Driver
//////////////////////////////////////////////////////////////////////////

  static { loadDrivers(); }
  private static String loadDebug;

  static void loadDrivers()
  {
    StringBuilder s = new StringBuilder();
    s.append("SqlConn.init:\n");
    try
    {
      String val = Pod.find("sql").config("java.drivers");
      s.append("  java.drivers=").append(val).append("\n");

      if (val != null)
      {
        s.append("\nSqlConn.preload:\n");
        String[] classNames = val.split(",");
        for (int i=0; i<classNames.length; ++i)
        {
          String className = classNames[i].trim();
          try
          {
            Class.forName(className);
            s.append("  " + className + " [ok]\n");
          }
          catch (Exception e)
          {
            System.out.println("WARNING: Cannot preload JDBC driver: " + className);
            s.append("  " + className + " [" + e + "]\n");
          }
        }
      }
    }
    catch (Throwable e)
    {
      System.out.println(e);
      s.append("ERROR: " + e + "\n");
    }
    loadDebug = s.toString();
  }

  public static String debugDrivers()
  {
    StringBuilder s = new StringBuilder();
    s.append("DriverManager.getDrivers:\n");
    Enumeration e = DriverManager.getDrivers();
    while (e.hasMoreElements())
    {
      Driver d = (Driver)e.nextElement();
      s.append("  " + d.getClass().getName() + " [v" + d.getMajorVersion() + "." + d.getMinorVersion() + "]\n");
    }
    s.append("\n").append(loadDebug);
    return s.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static RuntimeException err(SQLException e)
  {
    return SqlErr.make(e.getMessage(), Err.make(e));
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  java.sql.Connection jconn;
  Map meta;
  boolean supportsGetGenKeys;
}

