//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Feb 10  Andy Frank  Creation
//

using compiler
using fandoc

**
** HtmlDocUtil provides util methods for generating Html documenation.
**
class HtmlDocUtil
{

  ** Return the first sentence found in the given str.
  static Str firstSentence(Str s)
  {
    buf := StrBuf.make
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