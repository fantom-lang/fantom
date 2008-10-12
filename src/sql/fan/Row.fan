//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jun 07  Brian Frank  Creation
//

**
** Row models a row of a relational table.  The cells of
** a row are accessed using normal reflection.  The row type's
** fields will be instances of Col.
**
** See `docLib::Sql`.
**
class Row
{

  **
  ** Get column value.
  **
  native Obj? get(Col col)

  **
  ** Set a column value.
  **
  native Void set(Col col, Obj? val)

  **
  ** Dump the cells separated by a comma.
  **
  override Str toStr()
  {
    s := StrBuf.make
    type.fields.each |Field f|
    {
      if (s.size > 0) s.add(", ")
      s.add(f.get(this))
    }
    return s.toStr
  }

}