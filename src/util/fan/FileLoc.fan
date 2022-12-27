//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 22  Brian Frank  Creation
//

**
** FileLoc is a location within a text file or source string.
** It includes an optional one-base line number and column number.
** This class provides a standardized API for text based tools which
** need to report the line/column numbers of errors.
**
@Js
const class FileLoc
{
  ** Constant for an unknown location
  static const FileLoc unknown := make("unknown", 0)

  ** Constant for tool input location
  static const FileLoc inputs := make("inputs", 0)

  ** Constant for synthetic location
  static const FileLoc synthetic := make("synthetic", 0)

  ** Constructor for file
  static new makeFile(File file, Int line := 0, Int col := 0)
  {
    uri := file.uri
    name := uri.scheme == "fan" ? "$uri.host::$uri.pathStr" : file.pathStr
    return make(name, line, col)
  }

  ** Constructor for filename string
  new make(Str file, Int line := 0, Int col := 0)
  {
    this.file = file
    this.line = line
    this.col  = col
  }

  ** Parse location formatted from `toStr`
  @NoDoc static FileLoc parse(Str s)
  {
    // by convention this should be called fromStr but that
    // conflicts with the make(Str) constructor - so just leave
    // as nodoc backdoor hook
    file := s
    line := 0
    col  := 0
    if (s.endsWith(")"))
    {
      open := s.indexr("(")
      if (open != null)
      {
        file = s[0..<open]
        comma := s.index(",", open+2)
        if (comma == null)
        {
          line = s[open+1..-2].trim.toInt(10, false) ?: 0
        }
        else
        {
          line = s[open+1..<comma].trim.toInt(10, false) ?: 0
          col  = s[comma+1..-2].trim.toInt(10, false) ?: 0
        }
      }
    }
    return make(file, line, col)
  }

  ** Filename location
  const Str file

  ** One based line number or zero if unknown
  const Int line

  ** One based line column number or zero if unknown
  const Int col

  ** Is this the unknown location
  Bool isUnknown() { this === unknown }

  ** Hash code
  override Int hash()
  {
    file.hash.xor(line.hash).xor(col.hash.shiftl(17))
  }

  ** Equality operator
  override Bool equals(Obj? that)
  {
    x := that as FileLoc
    if (x == null) return false
    return file == x.file && line == x.line && col == x.col
  }

  ** Comparison operator
  override Int compare(Obj that)
  {
    x := (FileLoc)that
    if (file != x.file) return file <=> x.file
    if (line != x.line) return line <=> x.line
    return col <=> x.col
  }

  ** Return string representation as "file", "file(line)", or "file(line,col)".
  ** This is the standard format used by the Fantom compiler.
  override Str toStr()
  {
    if (line <= 0) return file
    if (col <= 0) return "$file($line)"
    return "$file($line,$col)"
  }

}

**************************************************************************
** FileLocErr
**************************************************************************

**
** Exception with a file location
**
@Js
const class FileLocErr : Err
{
  ** Constructor with message, location, and optional cause
  new make(Str msg, FileLoc loc, Err? cause := null) : super(msg, cause)
  {
    this.loc = loc
  }

  ** File location
  const FileLoc loc

  ** Return "loc: msg"
  override Str toStr()
  {
    if (loc.isUnknown) return super.toStr
    return "$loc.toStr: $msg"
  }
}

