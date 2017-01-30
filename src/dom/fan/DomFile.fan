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

  ** Size of file in bytes.
  native Int size()

  ** MIME type of the file as a read-only string or "" if
  ** the type could not be determined.
  native Str type()
}