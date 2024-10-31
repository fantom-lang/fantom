//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Oct 2024  Matthew Giannini  Creation
//

**
** Utils for escaping strings/characters
**
@Js
internal final class Esc
{
  static const Str escapable := Str<|[!"#$%&'()*+,./:;<=>?@\[\\\]^_`{|}~-]|>

  static const Str entity := Str<|&(?:#x[a-f0-9]{1,6}|#[0-9]{1,7}|[a-z][a-z0-9]{1,31});|>

  static const Regex whitespace := Regex("[ \t\r\n]+")

  static const Regex backslash_or_amp := Regex<|[\\&]|>

  static const Regex entity_or_esc_char :=
    Regex("\\\\${escapable}|${entity}", "i")

  ** From RFC 3986 (see "reserved", "unreserved") except don't escape '[' or ']'
  ** to be compatible with JS encodeURI
  static const Regex escape_in_uri :=
    Regex("(%[a-fA-F0-9]{0,2}|[^:/?#@!\$&'()*+,;=a-zA-Z0-9\\-._~])");

  static const |Str,StrBuf| unescaper := |Str input, StrBuf sb| {
    if (input[0] == '\\') sb.add(input[1..<input.size])
    else return sb.add(Html5.entityToStr(input))
  }

  static const |Str,StrBuf| uri_replacer := |Str input, StrBuf sb| {
    if (input[0] == '%')
    {
      if (input.size == 3)
      {
        // already percent encoded, preserve
        sb.add(input)
      }
      else
      {
        // %25 is the percent-encoding for %
        sb.add("%25").add(input[1..-1])
      }
    }
    else
    {
      // percent encode each byte
      buf := input.toBuf
      byte := buf.read
      while (byte != null)
      {
        sb.addChar('%').add(byte.toHex.upper)
        byte = buf.read
      }
    }
  }

  ** Replace entities and backslash escapes with literal chars
  static Str unescapeStr(Str s)
  {
    if (backslash_or_amp.matcher(s).find)
      return replaceAll(entity_or_esc_char, s, unescaper)
    else
      return s
  }

  static Str percentEncodeUrl(Str url)
  {
    replaceAll(escape_in_uri, url, uri_replacer)
  }

  static Str normalizeLabelContent(Str input)
  {
    trimmed := input.trim
    // TODO:FIXIT - see java code for what is happening here; we can't really do it
    // correctly with existing fantom apis
    // caseFolded := trimmed.lower(Locale.root).upper(Locale.root)
    caseFolded := trimmed.upper
    return whitespace.matcher(caseFolded).replaceAll(" ")
  }

  static Str escapeHtml(Str input)
  {
    // avoid building a new string in the majority of the cases (nothing to escape)
    StrBuf? sb := null
    for (i := 0; i < input.size; ++i)
    {
      c := input[i]
      Str? replacement := null
      switch (c)
      {
        case '&':
          replacement = "&amp;"
        case '<':
          replacement = "&lt;"
        case '>':
          replacement = "&gt;"
        case '\"':
          replacement = "&quot;"
        // default:
        //   if (sb != null) sb.addChar(c)
        //   continue loop
      }
      if (replacement != null)
      {
        if (sb == null)
        {
          sb = StrBuf()
          sb.add(input[0..<i])
        }
        sb.add(replacement)
      }
      else if (sb != null) sb.addChar(c)
    }
    return sb == null ? input : sb.toStr
  }

  private static Str replaceAll(Regex pattern, Str s, |Str, StrBuf| replacer)
  {
    matcher := pattern.matcher(s)

    if (!matcher.find) return s

    sb := StrBuf()
    lastEnd := 0
    while(true)
    {
      sb.add(s[lastEnd..<matcher.start])
      replacer(matcher.group, sb)
      lastEnd = matcher.end
      if (!matcher.find) break
    }

    if (lastEnd != s.size) sb.add(s[lastEnd..<s.size])

    return sb.toStr

  }
}