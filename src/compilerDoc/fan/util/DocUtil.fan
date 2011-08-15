//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

**
** Utility functions useful for working with documentation
**
class DocUtil
{
  ** Return the first sentence found in the given str.
  static Str firstSentence(Str s)
  {
    buf := StrBuf()
    for (i:=0; i<s.size; i++)
    {
      ch := s[i]
      peek := i<s.size-1 ? s[i+1] : -1
      if (ch == '.' && (peek == ' ' || peek == '\n'))
      {
        buf.addChar(ch)
        break;
      }
      else if (ch == '\n')
      {
        if (peek == -1 || peek == ' ' || peek == '\n') break
        else buf.addChar(' ')
      }
      else buf.addChar(ch)
    }
    return buf.toStr
  }

}