//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jun 07  Brian Frank  Creation
//

**
** Row models a row of a relational table.
**
class Row
{

  **
  ** Get a read-only list of the columns.
  **
  native Col[] cols()

  **
  ** Get a column by name.  If not found and checked
  ** is true then throw ArgErr, otherwise return null.
  **
  native Col? col(Str name, Bool checked := true)

  **
  ** Get column value.
  **
  @Operator native Obj? get(Col col)

  **
  ** Set a column value.
  **
  @Operator native Void set(Col col, Obj? val)

  **
  ** Trap is used to get or set a column by name.
  **
  override Obj? trap(Str name, Obj?[]? args)
  {
    if (args.size == 0) { return get(col(name)) }
    if (args.size == 1) { set(col(name), args.first); return null }
    return super.trap(name, args)
  }

  **
  ** Dump the cells separated by a comma.
  **
  override Str toStr()
  {
    cols.join(", ") |Col col->Str| { (get(col) ?: "null").toStr }
  }

}