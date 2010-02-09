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

  ** Make a type link formatted as <a href='type.uri'>type.name</a>.
  static Str makeTypeLink(Type t, |Type->Uri| map)
  {
    if (!t.isGeneric)
    {
      p := t.params
      if (p["L"] != null)
      {
        of := p["V"]
        link := "${makeTypeLink(of,map)}[]"
        if (t.isNullable) link += "?"
        return link
      }
      if (p["M"] != null)
      {
        key := p["K"]
        val := p["V"]
        link := "${makeTypeLink(key,map)}:${makeTypeLink(val,map)}"
        if (t.isNullable) link = "[" + link + "]?"
        return link
      }
      if (p["R"] != null)
      {
        buf := StrBuf().addChar('|')
        keys := p.keys.rw.sort |Str a, Str b -> Int| { return a <=> b }
        keys.each |Str k, Int i|
        {
          if (k == "R") return
          if (i > 0) buf.add(", ")
          buf.add(makeTypeLink(p[k], map))
        }
        if (p["R"] != Void#) buf.add(" -> ").add(makeTypeLink(p["R"], map))
        if (buf.size == 1) buf.add("->") // for |->|
        buf.addChar('|')
        if (t.isNullable) buf.add("?")
        return buf.toStr
      }
    }

    // Skip FFI types for now
    if (t.toStr[0] == '[') return t.toStr

    link := (t.pod.name == "sys" && t.name.size == 1) ?
       "<a href='${map(Obj#)}'>$t.name</a>" :
       "<a href='${map(t)}'>$t.name</a>"

    if (t.isNullable) link += "?"
    return link
  }
}