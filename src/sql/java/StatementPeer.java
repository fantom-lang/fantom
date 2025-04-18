//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 07  John Sublett  Creation
//
package fan.sql;

import java.io.InputStream;
import java.sql.*;
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

    // are we using the old deprecated escape "@@foo"
    String depEsc = self.typeof().pod().config("deprecatedEscape");
    this.isDeprecatedEscape = ((depEsc != null) && depEsc.equals("true"));
  }

  public Statement prepare(Statement self)
  {
    // Fan uses the ADO .NET prepared statement syntax, so
    // for Java the sql needs to be translated and the @param
    // syntax must be replaced with ?.  It's not a simple
    // replace though because we need to keep the key/value
    // map.

    // Maybe there is a parameter or an escape.
    if ((self.sql.indexOf('@') != -1) || (self.sql.indexOf('\\') != -1))
    {
      // Check for deprecated escape: "@@foo"
      if (isDeprecatedEscape)
      {
        DeprecatedTokenizer t = DeprecatedTokenizer.make(self.sql);
        this.translated = t.sql;
        this.paramMap = t.params;
      }
      else
      {
        Tokenizer t = Tokenizer.make(self.sql);
        this.translated = t.sql;
        this.paramMap = t.params;
      }
    }
    // No parameters or escapes, so we don't need to tokenize.
    else
    {
      this.translated = self.sql;
      this.paramMap = new Map(
        Sys.StrType,
        Sys.IntType.toListOf());
    }

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

      List result = toRows(rs);
      rs.close();
      return result;
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
  private Object each(ResultSet rs, Func eachFunc, boolean isWhile)
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
      Object r = eachFunc.call(row);
      if (isWhile && (r != null)) return r;
    }
    return null;
  }

  /**
   * Map result set columns to Fan columns.
   * result set.
   */
  private Cols makeCols(ResultSet rs)
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
        //System.out.println("WARNING: Cannot map " + typeName + " to Fan type");
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
  private Row makeRow(ResultSet rs, Cols cols, SqlUtil.SqlToFan[] converters)
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
  private Object updateRow(ResultSet rs, Row row, SqlUtil.SqlToFan[] converters)
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
  private SqlUtil.SqlToFan[] makeConverters(ResultSet rs)
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
  private List toRows(ResultSet rs)
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
    doQueryEach(self, params, eachFunc, false);
  }

  public Object queryEachWhile(Statement self, Map params, Func eachFunc)
  {
    return doQueryEach(self, params, eachFunc, true);
  }

  private Object doQueryEach(
      Statement self, Map params, Func eachFunc, boolean isWhile)
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

      Object result = each(rs, eachFunc, isWhile);
      rs.close();
      return result;
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
        ResultSet rs = stmt.getResultSet();
        List result = toRows(rs);
        rs.close();
        return result;
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
        rs.close();
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

  public List executeBatch(Statement self, List paramsList)
  {
    if (!prepared)
      throw SqlErr.make("Statement has not been prepared.");
    PreparedStatement pstmt = (PreparedStatement)stmt;

    try
    {
      // add batch
      for (int i = 0; i < paramsList.size(); i++)
      {
        setParameters((Map) paramsList.get(i));
        pstmt.addBatch();
      }

      // execute batch
      int[] exec = pstmt.executeBatch();

      // process result
      List result = List.make(Sys.IntType, exec.length);
      for (int i = 0; i < exec.length; i++)
      {
        int n = exec[i];

        // A less-than-zero value here is always
        // java.sql.Statement.SUCCESS_NO_INFO. We treat that as a null,
        // indicating that the command was processed successfully but that the
        // number of rows affected is unknown.
        result.add(n < 0 ? null : (long)n);
      }
      return result;
    }
    catch (SQLException ex)
    {
      throw SqlConnImplPeer.err(ex);
    }
  }

  public List more(Statement self)
  {
    try
    {
      // We don't need to close this ResultSet.
      // https://docs.oracle.com/javase/8/docs/api/java/sql/Statement.html#getMoreResults--
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

    Iterator i = paramMap.pairsIterator();
    while (i.hasNext())
    {
      java.util.Map.Entry entry = (java.util.Map.Entry)i.next();
      String key = (String)entry.getKey();
      Object value = params.get(key);
      Object jobj = SqlUtil.fanToSqlObj(value);
      List locs = (List)entry.getValue();
      for (int j = 0; j < locs.size(); j++)
      {
        try
        {
          int idx = ((Long) locs.get(j)).intValue();

          // Stream via PreparedStatement.setBinaryStream()
          if (jobj instanceof InputStream)
          {
            InputStream stream = (InputStream) jobj;
            pstmt.setBinaryStream(idx, stream, stream.available());
          }
          else
          {
            pstmt.setObject(idx, jobj);
          }
        }
        catch (Exception e)
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

  private boolean prepared = false;
  private String translated;
  private java.sql.Statement stmt;
  private Map paramMap;
  private int limit = 0;              // limit field value

  // These are set during init():
  private boolean isInsert;           // does sql contain insert keyword
  private boolean isAutoKeys;         // isInsert and connector supports auto-gen keys
  private int autoKeyMode;            // JDBC constant for auto-gen keys
  private boolean isDeprecatedEscape; // are we using the old deprecated escape "@@foo"
}

