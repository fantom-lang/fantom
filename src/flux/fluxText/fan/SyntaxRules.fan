//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 08  Brian Frank  Creation
//

using flux

**
** SyntaxRules defines the rules for parsing text for color coding.
**
@Serializable
const class SyntaxRules
{

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

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  internal static SyntaxRules load(SyntaxOptions options, File? f, Str? firstLine)
  {
    // try file extension first
    SyntaxRules? rules := null
    extToRulesName := options.extToRules[f?.ext?.lower ?: "not.found"]
    if (extToRulesName != null)
    {
      rules = findRules(extToRulesName)
      if (rules != null) return rules
    }

    // try shebang
    firstLine = firstLine ?: ""
    if (firstLine.startsWith("#!") || firstLine.startsWith("# !"))
    {
      toks := firstLine[firstLine.index("!")+1..-1].split
      cmd := toks[0].split('/').last.lower
      if (cmd == "env" && toks.size > 1)
        cmd = toks[1].split('/').last.lower
      cmdToRulesName := options.extToRules[cmd]
      rules = findRules(cmdToRulesName)
      if (rules != null) return rules
    }

    // return default rules
    return SyntaxRules()
  }

  private static SyntaxRules? findRules(Str name)
  {
    file := Env.cur.findFile(`etc/fluxText/syntax/syntax-${name}.fog`, false)
    if (file == null) return null
    return file.readObj
  }

}

**
** Syntax rules for a string or character literal
**
@Serializable
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