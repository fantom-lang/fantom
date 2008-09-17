//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Sep 08  Brian Frank  Creation
//

using fwt

**
** Mark is used to identify a uri with an optional
** line and column position.
**
const class Mark
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** Uri of the resource
  const Uri uri

  ** One based line number or null if unknown
  const Int line

  ** One based line column or null if unknown
  const Int col

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

//////////////////////////////////////////////////////////////////////////
// From Str
//////////////////////////////////////////////////////////////////////////

  **
  ** Attempt to parse an arbitrary line of text into a mark.
  ** We attempt to match anything that looks like a absolute
  ** file name.  If we match a filename, then we look for an
  ** optional line and column number no more than a few chars
  ** from the filename.  This will correctly handle output from
  ** various compilers including Fan compilers, javac, and the
  ** C# compiler.  Return null if file path found.
  **
  static Mark fromStr(Str text)
  {
    // use case insensitive compare on windows
    if (Desktop.isWindows) text = text.lower

    // attempt to match one of the root indices
    Str root := null
    Int s := rootDirs.eachBreak |Str rootDir->Int| { return text.index(root = rootDir) }
    if (s == null) return null

    // match up anything that looks like a directory
    e := s + root.size
    f := File.os(text[s..e])
    while (text[e] == '/' || text[e] == '\\')
    {
      slash := text.index("/", e+1)
      if (slash == null) slash = text.index("\\", e+1)
      if (slash == null) break
      testf := File.os(text[s..slash])
      if (!testf.exists) break
      f = testf
      e = slash
    }

    // try and find the longest matching file name in that directory
    rest := text[e+1..-1]
    names := Str[,]
    f.list.map(names) |File x->Str| { return Desktop.isWindows ? x.name.lower : x.name }
    names.sortr |Str a, Str b->Int| { return a.size <=> b.size }
    Str n := names.eachBreak |Str n->Str| { return rest.startsWith(n) ? n : null }
    if (n != null)
    {
      f = f + n.toUri
      e += n.size
    }

    // we now have our uri
    Uri uri := null
    try { uri = f.normalize.uri } catch { return null }

    // try to find a number for line
    Int num := null
    for (i:=e+1; i<e+8 && i<text.size; ++i)
      if (text[i].isDigit) { num=i; break }
    if (num == null) return Mark { uri = uri }

    // parse out line number
    line := text[num] - '0'
    while (++num < text.size && text[num].isDigit)
      line = line*10 + (text[num] - '0')

    // try to find a column number
    e = num; num = null;
    for (i:=e; i<e+8 && i<text.size; ++i)
      if (text[i].isDigit) { num=i; break }
    if (num == null) return Mark { uri = uri; line = line }

    // parse out line number
    col := text[num] - '0'
    while (++num < text.size && text[num].isDigit)
      col = col*10 + (text[num] - '0')

    return Mark { uri = uri; line = line; col = col }
  }

  **
  ** Get a listing of the file system root paths
  ** to use for matching absolute filepaths.
  **
  internal static Str[] rootDirs()
  {
    Str[] roots := Thread.locals["flux.Mark.roots"]
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
      Thread.locals["flux.Mark.roots"] = roots
    }
    return roots
  }

}
