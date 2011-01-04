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

public class SqlConnPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static SqlConnPeer make(SqlConn fan)
  {
    return new SqlConnPeer();
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public static SqlConn open(String uri, String user, String pass)
  {
    try
    {
      SqlConn self = SqlConn.make();
      self.peer.jconn = DriverManager.getConnection(uri, user, pass);
      self.peer.supportsGetGenKeys = self.peer.jconn.getMetaData().supportsGetGeneratedKeys();
      return self;
    }
    catch (SQLException e)
    {
      throw err(e);
    }
  }

  public boolean isClosed(SqlConn self)
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

  public boolean close(SqlConn self)
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

  public boolean tableExists(SqlConn self, String tableName)
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

  public List tables(SqlConn self)
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

  public Row tableRow(SqlConn self, String tableName)
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

  public Map meta(SqlConn self)
  {
    if (meta != null) return meta;
    try
    {
      Map map = new Map(Sys.StrType, Sys.ObjType.toNullable());
      DatabaseMetaData data = jconn.getMetaData();

      map.set("productName", data.getDatabaseProductName());
      map.set("productVersion", Version.fromStr(""+data.getDatabaseMajorVersion()+"."+data.getDatabaseMinorVersion()));
      map.set("productVersionStr", data.getDatabaseProductVersion());

      map.set("driverName", data.getDriverName());
      map.set("driverVersion", Version.fromStr(""+data.getDriverMajorVersion()+"."+data.getDriverMinorVersion()));
      map.set("driverVersionStr", data.getDriverVersion());

      return this.meta = (Map)map.toImmutable();
    }
    catch (SQLException e)
    {
      throw err(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  public boolean autoCommit(SqlConn self)
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

  public void autoCommit(SqlConn self, boolean b)
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

  public void commit(SqlConn self)
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

  public void rollback(SqlConn self)
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

  static void loadDrivers()
  {
    try
    {
      String val = Pod.find("sql").config("java.drivers");
      if (val == null) return;
      String[] classNames = val.split(",");
      for (int i=0; i<classNames.length; ++i)
      {
        String className = classNames[i].trim();
        try
        {
          Class.forName(className);
        }
        catch (Exception e)
        {
          System.out.println("WARNING: Cannot preload JDBC driver: " + className);
        }
      }
    }
    catch (Throwable e)
    {
      System.out.println(e);
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
  Map meta;
  boolean supportsGetGenKeys;
}