//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 08  Andy Frank  Creation
//

using compiler
using fandoc

**
** FanToHtml generates a syntax color coded HTML fragment from a
** Fantom source file.  The actual CSS styles are not defined by this
** class, and should be set by the parent HTML markup or external
** CSS file.
**
**   // parse the file below into the markup below
**   FanToHtml(in, out).parse
**
**   class Foo
**   {
**     Int x := 5
**   }
**
**   <div class='src'>
**   <pre>
**   <span class='k'>class<span>Foo
**   <span class='b'>{</span>
**     Int x := 5
**   <span class='b'>}</span>
**   <pre>
**   </div>
**
** The default CSS class names can be changed by modifing the
** respective fields.  They default to a single character to
** preserve space:
**
**   source        =>  src
**   bracket       =>  b
**   keyword       =>  k
**   string        =>  s
**   char          =>  c
**   uri           =>  u
**   blockComment  =>  x
**   lineComment   =>  y
**   fandocComment =>  z
**
class FanToHtml
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Create a new FanToHtml to parse the given InStream to the
  ** given OutStream.  The slots map is a slot name to line
  ** number map.  If non-null, it will be used to attempt to
  ** place an anchor where the respective slot is defined.
  **
  new make(InStream in, OutStream out, [Str:Int]? slots := null)
  {
    this.in    = FanToHtmlInStream(in)
    this.out   = out
    this.slots = slots == null ? Str:Int[:] : slots
    this.used  = Str:Bool[:]
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the source file into a HTML fragment.
  **
  Void parse()
  {
    out.print("<div class='$classSource'>\n")
    out.print("<pre>\n")
    if (in.peek == '#') shebang
    while (nextToken) {}
    out.print("</pre>\n")
    out.print("</div>\n")
  }

  **
  ** Parse the next token.
  **
  private Bool nextToken()
  {
    peek := in.peek
    if (peek == null) return false

    if (peek.isAlphaNum || peek == '_') identifier
    else if (brackets.get(peek, false)) bracket
    else if (peek == '\'') char
    else if (peek == '\"') string
    else if (peek == '`') uri
    else if (peek == '/') comment
    else if (peek == '*') fandoc
    else safe(in.next)
    return  true
  }

  **
  ** Parse an identifier.
  **
  private Void identifier()
  {
    id := in.readStrToken(512) |Int ch->Bool|
    {
      return !ch.isAlphaNum && ch != '_'
    }
    if (keywords.get(id, false))
    {
      out.print("<span class='").print(classKeyword).print("'>")
      out.print(id)
      out.print("</span>")
    }
    else if (slots[id] == in.line && used[id] == null)
    {
      used[id] = true
      out.print("<span id='").print(id).print("'>")
      out.print(id)
      out.print("</span>")
    }
    else out.print(id)
  }

  **
  ** Parse a bracket.
  **
  private Void bracket()
  {
    out.print("<span class='").print(classBracket).print("'>")
    out.writeChar(in.next)
    while (brackets.get(in.peek ?: 0, false)) // optimize consecutive brackets like () or []
      out.writeChar(in.next)
    out.print("</span>")
  }

  **
  ** Parse a char literal.
  **
  private Void char()
  {
    out.print("<span class='").print(classString).print("'>")
    out.writeChar(in.next) // start quote
    ch := in.next
    while (ch != '\'')
    {
      safe(ch)
      peek := in.peek
      if (ch == '\\' && (peek == '\'' || peek == '\\'))
        out.writeChar(in.next)
      ch = in.next
    }
    out.writeChar(ch) // end quote
    out.print("</span>")
  }

  **
  ** Parse a string literal.
  **
  private Void string()
  {
    out.print("<span class='").print(classString).print("'>")
    out.writeChar(in.next) // start quote
    ch := in.next
    while (ch != '\"')
    {
      safe(ch)
      peek := in.peek
      if (ch == '\\' && (peek == '\"' || peek == '\\'))
        out.writeChar(in.next)
      ch = in.next
    }
    out.writeChar(ch)  // end quote
    out.print("</span>")
  }

  **
  ** Parse a Uri literal.
  **
  private Void uri()
  {
    out.print("<span class='").print(classUri).print("'>")
    out.writeChar(in.next) // start quote
    ch := in.next
    while (ch != '`')
    {
      safe(ch)
      ch = in.next
    }
    out.writeChar(ch)  // end quote
    out.print("</span>")
  }

  **
  ** Parse a comment.
  **
  private Void comment()
  {
    in.next // eat '/'
    peek := in.peek
    if (peek == '/')
    {
      ch := in.read
      out.print("<span class='y'>/")
      while (ch != null && !nl(ch))
      {
        safe(ch)
        ch = in.next
      }
      out.print("</span>")
      if (nl(ch)) out.writeChar(ch)
    }
    else if (peek == '*')
    {
      ch := in.read
      out.print("<span class='x'>/*")
      a := in.next
      b := in.next
      stack := 1
      while (true)
      {
        if (a == '/' && b == '*')
        {
          stack++
          safe(a)
          safe(b)
          a = in.next
          b = in.next
        }
        else if (a == '*' && b == '/')
        {
          stack--
          safe(a)
          safe(b)
          if (stack == 0) break
          a = in.next
          b = in.next
        }
        else
        {
          safe(a)
          a = b
          b = in.next
        }
      }
      out.print("</span>")
    }
    else
    {
      // was not acutally a comment
      out.writeChar('/')
    }
  }

  **
  ** Parse a fandoc comment.
  **
  private Void fandoc()
  {
    in.read // eat first '*'
    if (in.peek == '*')
    {
      in.read // eat second '*'
      out.print("<span class='z'>**")
      ch := in.next
      while (ch != null && !nl(ch))
      {
        safe(ch)
        ch = in.next
      }
      out.print("</span>")
      if (nl(ch)) out.writeChar(ch)
    }
    else
    {
      // not actually a fandoc commnet
      out.writeChar('*')
    }
  }

  **
  ** Parse a #! shebang
  **
  private Void shebang()
  {
    out.print("<span>")
    ch := in.next
    while (ch != null && !nl(ch))
    {
      safe(ch)
      ch = in.next
    }
    if (nl(ch)) out.writeChar(ch)
    out.print("</span>")
  }

  **
  ** Escape <, &, and > characters.
  **
  private Void safe(Int ch)
  {
    switch (ch)
    {
      case '<': out.print("&lt;")
      case '>': out.print("&gt;")
      case '&': out.print("&amp;")
      default: out.writeChar(ch)
    }
  }

  **
  ** Return true if ch is a newline character.
  **
  private Bool nl(Int? ch)
  {
    return ch == '\n' || ch == 0x0d
  }

//////////////////////////////////////////////////////////////////////////
// CSS class names
//////////////////////////////////////////////////////////////////////////

  ** The top level <div> CSS class name.
  Str classSource := "src"

  ** The CSS class name used to style brackets (parens, curly brace).
  Str classBracket := "b"

  ** The CSS class name used to style keywords.
  Str classKeyword := "k"

  ** The CSS class name used to style strings.
  Str classString := "s"

  ** The CSS class name used to style characters.
  Str classChar := "c"

  ** The CSS class name used to style URI's.
  Str classUri := "u"

  ** The CSS class name used to style block comments.
  Str classBlockComment := "x"

  ** The CSS class name used to style single line comments.
  Str classLineComment := "y"

  ** The CSS class name used to style fandoc comments.
  Str classFandocComment := "z"

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private FanToHtmlInStream in  // the source file to parse
  private OutStream out         // where to write results
  private Str:Int slots         // map of slots to line numbers
  private Str:Bool used         // keep track of already anchored slots

  private static const Int:Bool brackets :=
  [
    '{': true,'}': true,
    '(': true,')': true,
    '[': true,']': true,
  ]

  private static const Str:Bool keywords
  static
  {
    list :=
    [
      "abstract",  "finally",    "readonly",
      "as",        "for",        "return",
      "assert",    "foreach",    "static",
      "break",     "goto",       "super",
      "case",      "if",         "switch",
      "catch",     "internal",   "this",
      "class",     "is",         "throw",
      "const",     "mixin",      "true",
      "continue",  "native",     "try",
      "default",   "new",        "using",
      "do",        "null",       "virtual",
      "else",      "override",   "volatile",
      "enum",      "private",    "void",
      "false",     "protected",  "while",
      "final",     "public",     "once"
     ]
     map := Str:Bool[:]
     list.each |Str s| { map[s] = true }
     keywords = map
  }
}

**************************************************************************
** FanToHtmlInStream is used for line counting.
**************************************************************************

internal class FanToHtmlInStream : InStream
{
  **
  ** Wrap the given base stream.
  **
  new make(InStream base) : super(base) {}

  **
  ** Read the next character from the base stream.  If the
  ** character is a newline, increment our current line.
  **
  Int? next()
  {
    ch := readChar
    if (ch == 0x0a || ch == 0x0d) line++
    return ch
  }

  **
  ** The current line number.
  **
  Int line := 1
}