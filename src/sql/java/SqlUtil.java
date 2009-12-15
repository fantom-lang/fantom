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

public class SqlUtil
{

  /**
   * Type literal for sql::Col
   */
  public static final Type colType;
  static
  {
    Type t = null;
    try { t = Type.find("sql::Col"); }
    catch (Exception e) { e.printStackTrace(); }
    colType = t;
  }

  /**
   * Type literal for sql::Row
   */
  public static final Type rowType;
  static
  {
    Type t = null;
    try { t = Type.find("sql::Row"); }
    catch (Exception e) { e.printStackTrace(); }
    rowType = t;
  }

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

      case Types.TIMESTAMP:
        return Sys.DateTimeType;

      case Types.DATE:
        return Sys.DateType;

      case Types.TIME:
        return Sys.TimeType;

      default:
        return null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Sql => Fantom
//////////////////////////////////////////////////////////////////////////

  /**
   * Map an java.sql.ResultSet column to a Fantom object.
   */
  public static Object toObj(ResultSet rs, int col)
    throws SQLException
  {
    switch (rs.getMetaData().getColumnType(col))
    {
      case Types.CHAR:
      case Types.VARCHAR:
      case Types.LONGVARCHAR:
        return rs.getString(col);

      case Types.BIT:
        boolean b = rs.getBoolean(col);
        if (rs.wasNull()) return null;
        return Boolean.valueOf(b);

      case Types.TINYINT:
      case Types.SMALLINT:
      case Types.INTEGER:
      case Types.BIGINT:
        long i = rs.getLong(col);
        if (rs.wasNull()) return null;
        return Long.valueOf(i);

      case Types.REAL:
      case Types.FLOAT:
      case Types.DOUBLE:
        double f = rs.getDouble(col);
        if (rs.wasNull()) return null;
        return Double.valueOf(f);

      case Types.BINARY:
      case Types.VARBINARY:
      case Types.LONGVARBINARY:
        byte[] buf = rs.getBytes(col);
        if (rs.wasNull()) return null;
        return new MemBuf(buf);

      default:
        return String.valueOf(rs.getObject(col));
    }
  }

  /**
   * Map an java.sql.ResultSet column to a Fantom object.
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

      case Types.TIMESTAMP:
        return new ToFanDateTime();

      case Types.DATE:
        return new ToFanDate();

      case Types.TIME:
        return new ToFanTime();

      default:
        return new ToDefFanStr();
    }
  }

//////////////////////////////////////////////////////////////////////////
// SqlToFan
//////////////////////////////////////////////////////////////////////////

  public abstract static class SqlToFan
  {
    public abstract Object toObj(ResultSet rs, int col)
      throws SQLException;
  }

  public static class ToFanStr extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      return rs.getString(col);
    }
  }

  public static class ToFanBool extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      boolean b = rs.getBoolean(col);
      if (rs.wasNull()) return null;
      return Boolean.valueOf(b);
    }
  }

  public static class ToFanInt extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      long i = rs.getLong(col);
      if (rs.wasNull()) return null;
      return Long.valueOf(i);
    }
  }

  public static class ToFanFloat extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      double f = rs.getDouble(col);
      if (rs.wasNull()) return null;
      return Double.valueOf(f);
    }
  }

  public static class ToFanDateTime extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      java.sql.Timestamp ts = rs.getTimestamp(col);
      if (rs.wasNull()) return null;
      return DateTime.fromJava(ts.getTime());
    }
  }

  public static class ToFanDate extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      java.sql.Date d = rs.getDate(col);
      if (rs.wasNull()) return null;
      return fan.sys.Date.make(d.getYear()+1900, (Month)Month.vals.get(d.getMonth()), d.getDate());
    }
  }

  public static class ToFanTime extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      java.sql.Time t = rs.getTime(col);
      if (rs.wasNull()) return null;
      return fan.sys.Time.make(t.getHours(), t.getMinutes(), t.getSeconds());
    }
  }

  public static class ToFanBuf extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      byte[] buf = rs.getBytes(col);
      if (rs.wasNull()) return null;
      return new MemBuf(buf);
    }
  }

  public static class ToDefFanStr extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      return String.valueOf(rs.getObject(col));
    }
  }

}