//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Sep 08  Brian Frank  Creation
//

using concurrent
using fwt

**
** Mark is used to identify a uri with an optional
** line and column position.
**
const class Mark
{

  **
  ** Default constructor with it-block.
  **
  new make(|This| f) { f(this) }

  **
  ** Attempt to parse an arbitrary line of text into a mark.
  ** We attempt to match anything that looks like a absolute
  ** file name.  If we match a filename, then we look for an
  ** optional line and column number no more than a few chars
  ** from the filename.  This will correctly handle output from
  ** various compilers including Fantom compilers, javac, and the
  ** C# compiler.  Return null if file path found.
  **
  static Mark? fromStr(Str text)
  {
    return MarkParser(text).parse
  }

  **
  ** Uri of the resource
  **
  const Uri uri := ``

  **
  ** One based line number or null if unknown.
  ** Note that fwt widgets are zero based.
  **
  const Int? line

  **
  ** One based line column or null if unknown
  ** Note that fwt widgets are zero based.
  **
  const Int? col

  **
  ** Hash code is based on uri, line, and col.
  **
  override Int hash()
  {
    hash := uri.hash
    if (line != null) hash = hash.xor(line.shiftl(21))
    if (col != null)  hash = hash.xor(col.shiftl(11))
    return hash
  }

  **
  ** Equality is based on uri, line, and col.
  **
  override Bool equals(Obj? that)
  {
    x := that as Mark
    if (x == null) return false
    return uri == x.uri && line == x.line && col == x.col
  }

  **
  ** Compare URIs, then lines, then columns
  **
  override Int compare(Obj that)
  {
    x := (Mark)that
    cmp := uri <=> x.uri
    if (cmp == 0) cmp = line <=> x.line
    if (cmp == 0) cmp = col <=> x.col
    return cmp
  }

  **
  ** Return string formatted as "uri:line:col" where the
  ** line and col are optional if null.
  **
  override Str toStr()
  {
    s := uri.toStr
    if (line != null) s += ":$line"
    if (col != null)  s += ":$col"
    return s
  }

}

**************************************************************************
** MarkParser
**************************************************************************

**
** MarkParser is used to implement Mark.fromStr.
** It also keeps track of the string indices for
** the filename so console can shrink it.
**
internal class MarkParser
{
  new make(Str text) { this.text = text }

  Mark? parse()
  {
    try
    {
      return doParse
    }
    catch (Err e)
    {
      e.trace
      return null
    }
  }

  private Mark? doParse()
  {
    // use case insensitive compare on windows
    text := this.text
    if (Desktop.isWindows) text = text.lower

    // attempt to match one of the root indices
    Str? root := null
    Int? s := null
    rootDirs.each |Str rootDir|
    {
      x := text.index(rootDir)
      if (x == null) return
      if (s == null || x < s) { s = x; root = rootDir }
    }
    if (s == null) return null

    // match up anything that looks like a directory
    e := s + root.size
    if (text.size <= e) return null
    f := File.os(text[s..e])
    while (text[e] == '/' || text[e] == '\\')
    {
      slash := Desktop.isWindows ? text.index("\\", e+1) : null
      if (slash == null) slash = text.index("/", e+1)
      if (slash == null) break
      testf := File.os(text[s..slash])
      if (!testf.exists) break
      f = testf
      e = slash
    }

    // try and find the longest matching file name in that directory
    rest := text[e+1..-1]
    Str[] names := f.list.map |File x->Str| { Desktop.isWindows ? x.name.lower : x.name }
    names.sortr |Str a, Str b->Int| { a.size <=> b.size }
    Str? n := names.eachWhile |Str n->Str?| { rest.startsWith(n) ? n : null }
    if (n != null)
    {
      f = File.make(f.uri + n.toUri, false)
      e += n.size
    }
    fileStart = s
    fileEnd = e

    // we now have our uri
    Uri? uri := null
    try { uri = f.normalize.uri } catch { return null }

    // try to find a number for line
    Int? num := null
    for (i:=e+1; i<e+8 && i<text.size; ++i)
      if (text[i].isDigit) { num=i; break }
    if (num == null) return Mark { it.uri = uri }

    // parse out line number
    line := text[num] - '0'
    while (++num < text.size && text[num].isDigit)
      line = line*10 + (text[num] - '0')

    // try to find a column number
    e = num; num = null;
    for (i:=e; i<e+8 && i<text.size; ++i)
      if (text[i].isDigit) { num=i; break }
    if (num == null) return Mark { it.uri = uri; it.line = line }

    // parse out line number
    col := text[num] - '0'
    while (++num < text.size && text[num].isDigit)
      col = col*10 + (text[num] - '0')

    return Mark { it.uri = uri; it.line = line; it.col = col }
  }

  **
  ** Get a listing of the file system root paths
  ** to use for matching absolute filepaths.
  **
  internal static Str[] rootDirs()
  {
    Str[]? roots := Actor.locals["flux.Mark.roots"]
    if (roots == null)
    {
      roots = Str[,]
      File.osRoots.each |File f|
      {
        f.list.each |File x|
        {
          path := x.osPath
          if (Desktop.isWindows) path = path.lower
          roots.add(path)
        }
      }
      roots.sortr |Str a, Str b->Int| { a.size <=> b.size }
      Actor.locals["flux.Mark.roots"] = roots
    }
    return roots
  }

  Str? text
  Int fileStart := -1
  Int fileEnd := -1
}