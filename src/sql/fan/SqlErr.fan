//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Feb 07  Brian Frank  Creation
//

**
** SqlErr indicates an error from the SQL database driver.
**
const class SqlErr : Err
{

  new make(Str? msg, Err? cause := null)
    : super(msg, cause)
  {
  }

}