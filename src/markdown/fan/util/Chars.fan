//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

**
** A bunch of utilities for working with strings that ensure conformance
** to the common mark spec.
**
@Js
internal final class Chars
{
  ** Find the index of 'c' in 's' starting at 'startIndex' or return -1
  ** if not found.
  static Int find(Int c, Str s, Int startIndex)
  {
    len := s.size
    for (i := startIndex; i < len; ++i)
    {
      if (s[i] == c) return i
    }
    return -1
  }

  ** See spec for blank lines
  static Bool isBlank(Str s)
  {
    skipSpaceTab(s, 0, s.size) == s.size
  }

  ** Return true if the string has a non-space (' ') in it
  static Bool hasNonSpace(Str s)
  {
    s.any |ch| { ch != ' ' }
  }

  ** Return true if the code point at index 'i' in text is a letter
  **
  ** TODO:OPEN - this does not conform to java reference impl
  ** which uses Character.codePointAt and Character.isLetter and
  ** we don't have fantom equivalents for those.
  static Bool isLetter(Str text, Int i) { text[i].isAlpha }

  ** Is the code point an ISO control character. A character is considered
  ** an ISO control character if its code is in the range '\u0000' through '\u001F' or
  ** in the range '\u007F' through '\u009F'.
  static Bool isIsoControl(Int ch)
  {
    (0x00 <= ch && ch <= 0x1F) ||
    (0x7F <= ch && ch <= 0x9F)
  }

  ** Skip all 'skip' characters in 's' between startIndex (inclusive) and
  ** endIndex (exclusive). Return the index of the first non-skip character
  ** or endIndex if reached.
  static Int skip(Int skip, Str s, Int startIndex, Int endIndex)
  {
    for (i := startIndex; i < endIndex; ++i)
    {
      if (s[i] != skip) return i
    }
    return endIndex
  }

  ** Skip spaces and tabs in 's' between startIndex (inclusive) and
  ** endIndex (exclusive). Return the index of the first non-space-or-tab, or
  ** endIndex if reached.
  static Int skipSpaceTab(Str s, Int startIndex, Int endIndex)
  {
    for (i := startIndex; i < endIndex; ++i)
    {
      switch (s[i])
      {
        case ' ':
        case '\t':
          // fall-through
          continue
        default:
          return i
      }
    }
    return endIndex
  }

  static Int skipBackwards(Int skip, Str s, Int startIndex := s.size-1, Int lastIndex := 0)
  {
    for (i := startIndex; i >= lastIndex; --i)
    {
      if (s[i] != skip) return i
    }
    return lastIndex - 1
  }

  static Int skipSpaceTabBackwards(Str s, Int startIndex := s.size-1, Int lastIndex := 0)
  {
    for (i := startIndex; i >= lastIndex; --i)
    {
      if (s[i] == ' ' || s[i] == '\t') continue
      return i
    }
    return lastIndex - 1
  }

  static Bool isSpaceOrTab(Str s, Int index)
  {
    if (index < s.size) { return s[index] == ' ' || s[index] == '\t' }
    return false
  }

  ** See spec section 2.1 - all characters in Unicode section P and S.
  ** Fantom doesn't have a good way to test for this, but java does (TODO)
  **
  ** So for now we only support ASCII punctuation 😢
  **
  ** See `https://www.compart.com/en/unicode/category`
  static Bool isPunctuation(Int cp)
  {
    switch (cp)
    {
      // Pc
      case '_':
      // Pd
      case '-':
      // Pe
      case ')':
      case ']':
      case '}':
      // Pf (no ascii chars)
      // Pi (no ascii chars)
      // Po
      case '!':
      case '"':
      case '#':
      case '%':
      case '&':
      case '\'':
      case '*':
      case ',':
      case '.':
      case '/':
      case ':':
      case ';':
      case '?':
      case '@':
      case '\\':
      // Ps
      case '(':
      case '[':
      case '{':
        return true

      // Sc
      case '$':
      // Sk
      case '^':
      case '`':
      // Sm
      case '+':
      case '<':
      case '=':
      case '>':
      case '|':
      case '~':
      // So (no ascii chars)
        return true
    }
    return false
  }

  ** Check whether the provided code point is a unicode whitespace character as defined
  ** in the [spec]`https://spec.commonmark.org/0.31.2/#unicode-whitespace-character`
  static Bool isWhitespace(Int cp)
  {
    switch (cp)
    {
      case ' ':
      case '\t':
      case '\n':
      case '\f':
      case '\r':
        return true
    }
    // Zs
    if (cp == 0x00A0 || cp == 0x1680) return true
    if (0x2000 <= cp && cp <= 0x200A) return true
    return (cp == 0x202F || cp == 0x205F || cp == 0x3000)
  }
}