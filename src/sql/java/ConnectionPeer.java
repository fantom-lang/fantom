//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jun 07  Brian Frank  Creation
//
package fan.sql;

import java.sql.*;
import java.util.StringTokenizer;
import fan.sys.*;
import fan.sql.Connection;

public class ConnectionPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static ConnectionPeer make(Connection fan)
  {
    return new ConnectionPeer();
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public static Connection open(String database, String username, String password, Dialect dialect)
  {
    try
    {
      loadDriver(dialect);
      Connection self = Connection.make();
      self.peer.jconn = DriverManager.getConnection(database, username, password);
      self.peer.openCount = 1;
      self.peer.supportsGetGenKeys = self.peer.jconn.getMetaData().supportsGetGeneratedKeys();
      return self;
    }
    catch (SQLException e)
    {
      throw err(e);
    }
  }

  public boolean isClosed(Connection self)
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

  public boolean close(Connection self)
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
// Database metadata
//////////////////////////////////////////////////////////////////////////

  public boolean tableExists(Connection self, String tableName)
  {
    try
    {
      DatabaseMetaData dbData = jconn.getMetaData();
        ResultSet tables =
          dbData.getTables(null,          // catalog
                           null,          // schema pattern
                           tableName,     // table name pattern
                           null);         // types

      boolean exists = tables.next();
      tables.close();
      return exists;
    }
    catch (SQLException ex)
    {
      throw err(ex);
    }
  }

  public List tables(Connection self)
  {
    try
    {
      DatabaseMetaData dbData = jconn.getMetaData();
      ResultSet tables =
        dbData.getTables(null,  // catalog
                         null,  // schema pattern
                         null,  // table name pattern
                         null); // types

      int nameIndex = tables.findColumn("TABLE_NAME");
      List tableList = new List(Sys.StrType, 32);
      while (tables.next())
      {
        String tableName = tables.getString(nameIndex);
        tableList.add(tableName);
      }
      tables.close();

      return tableList.ro();
    }
    catch (SQLException ex)
    {
      throw err(ex);
    }
  }

  public Row tableRow(Connection self, String tableName)
  {
    try
    {
      DatabaseMetaData dbData = jconn.getMetaData();
      ResultSet columns = dbData.getColumns(null, null, tableName, null);

      // map the meta-data to a dynamic type
      List cols = new List(SqlUtil.colType);

      int nameIndex = columns.findColumn("COLUMN_NAME");
      int typeIndex = columns.findColumn("DATA_TYPE");
      int typeNameIndex = columns.findColumn("TYPE_NAME");
      int colIndex = 0;
      while (columns.next())
      {
        String name = columns.getString(nameIndex);
        String typeName = columns.getString(typeNameIndex);
        Type fanType = SqlUtil.sqlToFanType(columns.getInt(typeIndex));
        if (fanType == null)
        {
          System.out.println("WARNING: Cannot map " + typeName + " to Fan type");
          fanType = Sys.StrType;
        }
        cols.add(Col.make(Long.valueOf(colIndex++), name, fanType, typeName));
      }

      if (colIndex == 0)
        throw SqlErr.make("Table not found: " + tableName).val;

      Row row = Row.make();
      row.peer.cols = new Cols(cols);
      row.peer.cells = new Object[cols.sz()];
      return row;
    }
    catch (SQLException ex)
    {
      throw err(ex);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  public boolean getAutoCommit(Connection self)
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

  public void setAutoCommit(Connection self, boolean b)
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

  public void commit(Connection self)
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

  public void rollback(Connection self)
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
// Open Count
//////////////////////////////////////////////////////////////////////////

  public long increment(Connection self)
  {
    return ++openCount;
  }

  public long decrement(Connection self)
  {
    if (openCount != 0) openCount--;
    return openCount;
  }

//////////////////////////////////////////////////////////////////////////
// Load Driver
//////////////////////////////////////////////////////////////////////////

  /**
   * Look for config key {dialect.qname}.driver and attempt to
   * load it as Java classname to ensure driver is in memory.
   */
  static void loadDriver(Dialect d)
  {
    // preload the driver classes defined in sys.props, any
    // property that starts with "sql." and ends with ".driver"
    // is assumed to be a driver class name.
    try
    {
      String key = d.typeof().qname() + ".driver";
      String val = Pod.find("sql").config(key);
      if (val == null) return;
      try
      {
        Class.forName(val);
      }
      catch (Exception e)
      {
        System.out.println("WARNING: Cannot preload JDBC driver: " + key + "=" + val);
      }
    }
    catch (Exception e)
    {
      System.out.println(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Static Init
//////////////////////////////////////////////////////////////////////////

  static Type rowType;
  static List listOfRow;
  static
  {
    try
    {
      rowType = Type.find("sql::Row", true);
      listOfRow = new List(Sys.TypeType, new Type[] { rowType });
    }
    catch (Exception e)
    {
      e.printStackTrace();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static RuntimeException err(SQLException e)
  {
    return SqlErr.make(e.getMessage(), Err.make(e)).val;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  java.sql.Connection jconn;
  int openCount;
  boolean supportsGetGenKeys;
}