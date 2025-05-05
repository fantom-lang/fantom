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
   * Get a JDBC Java object for the specified Fan object.
   */
  @SuppressWarnings({"deprecation"})
  public static Object fanToSqlObj(Object value)
  {
    Object jobj = value;

    if (value instanceof DateTime)
    {
      DateTime dt = (DateTime)value;
      jobj = new Timestamp(dt.toJava());
    }
    else if (value instanceof fan.sys.Date)
    {
      fan.sys.Date d = (fan.sys.Date)value;
      jobj = new java.sql.Date((int)d.year()-1900, (int)d.month().ordinal(), (int)d.day());
    }
    else if (value instanceof fan.sys.Time)
    {
      fan.sys.Time t = (fan.sys.Time)value;
      jobj = new java.sql.Time((int)t.hour(), (int)t.min(), (int)t.sec());
    }
    // Stream via PreparedStatement.setBinaryStream()
    else if (value instanceof Buf)
    {
      jobj = ((Buf)value).javaIn();
    }
    // Support for converting Fantom Lists to Postgres arrays.
    else if (value instanceof List)
    {
      List list = (List) value;

      // postgres text array
      if (list.of().equals(Sys.StrType))
      {
        String[] arr = new String[list.sz()];
        for (int i = 0; i < list.sz(); i++)
          arr[i] = (String) list.get(i);
        jobj = arr;
      }
      // postgres int/bigint array (works for both)
      else if (list.of().equals(Sys.IntType))
      {
        Long[] arr = new Long[list.sz()];
        for (int i = 0; i < list.sz(); i++)
          arr[i] = (Long) list.get(i);
        jobj = arr;
      }
      // postgres boolean array
      else if (list.of().equals(Sys.BoolType))
      {
        Boolean[] arr = new Boolean[list.sz()];
        for (int i = 0; i < list.sz(); i++)
          arr[i] = (Boolean) list.get(i);
        jobj = arr;
      }
      // postgres real/double precision array (works for both)
      else if (list.of().equals(Sys.FloatType))
      {
        Double[] arr = new Double[list.sz()];
        for (int i = 0; i < list.sz(); i++)
          arr[i] = (Double) list.get(i);
        jobj = arr;
      }
      // postgres timestamptz
      else if (list.of().equals(Sys.DateTimeType))
      {
        Timestamp[] arr = new Timestamp[list.sz()];
        for (int i = 0; i < list.sz(); i++)
        {
          DateTime dt = (DateTime) list.get(i);
          arr[i] = new Timestamp(dt.toJava());
        }
        jobj = arr;
      }
      else
      {
        throw SqlErr.make("Cannot create array from " + list.of());
      }
    }

    return jobj;
  }

  /**
   * Map an java.sql.Types code to a Fan type.
   */
  public static Type sqlToFanType(int sql)
  {
    switch (sql)
    {
      case Types.CHAR:
      case Types.NCHAR:
      case Types.VARCHAR:
      case Types.NVARCHAR:
      case Types.LONGVARCHAR:
      case Types.SQLXML:
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

      case Types.DECIMAL:
      case Types.NUMERIC:
        return Sys.DecimalType;

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

      case Types.DECIMAL:
      case Types.NUMERIC:
        return rs.getBigDecimal(col);

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

      case Types.DECIMAL:
      case Types.NUMERIC:
        return new ToFanDecimal();

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

      case Types.ARRAY:
        return new ToFanList();

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

  public static class ToFanDecimal extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      return rs.getBigDecimal(col);
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
    @SuppressWarnings({"deprecation"})
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
    @SuppressWarnings({"deprecation"})
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

  // Support for converting Postgres arrays to Fantom Lists.
  public static class ToFanList extends SqlToFan
  {
    public Object toObj(ResultSet rs, int col)
      throws SQLException
    {
      Object arr = ((java.sql.Array) rs.getObject(col)).getArray();

      // postgres text array
      if (arr instanceof String[])
      {
        return new List(Sys.StrType, (String[]) arr);
      }
      // postgres int array
      else if (arr instanceof Integer[])
      {
        // We have to copy the Integer[] over to a Long[]
        Integer[] src = (Integer[]) arr;
        Long[] dst = new Long[src.length];

        for (int i = 0; i < src.length; i++)
          dst[i] = src[i].longValue();

        return new List(Sys.IntType, dst);
      }
      // postgres bigint array
      else if (arr instanceof Long[])
      {
        return new List(Sys.IntType, (Long[]) arr);
      }
      // postgres boolean array
      else if (arr instanceof Boolean[])
      {
        return new List(Sys.BoolType, (Boolean[]) arr);
      }
      // postgres real array
      else if (arr instanceof Float[])
      {
        // We have to copy the Float[] over to a Double[]
        Float[] src = (Float[]) arr;
        Double[] dst = new Double[src.length];

        for (int i = 0; i < src.length; i++)
          dst[i] = src[i].doubleValue();

        return new List(Sys.FloatType, dst);
      }
      // postgres double precision array
      else if (arr instanceof Double[])
      {
        return new List(Sys.FloatType, (Double[]) arr);
      }
      // postgres timestamptz array
      else if (arr instanceof Timestamp[])
      {
        // We have to copy the Timestamp[] over to a DateTime[]
        Timestamp[] src = (Timestamp[]) arr;
        DateTime[] dst = new DateTime[src.length];

        for (int i = 0; i < src.length; i++)
          dst[i] = DateTime.fromJava(src[i].getTime());

        return new List(Sys.DateTimeType, dst);
      }
      else
      {
        throw SqlErr.make("Cannot create array from " + arr.getClass());
      }
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

