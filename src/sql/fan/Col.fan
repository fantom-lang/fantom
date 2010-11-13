//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jun 07  Brian Frank  Creation
//

**
** Col models a column of a relational table.  Columns
** are accessed from rows with `Row.col` and `Row.cols`
**
const class Col
{

  **
  ** Construct a column for the given meta-data.
  **
  new make(Int index, Str name, Type type, Str sqlType)
  {
    this.index   = index
    this.name    = name
    this.of      = type
    this.type    = type
    this.sqlType = sqlType
  }

  ** Return 'name'.
  override Str toStr() { name }

  ** Zero based index of the column in the query result.
  const Int index

  ** Name of the column.
  const Str name

  ** Type of the column.
  @Deprecated { msg = "Use Col.type" }
  const Type of // TODO

  ** Type of the column.
  const Type type

  ** The type of the column as defined by the SQL database.
  const Str sqlType

}