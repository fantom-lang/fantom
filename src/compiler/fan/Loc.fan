//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 May 06  Brian Frank  Creation
//

**
** Loc provides a source file, line number, and column number.
**
class Loc
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

  override Int hash()
  {
    hash := 33
    if (file != null) hash = hash.xor(file.hash)
    if (line != null) hash = hash.xor(line.hash)
    if (col  != null) hash = hash.xor(col.hash)
    return hash
  }

  override Bool equals(Obj? that)
  {
    x := that as Loc
    if (x == null) return false
    return file == x.file && line == x.line && col == x.col
  }

  override Int compare(Obj that)
  {
    x := (Loc)that
    if (file != x.file) return file <=> x.file
    if (line != x.line) return line <=> x.line
    return col <=> x.col
  }

  override Str toStr()
  {
    return toLocStr
  }

  Str toLocStr()
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