//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 08  Brian Frank  Creation
//   30 Aug 11  Brian Frank  Refactor out of fluxText
//

**
** SyntaxRules defines the syntax rules used to parse a specific
** programming language.
**
@Js @Serializable
const class SyntaxRules
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  **
  ** Load syntax rules for given file extension using "etc/syntax/ext.props".
  ** If no rules defined for extension return null.
  **
  static SyntaxRules? loadForExt(Str ext)
  {
    props := SyntaxRules#.pod.props(`ext.props`, 1min)
    ruleName := props[ext]
    if (ruleName == null) return null
    file := Env.cur.findFile(`etc/syntax/syntax-${ruleName}.fog`, false)
    if (file == null) return null
    return file.readObj
  }

  **
  ** Load syntax rules for given file.  If the file has already been
  ** parse then pass the first line to avoid re-reading the file
  ** to check the "#!" shebang.  First we attempt to map the file extension
  ** to rules.  If that fails, then we check the first line to see
  ** if defines a "#!" shebang.  Return null if no rules can be
  ** determined.
  **
  static SyntaxRules? loadForFile(File file, Str? firstLine := null)
  {
    // try file extension first
    rules := loadForExt(file.ext ?: "not.found")
    if (rules != null) return rules

    // if we don't have a firstLine, then read it
    if (firstLine == null)
    {
      in := file.in
      try { firstLine = in.readLine ?: "" } finally { in.close }
    }

    // try to parse first line with shebang
    if (firstLine.startsWith("#!") || firstLine.startsWith("# !"))
    {
      toks := firstLine[firstLine.index("!")+1..-1].split
      cmd := toks[0].split('/').last.lower
      if (cmd == "env" && toks.size > 1)
        cmd = toks[1].split('/').last.lower
      rules = loadForExt(cmd)
      if (rules != null) return rules
    }

    // give up
    return null
  }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Default constructor with it-block
  **
  new make(|This|? f := null) { if (f != null) f(this) }

//////////////////////////////////////////////////////////////////////////
// Rule Configuration
//////////////////////////////////////////////////////////////////////////

  ** Bracket characters defaults to "()[]{}".
  const Str brackets := "(){}[]"

  ** List of the keywords.
  const Str[]? keywords

  ** Start tokens for single line comments to end
  ** of line (list of strings).
  const Str[]? comments

  ** String and character literal styles
  const SyntaxStr[]? strs

  ** Start token for multi-line block comments
  const Str? blockCommentStart

  ** End token for multi-line block comments
  const Str? blockCommentEnd

  ** Can block comments be nested (default is false).
  const Bool blockCommentsNest := false
}

**
** Syntax rules for a string or character literal
**
@Js @Serializable
const class SyntaxStr
{
  ** Token which delimits the start and end of the string.
  ** If the end delimiter is different, then also set the
  ** `delimiterEnd` field.
  const Str delimiter := "\""

  ** Token which delimits the end of the string, or if
  ** null, then `delimiter` is assumed to be both the
  ** start and end of the string.
  const Str? delimiterEnd

  ** Escape character placed before ending delimiter to indicate
  ** the delimiter is part of the string, not the end.  The
  ** escape character is also assumed to escape itself.
  const Int escape

  ** Can this string literal span multiple lines
  const Bool multiLine := false
}