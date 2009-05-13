//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler
using fandoc

**
** PodIndexGenerator generates the index file for a pod.
**
class PodIndexGenerator : HtmlGenerator
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(DocCompiler compiler, Location loc, OutStream out)
    : super(compiler, loc, out)
  {
    sorter := |Type a, Type b -> Int| { return a.name.compareIgnoreCase(b.name) }
    filter := |Type t -> Bool| { return showType(t) }

    this.pod = compiler.pod
    this.types = pod.types.rw.sort(sorter).findAll(filter)
  }

//////////////////////////////////////////////////////////////////////////
// Generator
//////////////////////////////////////////////////////////////////////////

  override Str title()
  {
    return pod.name
  }

  override Void header()
  {
    out.print("<ul>\n")
    out.print("  <li><a href='../index.html'>$docHome</a></li>\n")
    out.print("  <li><a href='index.html'>$pod.name</a></li>\n")
    out.print("</ul>\n")
  }

  override Void content()
  {
    out.print("<h1>$pod.name</h1>\n")
    out.print("<table>\n")
    types.each |Type t, Int i|
    {
      // clip doc to first sentence
      cls := i % 2 == 0 ? "even" : "odd"
      doc := t.doc

      out.print("<tr class='$cls'>\n")
      out.print("  <td><a href='${compiler.uriMapper.map(t.qname, loc)}'>$t.name</a></td>\n")
      out.print("  <td>")
      if (doc != null)
      {
        try
        {
          doc = firstSentence(doc)
          fandoc := FandocParser.make.parse("API for $t", doc.in)
          para := fandoc.children.first as Para
          para.children.each |DocNode child| { child.write(this) }
        }
        catch (Err e)
        {
          compiler.log.error("Failed to generate fandoc for $t.qname")
        }
      }
      out.print("</td>\n")
      out.print("</tr>\n")
    }
    out.print("</table>\n")
  }

  override Void sidebar()
  {
    out.print("<h2>Types</h2>\n")
    out.print("<ul class='clean'>\n")
    types.each |Type t|
    {
      out.print("  <li><a href='${compiler.uriMapper.map(t.qname, loc)}'>$t.name</a></li>\n")
    }
    out.print("</ul>\n")
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

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
        if (peek == -1 || peek == ' ' || peek == '\n')
          break;
        else
          buf.addChar(' ')
      }
      else
      {
        buf.addChar(ch)
      }
    }
    return buf.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Pod pod
  Type[] types

}