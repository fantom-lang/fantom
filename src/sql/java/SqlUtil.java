//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Jul 07  Brian Frank  Creation
//
package fan.sql;

import java.sql.*;
import fan.sys.*;
import fan.sys.Float;

public class SqlUtil
{
  /**
   * Map an java.sql.Types code to a Fan type.
   */
  public static Type sqlToFanType(int sql)
  {
    switch (sql)
    {
      case Types.CHAR:
      case Types.VARCHAR:
      case Types.LONGVARCHAR:
        return Sys.StrType;

      case Types.BIT:
        return Sys.BoolType;

      case Types.TINYINT:
      case Types.SMALLINT:
      case Types.INTEGER:
      case Types.BIGINT:
        return Sys.IntType;

      case Types.REAL:
      case Types.FLOAT:
      case Types.DOUBLE:
        return Sys.FloatType;

      case Types.BINARY:
      case Types.VARBINARY:
      case Types.LONGVARBINARY:
        return Sys.BufType;

      default:
        return null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// From fa
//////////////////////////////////////////////////////////////////////////

  /**
   * Map an java.sql.ResultSet column to a Fan object.
   */
  public static Obj toObj(ResultSet rs, int col)
    throws SQLException
  {
    switch (rs.getMetaData().getColumnType(col))
    {
      case Types.CHAR:
      case Types.VARCHAR:
      case Types.LONGVARCHAR:
        return Str.make(rs.getString(col));

      case Types.BIT:
        boolean b = rs.getBoolean(col);
        if (rs.wasNull()) return null;
        return Bool.make(b);

      case Types.TINYINT:
      case Types.SMALLINT:
      case Types.INTEGER:
      case Types.BIGINT:
        long i = rs.getLong(col);
        if (rs.wasNull()) return null;
        return Int.make(i);

      case Types.REAL:
      case Types.FLOAT:
      case Types.DOUBLE:
        double f = rs.getDouble(col);
        if (rs.wasNull()) return null;
        return Float.make(f);

      case Types.BINARY:
      case Types.VARBINARY:
      case Types.LONGVARBINARY:
        byte[] buf = rs.getBytes(col);
        if (rs.wasNull()) return null;
        return new MemBuf(buf);

      default:
        return Str.make(String.valueOf(rs.getObject(col)));
    }
  }
  
  /**
   * Map an java.sql.ResultSet column to a Fan object.
   */
  public static SqlToFan converter(ResultSet rs, int col)
    throws SQLException
  {
    switch (rs.getMetaData().getColumnType(col))
    {
      case Types.CHAR:
      case Types.VARCHAR:
      case Types.LONGVARCHAR:
        return new ToFanStr();

      case Types.BIT:
        return new ToFanBool();

      case Types.TINYINT:
      case Types.SMALLINT:
      case Types.INTEGER:
      case Types.BIGINT:
        return new ToFanInt();

      case Types.REAL:
      case Types.FLOAT:
      case Types.DOUBLE:
        return new ToFanFloat();

      case Types.BINARY:
      case Types.VARBINARY:
      case Types.LONGVARBINARY:
        return new ToFanBuf();

      default:
        return new ToDefFanStr();
    }
  }

//////////////////////////////////////////////////////////////////////////
// SqlToFan
//////////////////////////////////////////////////////////////////////////

  public abstract static class SqlToFan
  {
    public abstract Obj toObj(ResultSet rs, int col)
      throws SQLException;
  }
  
  public static class ToFanStr extends SqlToFan
  {
    public Obj toObj(ResultSet rs, int col)
      throws SQLException
    {
      return Str.make(rs.getString(col));
    }
  }
  
  public static class ToFanBool extends SqlToFan
  {
    public Obj toObj(ResultSet rs, int col)
      throws SQLException
    {
      boolean b = rs.getBoolean(col);
      if (rs.wasNull()) return null;
      return Bool.make(b);
    }
  }

  public static class ToFanInt extends SqlToFan
  {
    public Obj toObj(ResultSet rs, int col)
      throws SQLException
    {
      long i = rs.getLong(col);
      if (rs.wasNull()) return null;
      return Int.make(i);
    }
  }
  
  public static class ToFanFloat extends SqlToFan
  {
    public Obj toObj(ResultSet rs, int col)
      throws SQLException
    {
      double f = rs.getDouble(col);
      if (rs.wasNull()) return null;
      return Float.make(f);
    }
  }

  public static class ToFanBuf extends SqlToFan
  {
    public Obj toObj(ResultSet rs, int col)
      throws SQLException
    {
      byte[] buf = rs.getBytes(col);
      if (rs.wasNull()) return null;
      return new MemBuf(buf);
    }
  }
  
  public static class ToDefFanStr extends SqlToFan
  {
    public Obj toObj(ResultSet rs, int col)
      throws SQLException
    {
      return Str.make(String.valueOf(rs.getObject(col)));
    }
  }

}