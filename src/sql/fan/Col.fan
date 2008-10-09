//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jun 07  Brian Frank  Creation
//

**
** Col models a column of a relational table.  Col is a
** subclass of Field and uses the standard reflection APIs.
**
** See `docLib::Sql`.
**
const class Col : Field
{

  **
  ** Construct a column for the given meta-data.
  **
  new make(Int index, Str name, Type of, Str sqlType, Str:Obj facets := null)
    : super(name, of, facets)
  {
    this.index   = index
    this.sqlType = sqlType
  }

  **
  ** Get the column value for the specified row.
  **
  override Obj? get(Obj? row)
  {
    return ((Row)row).get(this)
  }

  **
  ** Set the column value for the specified row.
  **
  override Void set(Obj? row, Obj? val)
  {
    ((Row)row).set(this, val)
  }

  ** Zero based index of the column in the query result.
  const Int index

  ** The type of the column as defined by the SQL database.
  const Str sqlType

}