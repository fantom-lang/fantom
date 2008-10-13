//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Jul 06  Andy Frank  Creation
//

**
** UserAgent identifies a user agent.
**
class UserAgent
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a new UserAgent with this user agent string.
  **
  new fromStr(Str userAgentStr)
  {
    // Tokens
    arr := userAgentStr.split
    for (i:=0; i<arr.size; i++)
    {
      s := arr[i]
      if (s.startsWith("("))
        while (!arr[i].endsWith(")"))
          s += " " + arr[++i]
      tokens.push(s)
    }
    tokens = tokens.ro

    // Browser/Version
    Version? version := null
    for (i:=0; i<tokens.size; i++)
    {
      s := tokens[i]

      if (s.contains("MSIE"))
      {
        isIE = true
        start := s.index("MSIE") + 5
        end   := s.index(";", start)
        version = parseVer(s[start...end])
        break
      }

      if (s.startsWith("Firefox/"))
      {
        isFirefox = true
        version = parseVer(s["Firefox/".size..-1])
        break
      }

      if (s.startsWith("Safari/"))
      {
        isSafari = true
        version = parseVer(s["Safari/".size..-1])
        break
      }

      if (s.startsWith("Opera/"))
      {
        isOpera = true
        version = parseVer(s["Opera/".size..-1])
        break
      }
    }

    // Check for valid version
    if (version == null) version = Version.fromStr("0.0")
    this.version = version
  }

  **
  ** Parse this version string into a Version object.  This
  ** method is more forgiving than straight Version.fromStr().
  ** It will strip out invalid characters and attempt to
  ** return a reasonable version match.  Returns null if
  ** nothing could be salvaged.
  **
  ** Examples:
  **   "7.0b"   =>  7.0
  **   "2.1a2"  =>  2.1
  **   "1b"     =>  1
  **   "abc"    =>  null
  **
  internal Version? parseVer(Str s)
  {
    v := ""
    for (i:=0; i<s.size; i++)
    {
      curr := s[i]
      next := (i < s.size-1) ? s[i+1] : -1
      last := (i > 0) ? s[i-1] : -1

      if (curr === '.')
      {
        if (last === '.') break
        if (next === '.') break
        if (!next.isDigit) break

      }
      else if (!curr.isDigit) break

      v += s[i].toChar
    }

    try { return Version.fromStr(v) } catch {}
    return null
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a string representation of this object. The result
  ** of this method will match the original Str that was used
  ** to parse this UserAgent.
  **
  override Str toStr()
  {
    s := ""
    tokens.each |Str p, Int i|
    {
      if (i > 0) s += " "
      s += p
    }
    return s
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  **
  ** Is this user agent Microsoft Internet Explorer.
  **
  readonly Bool isIE := false

  **
  ** Is this user agent Mozilla Firefox.
  **
  readonly Bool isFirefox := false

  **
  ** Is this agent Apple Safari.
  **
  readonly Bool isSafari := false

  **
  ** Is this agent Opera.
  **
  readonly Bool isOpera := false

  **
  ** The primary version for this user agent.  This field is
  ** only valid if the user agent is IE, Firefox, Safari, or
  ** Opera. For all other browsers, or if the above list has
  ** an invalid version string, this field will default
  ** to "0.0".
  **
  readonly Version version

  **
  ** The tokens identifying this user agent in the order
  ** they were parsed. This list is readonly.
  **
  readonly Str[] tokens := Str[,]

}