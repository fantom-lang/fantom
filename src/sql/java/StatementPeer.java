//
// Copyright (c) 2007, John Sublett
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 07  John Sublett  Creation
//
package fan.sql;

import java.sql.*;
import java.util.HashMap;
import java.util.Iterator;
import fan.sys.*;
import fan.sql.Statement;

public class StatementPeer
{
  public static StatementPeer make(Statement fan)
  {
    return new StatementPeer();
  }

  public void init(Statement self)
  {
    // at this point the conn and sql fields are configured,
    // figure out our auto-generated key mode
    this.isInsert = FanStr.indexIgnoreCase(self.sql, "insert ") != null;
    this.isAutoKeys = this.isInsert && self.conn.peer.supportsGetGenKeys;
    this.autoKeyMode = this.isAutoKeys ?
                       java.sql.Statement.RETURN_GENERATED_KEYS :
                       java.sql.Statement.NO_GENERATED_KEYS;

  }

  public Statement prepare(Statement self)
  {
    // Fan uses the ADO .NET prepared statement syntax, so
    // for Java the sql needs to be translated and the @param
    // syntax must be replaced with ?.  It's not a simple
    // replace though because we need to keep the key/value
    // map.
    parse(self.sql);
    try
    {
      prepared = true;
      createStatement(self);
    }
    catch (SQLException ex)
    {
      throw SqlConnImplPeer.err(ex);
    }
    return self;
  }

  public List query(Statement self, Map params)
  {
    try
    {
      ResultSet rs = null;
      if (prepared)
      {
        setParameters(params);
        rs = ((PreparedStatement)stmt).executeQuery();
      }
      else
      {
        createStatement(self);
        rs = stmt.executeQuery(self.sql);
      }

      return toRows(rs);
    }
    catch (SQLException ex)
    {
      throw SqlConnImplPeer.err(ex);
    }
    finally
    {
      try { if (!prepared) stmt.close(); } catch (Exception ex) {}
    }
  }

  /**
   * Invoke the 'eachFunc' on every row in the result.
   */
  void each(ResultSet rs, Func eachFunc)
    throws SQLException
  {
    Cols cols = makeCols(rs);
    Row row = null;
    SqlUtil.SqlToFan[] converters = makeConverters(rs);
    while (rs.next())
    {
      if (row == null)
        row = makeRow(rs, cols, converters);
      else
        updateRow(rs, row, converters);
      eachFunc.call(row);
    }
  }

  /**
   * Map result set columns to Fan columns.
   * result set.
   */
  Cols makeCols(ResultSet rs)
    throws SQLException
  {
    // map the meta-data to a dynamic type
    ResultSetMetaData meta = rs.getMetaData();
    int numCols = meta.getColumnCount();
    List cols = new List(SqlUtil.colType, numCols);
    for (int i=0; i<numCols; ++i)
    {
      String name = meta.getColumnLabel(i+1);
      String typeName = meta.getColumnTypeName(i+1);
      Type fanType = SqlUtil.sqlToFanType(meta.getColumnType(i+1));
      if (fanType == null)
      {
        System.out.println("WARNING: Cannot map " + typeName + " to Fan type");
        fanType = Sys.StrType;
      }
      cols.add(Col.make(Long.valueOf(i), name, fanType, typeName));
    }
    return new Cols(cols);
  }

  /**
   * Make a row of the specified dynamic type and set the cell values
   * from the specified result set.
   */
  Row makeRow(ResultSet rs, Cols cols, SqlUtil.SqlToFan[] converters)
    throws SQLException
  {
    Row row = Row.make();
    int numCols = rs.getMetaData().getColumnCount();
    Object[] cells = new Object[numCols];
    row.peer.cols = cols;
    row.peer.cells = cells;
    for (int i=0; i<numCols; ++i)
      cells[i] = converters[i].toObj(rs, i+1);
    return row;
  }

  /**
   * Update an existing row with new values from the specified result set.
   */
  Object updateRow(ResultSet rs, Row row, SqlUtil.SqlToFan[] converters)
    throws SQLException
  {
    int numCols = rs.getMetaData().getColumnCount();
    Object[] cells = row.peer.cells;
    for (int i=0; i<numCols; ++i)
      cells[i] = converters[i].toObj(rs, i+1);
    return row;
  }

  /**
   * Make the list of converters for the specified result set.
   */
  SqlUtil.SqlToFan[] makeConverters(ResultSet rs)
    throws SQLException
  {
    int numCols = rs.getMetaData().getColumnCount();
    SqlUtil.SqlToFan[] converters = new SqlUtil.SqlToFan[numCols];
    for (int i=0; i<numCols; i++)
      converters[i] = SqlUtil.converter(rs, i+1);
    return converters;
  }

  /**
   * Convert the result set to a list of the 'of' type.
   */
  List toRows(ResultSet rs)
    throws SQLException
  {
    Cols cols = makeCols(rs);
    SqlUtil.SqlToFan[] converters = makeConverters(rs);
    List rows = new List(SqlUtil.rowType);
    while (rs.next()) rows.add(makeRow(rs, cols, converters));
    return rows;
  }

  public void queryEach(Statement self, Map params, Func eachFunc)
  {
    try
    {
      ResultSet rs = null;
      if (prepared)
      {
        setParameters(params);
        rs = ((PreparedStatement)stmt).executeQuery();
      }
      else
      {
        createStatement(self);
        rs = stmt.executeQuery(self.sql);
      }

      each(rs, eachFunc);
    }
    catch (SQLException ex)
    {
      throw SqlConnImplPeer.err(ex);
    }
    finally
    {
      try { if (!prepared) stmt.close(); } catch (Exception ex) {}
    }
  }

  public Object execute(Statement self, Map params)
  {
    try
    {
      if (prepared)
      {
        setParameters(params);
        boolean isResultSet = ((PreparedStatement)stmt).execute();
        return executeResult(self, isResultSet);
      }
      else
      {
        createStatement(self);
        try
        {
          boolean isResultSet = stmt.execute(self.sql, autoKeyMode);
          return executeResult(self, isResultSet);
        }
        finally
        {
          stmt.close();
        }
      }
    }
    catch (SQLException ex)
    {
      throw SqlConnImplPeer.err(ex);
    }
  }

  private Object executeResult(Statement self, boolean isResultSet)
  {
    try
    {
      // if result is ResultSet, then return Row[]
      if (isResultSet)
      {
        return toRows(stmt.getResultSet());
      }

      // if auto-generated keys, then return Int[]
      // Some databases like Oracle do not allow access to
      // keys as Int, so return keys as Str[]
      if (isAutoKeys)
      {
        ResultSet rs = stmt.getGeneratedKeys();
        List keys = null;
        while (rs.next())
        {
          // get key as Long or String
          Object key;
          try { key = rs.getLong(1); }
          catch (Exception e) { key = rs.getString(1); }

          // lazily create keys list with proper type
          if (keys == null)
            keys = new List(key instanceof Long ? Sys.IntType : Sys.StrType);

          keys.add(key);
        }
        if (keys != null) return keys;
      }

      // othertise return the update count
      return Long.valueOf(stmt.getUpdateCount());
    }
    catch (Exception e)
    {
      e.printStackTrace();
    }
    return Long.valueOf(-1);
  }

  public List more(Statement self)
  {
    try
    {
      if (stmt.getMoreResults())
        return toRows(stmt.getResultSet());
      else
        return null;
    }
    catch (SQLException ex)
    {
      throw SqlConnImplPeer.err(ex);
    }
  }

  /**
   * Set the parameters for the underlying prepared statement
   * using the values specified in the map.
   */
  private void setParameters(Map params)
  {
    if (!prepared)
      throw SqlErr.make("Statement has not been prepared.");
    PreparedStatement pstmt = (PreparedStatement)stmt;

    Iterator i = paramMap.entrySet().iterator();
    while (i.hasNext())
    {
      java.util.Map.Entry entry = (java.util.Map.Entry)i.next();
      String key = (String)entry.getKey();
      Object value = params.get(key);
      Object jobj = SqlUtil.fanToSqlObj(value);
      int[] locs = (int[])entry.getValue();
      for (int j = 0; j < locs.length; j++)
      {
        try
        {
          pstmt.setObject(locs[j], jobj);
        }
        catch (SQLException e)
        {
          throw SqlErr.make("Param name='" + key + "' class='" + value.getClass().getName() + "'; " +
                            e.getMessage(), Err.make(e));
        }
      }
    }
  }


  public void close(Statement self)
  {
    try
    {
      stmt.close();
    }
    catch (SQLException ex)
    {
      throw SqlConnImplPeer.err(ex);
    }
  }

  public Long limit(Statement self)
  {
    return limit <= 0 ? null : Long.valueOf(limit);
  }

  public void limit(Statement self, Long limit)
  {
    this.limit = 0;
    if (limit != null && limit.longValue() < Integer.MAX_VALUE)
      this.limit = limit.intValue();
  }

  private void createStatement(Statement self)
    throws SQLException
  {
    if (prepared)
      stmt = self.conn.peer.jconn.prepareStatement(translated, autoKeyMode);
    else
      stmt = self.conn.peer.jconn.createStatement();
    if (limit > 0) stmt.setMaxRows(limit);
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  private void parse(String sql)
  {
    StringBuffer jsql = new StringBuffer(sql.length());
    int index = sql.indexOf('@');

    // make sure the sql has at least one parameter
    // before bothering with the parse
    if (index == -1)
    {
      translated = sql;
      paramMap = new HashMap();
      return;
    }

    Tokenizer t = new Tokenizer(sql);
    String s;
    int pIndex = 1;
    while ((s = t.next()) != null)
    {
      if (s.length() == 0) continue;
      if (s.charAt(0) == '@')
      {
        if (s.length() == 1)
          jsql.append(s);
        else
        {
          if (paramMap == null) paramMap = new HashMap();

          // param
          String key = s.substring(1);
          int[] locs = (int[])paramMap.get(key);
          if (locs == null)
          {
            locs = new int[] { pIndex };
            paramMap.put(key, locs);
          }
          else
          {
            int[] temp = new int[locs.length+1];
            System.arraycopy(locs, 0, temp, 0, locs.length);
            temp[locs.length] = pIndex;
            paramMap.put(key, temp);
          }
          pIndex++;
          jsql.append("?");
        }
      }
      else
        jsql.append(s);
    }

    translated = jsql.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Tokenizer
//////////////////////////////////////////////////////////////////////////

  private class Tokenizer
  {
    public Tokenizer(String sql)
    {
      this.sql = sql;
      len = sql.length();
      current = 0;
    }

    public String next()
    {
      switch (mode)
      {
        case MODE_TEXT: return text();
        case MODE_PARAM: return param();
        case MODE_QUOTE: return quotedText();
        case MODE_END: return null;

        default: return null;
      }
    }

    private String text()
    {
      int start = current;
      while (current != len)
      {
        int ch = sql.charAt(current);
        if (ch == '@') { mode = MODE_PARAM; break; }
        if (ch == '\'') { mode = MODE_QUOTE; break; }

        current++;

        if (current == len) mode = MODE_END;
      }

      return sql.substring(start, current);
    }

    private String param()
    {
      int start = current;
      current++;

      if (current == len)
        throw SqlErr.make("Invalid parameter.  Parameter name required.");

      int ch = sql.charAt(current);
      // @@ means we really wanted @
      if (sql.charAt(current) == '@')
      {
        current++;
        return "@";
      }

      while (current != len)
      {
        ch = sql.charAt(current);
        boolean valid =
          ((ch >= 'a') && (ch <= 'z')) ||
          ((ch >= 'A') && (ch <= 'Z')) ||
          ((ch >= '0') && (ch <= '9')) ||
          (ch == '_');
        if (!valid)
        {
          if (ch == '\'')
          {
            mode = MODE_QUOTE;
            break;
          }
          else
          {
            mode = MODE_TEXT;
            break;
          }
        }
        current++;
        if (current == len) mode = MODE_END;
      }

      if (current == start+1)
        throw SqlErr.make("Invalid parameter.  Parameter name required.");

      return sql.substring(start, current);
    }

    private String quotedText()
    {
      int start = current;
      int end = -1;
      current++;

      if (current == len)
        throw SqlErr.make("Unterminated quoted text.  Expecting '.");

      while (current != len)
      {
        int ch = sql.charAt(current);
        if (ch == '\'')
        {
          end = current;
          current++;
          break;
        }

        current++;
      }

      if (end == -1)
        throw SqlErr.make("Unterminated quoted text. Expecting '.");

      if (current == len)
        mode = MODE_END;
      else
      {
        int ch = sql.charAt(current);
        if (ch == '@')
          mode = MODE_PARAM;
        else if (ch == '\'')
          mode = MODE_QUOTE;
        else
          mode = MODE_TEXT;
      }

      return sql.substring(start, end+1);
    }

    String sql;
    int    mode = MODE_TEXT;
    int    len;
    int    current;
  }

  private static final int MODE_TEXT  = 0;
  private static final int MODE_QUOTE = 1;
  private static final int MODE_PARAM = 2;
  private static final int MODE_END   = 3;

  private boolean prepared = false;
  private String translated;
  private java.sql.Statement stmt;
  private HashMap paramMap;
  private int limit = 0;              // limit field value
  private boolean isInsert;           // does sql contain insert keyword
  private boolean isAutoKeys;         // isInsert and connector supports auto-gen keys
  private int autoKeyMode;            // JDBC constant for auto-gen keys
}