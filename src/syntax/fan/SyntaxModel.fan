//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jul 08  Brian Frank  Creation
//

**
** SyntaxDoc models a full document as a series of SyntaxLines.
**
class SyntaxDoc
{

  **
  ** Parse an input stream into a document using given rules.
  ** The input stream is guaranteed to be closed.
  **
  static SyntaxDoc parse(SyntaxRules rules, InStream in)
  {
    try
      return SyntaxParser(rules).parse(in)
    finally
      in.close
  }

  ** Internal constructor
  internal new make(SyntaxRules rules)
  {
    this.rules = rules
  }

  ** Rules used to parse this document.
  SyntaxRules rules { private set }

  ** Iterate each line of the document.
  Void eachLine(|SyntaxLine| f)
  {
    for (x := lines; x != null; x = x.next) f(x)
  }

  internal SyntaxLine? lines
}

**************************************************************************
** SyntaxLine
**************************************************************************

**
** SyntaxLine models one parsed line of code
**
class SyntaxLine
{
  ** Internal constructor
  internal new make(Int num) { this.num = num }

  ** One based line number
  const Int num

  ** Iterate each segment span of text in the line
  Void eachSegment(|SyntaxType type, Str text| f)
  {
    for (i:=0; i<segments.size; i+=2)
    {
      f(segments[i], segments[i+1])
    }
  }

  internal SyntaxLine? next
  internal Obj[] segments := [,]  // SyntaxType/Str pairs
}

**************************************************************************
** SyntaxType
**************************************************************************

**
** SyntaxType models a syntax specific segment type such keyword or comment
**
enum class SyntaxType
{
  ** Normal text
  text(null),

  ** Bracket such as '{', '}', '(', ')', '[', or ']'
  bracket("b"),

  ** Language specific keyword
  keyword("i"),

  ** String literal
  literal("em"),

  ** Comment section either to end of line or multi-line block
  comment("q")

  private new make(Str? html) { this.html = html }

  ** HTML element to use for styled output
  internal const Str? html
}

