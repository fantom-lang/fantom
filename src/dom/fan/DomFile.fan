//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//

**
** DomFile models a DOM File object.
**
@Js class DomFile
{
  ** Name of file. This is just the file name, and does not
  ** include any path information.
  native Str name()

  ** Return file name extension (everything after the last dot)
  ** or 'null' name has no dot.
  Str? ext()
  {
    n := this.name
    i := n.indexr(".")
    return i==null ? null : n[i+1..-1]
  }

  ** Size of file in bytes.
  native Int size()

  ** MIME type of the file as a read-only string or "" if
  ** the type could not be determined.
  native Str type()

  ** Asynchronously load file contents as a 'data:' URI
  ** representing the file's contents.
  native Void readAsDataUri(|Uri| f)

  ** Asynchronously load file contents as text and invoke
  ** the callback function with results.
  native Void readAsText(|Str| f)
}