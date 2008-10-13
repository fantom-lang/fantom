//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 May 06  Brian Frank  Creation
//

**
** Location provides a source file, line number, and column number.
**
class Location
{

  new make(Str? file, Int? line := null, Int? col := null)
  {
    this.file = file
    this.line = line
    this.col  = col
  }

  new makeFile(File? file)
  {
    if (file != null)
    {
      osPath := file.osPath
      if (osPath != null)
        this.file = osPath
      else
        this.file = file.pathStr
    }
  }

  new makeUninit()
  {
  }

  Str? filename()
  {
    if (file == null) return null
    f := file
    slash := f.indexr("/")
    if (slash == null) slash = f.indexr("\\")
    if (slash != null) f = f[slash+1..-1]
    return f
  }

  Str? fileUri()
  {
    try
    {
      return File.os(file).uri.toStr
    }
    catch
    {
      return file
    }
  }

  override Str toStr()
  {
    return toLocationStr
  }

  Str toLocationStr()
  {
    StrBuf s := StrBuf()
    s.add(file)
    if (line != null)
    {
      s.add("(").add(line)
      if (col != null) s.add(",").add(col)
      s.add(")")
    }
    return s.toStr
  }

  Str? file
  Int? line
  Int? col

}