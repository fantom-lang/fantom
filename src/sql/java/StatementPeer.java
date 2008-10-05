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
import fan.sql.Connection;
import fan.sql.Statement;

public class StatementPeer
{
  public static StatementPeer make(Statement fan)
  {
    return new StatementPeer();
  }

  public Statement prepare(Statement self)
  {
    // Fan uses the ADO .net prepared statement syntax, so
    // for Java the sql needs to be translated and the @param
    // syntax must be replaced with ?.  It's not a simple
    // replace though because we need to keep the key/value
    // map.
    parse(self.sql.val);
    try
    {
      stmt = self.conn.peer.jconn.prepareStatement(translated, java.sql.Statement.RETURN_GENERATED_KEYS);
      prepared = true;
    }
    catch(SQLException ex)
    {
      throw ConnectionPeer.err(ex);
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
        stmt = self.conn.peer.jconn.createStatement();
        rs = stmt.executeQuery(self.sql.val);
      }

      return toRows(rs);
    }
    catch(SQLException ex)
    {
      throw ConnectionPeer.err(ex);
    }
    finally
    {
      try { if (!prepared) stmt.close(); } catch(Exception ex) {}
    }
  }
  /**
   * Invoke the 'eachFunc' on every row in the result.
   */
  void each(ResultSet rs, Func eachFunc)
    throws SQLException
  {
    Type dtype = makeDynamicType(rs);
    Row row = null;
    SqlUtil.SqlToFan[] converters = makeConverters(rs);
    while (rs.next())
    {
      if (row == null)
        row = makeDynamicRow(rs, dtype, converters);
      else
        updateDynamicRow(rs, row, converters);
      eachFunc.call1(row);
    }
  }

  /**
   * Make a dynamic type to map the columns of the
   * result set.
   */
  Type makeDynamicType(ResultSet rs)
    throws SQLException
  {
    // map the meta-data to a dynamic type
    Type t = Type.makeDynamic(ConnectionPeer.listOfRow);
    ResultSetMetaData meta = rs.getMetaData();
    int numCols = meta.getColumnCount();
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
      t.add(Col.make(Long.valueOf(i), Str.make(name), fanType, Str.make(typeName), null));
    }

    return t;
  }

  /**
   * Make a row of the specified dynamic type and set the cell values
   * from the specified result set.
   */
  Row makeDynamicRow(ResultSet rs, Type of, SqlUtil.SqlToFan[] converters)
    throws SQLException
  {
    if (!of.isDynamic())
      throw SqlErr.make("Expecting dynamic type, not " + of).val;

    Row row = (Row)of.make();
    int numCols = rs.getMetaData().getColumnCount();
    Object[] cells = new Object[numCols];
    row.peer.cells = cells;
    for (int i=0; i<numCols; ++i)
      cells[i] = converters[i].toObj(rs, i+1);
    return row;
  }

  /**
   * Update an existing row with new values from the specified result set.
   */
  Object updateDynamicRow(ResultSet rs, Row row, SqlUtil.SqlToFan[] converters)
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
    Type dtype = makeDynamicType(rs);
    SqlUtil.SqlToFan[] converters = makeConverters(rs);
    List rows = new List(dtype);
    while (rs.next())
      rows.add(makeDynamicRow(rs, dtype, converters));

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
        stmt = self.conn.peer.jconn.createStatement();
        rs = stmt.executeQuery(self.sql.val);
      }

      each(rs, eachFunc);
    }
    catch(SQLException ex)
    {
      throw ConnectionPeer.err(ex);
    }
    finally
    {
      try { if (!prepared) stmt.close(); } catch(Exception ex) {}
    }
  }

  public Long execute(Statement self, Map params)
  {
    self.conn.peer.lastAutoGen = null;
    try
    {
      if (prepared)
      {
        setParameters(params);
        Long rows = Long.valueOf(((PreparedStatement)stmt).executeUpdate());
        ResultSet keys = stmt.getGeneratedKeys();
        if (keys.next()) self.conn.peer.lastAutoGen = Long.valueOf(keys.getInt(1));
        return rows;
      }
      else
      {
        stmt = self.conn.peer.jconn.createStatement();
        try
        {
          int rc = stmt.executeUpdate(self.sql.val, java.sql.Statement.RETURN_GENERATED_KEYS);
          ResultSet keys = stmt.getGeneratedKeys();
          if (keys.next()) self.conn.peer.lastAutoGen = Long.valueOf(keys.getInt(1));
          return Long.valueOf(rc);
        }
        finally
        {
          stmt.close();
        }
      }
    }
    catch(SQLException ex)
    {
      throw ConnectionPeer.err(ex);
    }
  }

  /**
   * Set the parameters for the underlying prepared statement
   * using the values specified in the map.
   */
  private void setParameters(Map params)
  {
    if (!prepared)
      throw SqlErr.make(Str.make("Statement has not been prepared.")).val;
    PreparedStatement pstmt = (PreparedStatement)stmt;
    try
    {
      Iterator i = paramMap.entrySet().iterator();
      while (i.hasNext())
      {
        java.util.Map.Entry entry = (java.util.Map.Entry)i.next();
        Str key = (Str)entry.getKey();
        Object value = params.get(key);
        Object jobj = fanToJava(value);
        int[] locs = (int[])entry.getValue();
        for (int j = 0; j < locs.length; j++)
        {
          //System.out.println("pstmt.setObject: " + locs[j] + " -> " + jobj.getClass().getName());
          pstmt.setObject(locs[j], jobj);
        }
      }
    }
    catch(SQLException ex)
    {
      throw ConnectionPeer.err(ex);
    }
  }

  /**
   * Get a Java object for the specified fan object.
   */
  private Object fanToJava(Object value)
  {
    Object jobj = value;

    // TODO: there's got to be a better way, it'll
    // probably shake out in the ORM design
    if (value instanceof Double)
      jobj = value;
    else if (value instanceof Boolean)
      jobj = value;
    else if (value instanceof Long)
      jobj = value;
    else if (value instanceof Str)
      jobj = ((Str)value).val;
    else if (value instanceof MemBuf)
      jobj = ((MemBuf)value).buf;

    return jobj;
  }

  public void close(Statement self)
  {
    try
    {
      stmt.close();
    }
    catch(SQLException ex)
    {
      throw ConnectionPeer.err(ex);
    }
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
          Str key = Str.make(s.substring(1));
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
        throw SqlErr.make("Invalid parameter.  Parameter name required.").val;

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
          ((ch >= '0') && (ch <= '9'));
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
        throw SqlErr.make("Invalid parameter.  Parameter name required.").val;

      return sql.substring(start, current);
    }

    private String quotedText()
    {
      int start = current;
      int end = -1;
      current++;

      if (current == len)
        throw SqlErr.make("Unterminated quoted text.  Expecting '.").val;

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
        throw SqlErr.make("Unterminated quoted text. Expecting '.").val;

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

  private boolean            prepared = false;
  private String             translated;
  private java.sql.Statement stmt;
  private HashMap            paramMap;
}