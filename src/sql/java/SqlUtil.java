//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Jul 07  Brian Frank  Creation
//
package fan.sql;

import java.util.HashMap;
import java.util.Map;
import java.sql.*;
import fan.sys.*;
import fan.util.FloatArray;

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

//////////////////////////////////////////////////////////////////////////
// Fantom => Sql
//////////////////////////////////////////////////////////////////////////

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

      FanListToArray conv = listToArray.get(list.of().toNonNullable());
      if (conv == null)
        throw SqlErr.make("Cannot create array from " + list.of());
      return conv.toArray(list);
    }
    // Use FloatArray primitive array
    else if (value instanceof FloatArray)
    {
      return ((FloatArray) value).array();
    }

    return jobj;
  }

  //--------------------------------------------
  // Convert a Fan List to a java Array
  //--------------------------------------------

  interface FanListToArray
  {
    Object[] toArray(List list);
  }

  static final FanListToArray toStringArray = (list) ->
  {
    String[] arr = new String[list.sz()];
    for (int i = 0; i < list.sz(); i++)
      arr[i] = (String) list.get(i);
    return arr;
  };

  static final FanListToArray toLongArray = (list) ->
  {
    Long[] arr = new Long[list.sz()];
    for (int i = 0; i < list.sz(); i++)
      arr[i] = (Long) list.get(i);
    return arr;
  };

  static final FanListToArray toBooleanArray = (list) ->
  {
    Boolean[] arr = new Boolean[list.sz()];
    for (int i = 0; i < list.sz(); i++)
      arr[i] = (Boolean) list.get(i);
    return arr;
  };

  static final FanListToArray toDoubleArray = (list) ->
  {
    Double[] arr = new Double[list.sz()];
    for (int i = 0; i < list.sz(); i++)
      arr[i] = (Double) list.get(i);
    return arr;
  };

  static final FanListToArray toTimestampArray = (list) ->
  {
    Timestamp[] arr = new Timestamp[list.sz()];
    for (int i = 0; i < list.sz(); i++)
    {
      DateTime dt = (DateTime) list.get(i);
      arr[i] = (dt == null) ? null : new Timestamp(dt.toJava());
    }
    return arr;
  };

  static final Map<Type, FanListToArray> listToArray;
  static
  {
    listToArray = new HashMap<>();

    listToArray.put(Sys.StrType,      toStringArray);
    listToArray.put(Sys.IntType,      toLongArray);
    listToArray.put(Sys.BoolType,     toBooleanArray);
    listToArray.put(Sys.FloatType,    toDoubleArray);
    listToArray.put(Sys.DateTimeType, toTimestampArray);
  }

//////////////////////////////////////////////////////////////////////////
// Sql => Fantom
//////////////////////////////////////////////////////////////////////////

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
        return toFanStr;

      case Types.BIT:
        return toFanBool;

      case Types.TINYINT:
      case Types.SMALLINT:
      case Types.INTEGER:
      case Types.BIGINT:
        return toFanInt;

      case Types.REAL:
      case Types.FLOAT:
      case Types.DOUBLE:
        return toFanFloat;

      case Types.DECIMAL:
      case Types.NUMERIC:
        return toFanDecimal;

      case Types.BINARY:
      case Types.VARBINARY:
      case Types.LONGVARBINARY:
        return toFanBuf;

      case Types.TIMESTAMP:
        return toFanDateTime;

      case Types.DATE:
        return toFanDate;

      case Types.TIME:
        return toFanTime;

      case Types.ARRAY:
        return toFanList;

      default:
        return toDefFanStr;
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
      Object obj = rs.getObject(col);
      if (obj == null)
        return null;

      obj = ((java.sql.Array) obj).getArray();

      ArrayToFanList conv = arrayToList.get(obj.getClass());
      if (conv == null)
        throw SqlErr.make("Cannot create List from " + obj);
      return conv.toList(obj);
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

  public static final SqlToFan toFanStr      = new ToFanStr();
  public static final SqlToFan toFanBool     = new ToFanBool();
  public static final SqlToFan toFanInt      = new ToFanInt();
  public static final SqlToFan toFanFloat    = new ToFanFloat();
  public static final SqlToFan toFanDecimal  = new ToFanDecimal();
  public static final SqlToFan toFanDateTime = new ToFanDateTime();
  public static final SqlToFan toFanDate     = new ToFanDate();
  public static final SqlToFan toFanTime     = new ToFanTime();
  public static final SqlToFan toFanBuf      = new ToFanBuf();
  public static final SqlToFan toFanList     = new ToFanList();
  public static final SqlToFan toDefFanStr   = new ToDefFanStr();

  //--------------------------------------------
  // Convert a java Array to a Fan List
  //--------------------------------------------

  interface ArrayToFanList
  {
    List toList(Object obj);
  }

  static final ArrayToFanList toFanStringList = (obj) ->
  {
    String[] arr = (String[]) obj;
    return new List(
      hasNull(arr) ?
        Sys.StrType.toNullable() :
        Sys.StrType,
      arr);
  };

  static final ArrayToFanList toFanIntegerList = (obj) ->
  {
    // Copy the Integer[] over to a Long[]
    Integer[] src = (Integer[]) obj;
    Long[] dst = new Long[src.length];

    boolean hasNull = false;
    for (int i = 0; i < src.length; i++)
    {
      if (src[i] == null)
        hasNull = true;
      else
        dst[i] = src[i].longValue();
    }

    return new List(
      hasNull ?
        Sys.IntType.toNullable() :
        Sys.IntType,
      dst);
  };

  static final ArrayToFanList toFanLongList = (obj) ->
  {
    Long[] arr = (Long[]) obj;
    return new List(
      hasNull(arr) ?
        Sys.IntType.toNullable() :
        Sys.IntType,
      arr);
  };

  static final ArrayToFanList toFanBooleanList = (obj) ->
  {
    Boolean[] arr = (Boolean[]) obj;
    return new List(
      hasNull(arr) ?
        Sys.BoolType.toNullable() :
        Sys.BoolType,
      arr);
  };

  static final ArrayToFanList toFanFloatList = (obj) ->
  {
    // Copy the Float[] over to a Double[]
    Float[] src = (Float[]) obj;
    Double[] dst = new Double[src.length];

    boolean hasNull = false;
    for (int i = 0; i < src.length; i++)
    {
      if (src[i] == null)
        hasNull = true;
      else
        dst[i] = src[i].doubleValue();
    }

    return new List(
      hasNull ?
        Sys.FloatType.toNullable() :
        Sys.FloatType,
      dst);
  };

  static final ArrayToFanList toFanDoubleList = (obj) ->
  {
    Double[] arr = (Double[]) obj;
    return new List(
      hasNull(arr) ?
        Sys.FloatType.toNullable() :
        Sys.FloatType,
      arr);
  };

  static final ArrayToFanList toFanTimestampList = (obj) ->
  {
    // Copy the Timestamp[] over to a DateTime[]
    Timestamp[] src = (Timestamp[]) obj;
    DateTime[] dst = new DateTime[src.length];

    boolean hasNull = false;
    for (int i = 0; i < src.length; i++)
    {
      if (src[i] == null)
        hasNull = true;
      else
        dst[i] = DateTime.fromJava(src[i].getTime());
    }

    return new List(
      hasNull ?
        Sys.DateTimeType.toNullable() :
        Sys.DateTimeType,
      dst);
  };

  static boolean hasNull(Object[] arr)
  {
    for (int i = 0; i < arr.length; i++)
    {
      if (arr[i] == null)
        return true;
    }
    return false;
  }

  static final Map<Class, ArrayToFanList> arrayToList;
  static
  {
    arrayToList = new HashMap<>();

    arrayToList.put(String[].class,    toFanStringList);
    arrayToList.put(Integer[].class,   toFanIntegerList);
    arrayToList.put(Long[].class,      toFanLongList);
    arrayToList.put(Boolean[].class,   toFanBooleanList);
    arrayToList.put(Float[].class,     toFanFloatList);
    arrayToList.put(Double[].class,    toFanDoubleList);
    arrayToList.put(Timestamp[].class, toFanTimestampList);
  }
}

