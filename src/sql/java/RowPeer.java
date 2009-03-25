//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jun 07  Brian Frank  Creation
//
package fan.sql;

import java.sql.*;
import fan.sys.*;

public class RowPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static RowPeer make(Row fan)
  {
    return new RowPeer();
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public List cols(Row row) { return cols.list; }

  public Col col(Row row, String name) { return col(row, name, true); }
  public Col col(Row row, String name, boolean checked)
  {
    Col col = cols.get(name);
    if (col != null) return col;
    if (checked) throw ArgErr.make("Col not found: " + name).val;
    return null;
  }

  public Object get(Row row, Col col)
  {
    return cells[(int)col.index];
  }

  public void set(Row row, Col col, Object val)
  {
    cells[(int)col.index] = val;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public Cols cols;
  public Object[] cells;  // set in ConnectionPeer.query

}