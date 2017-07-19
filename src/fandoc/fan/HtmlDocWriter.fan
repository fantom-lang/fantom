//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Feb 07  Brian Frank  Creation
//

**
** HtmlDocWriter outputs a fandoc model to XHTML
**
** See [pod doc]`pod-doc#api` for usage.
**
@Js
class HtmlDocWriter : DocWriter
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(OutStream out := Env.cur.out)
  {
    this.out = out
  }

//////////////////////////////////////////////////////////////////////////
// Config
//////////////////////////////////////////////////////////////////////////

  ** Callback to perform link resolution and checking for
  ** every Link element
  |Link link|? onLink := null

  ** Callback to perform image link resolution and checking
  |Image img|? onImage := null

//////////////////////////////////////////////////////////////////////////
// DocWriter
//////////////////////////////////////////////////////////////////////////

  override Void docStart(Doc doc)
  {
    out.print("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n")
    out.print(" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n")
    out.print("<html>\n")
    out.print("<head>\n")
    docHead(doc)
    out.print("</head>\n")
  }

  virtual Void docHead(Doc doc)
  {
    out.print("  <meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>\n")
    doc.meta.each |Str val, Str key|
    {
      switch (key)
      {
        case "title":
          out.print("  <title>")
          safeText(val)
          out.print("</title>\n")
        default:
          out.print("  <meta")
          attr("name", key)
          attr("content", val)
          out.print("/>\n")
      }
    }
  }

  override Void docEnd(Doc doc)
  {
    out.print("</html>")
  }

  override Void elemStart(DocElem elem)
  {
    if (elem.isBlock) out.writeChar('\n')

    // if hyperlink to code, then wrap in code element
    if (elem.id == DocNodeId.link)
    {
      if (onLink != null) onLink(elem)
      if (elem->isCode) out.print("<code>")
    }

    out.writeChar('<').print(elem.htmlName)
    if (elem.anchorId != null) out.print(" id='$elem.anchorId'")
    switch (elem.id)
    {
      case DocNodeId.link:
        link := elem as Link
        out.print(" href='$link.uri.toXml'")
      case DocNodeId.image:
        img := elem as Image
        if (onImage != null) onImage(img)
        out.print(" src='$img.uri.toXml' alt='")
        safeAttr(img.alt)
        out.print("'")
        if (img.size != null)
        {
          toks := img.size.split('x')
          w := toks.getSafe(0)
          h := toks.getSafe(1)
          if (w != null) out.print(" width='").print(w).print("'")
          if (h != null) out.print(" height='").print(h).print("'")
        }
        out.print("/>")
        return
      case DocNodeId.para:
        para := elem as Para
        if (para.admonition != null)
        {
          out.print(" class='$para.admonition'")
          out.print(">").print(para.admonition).print(": ")
          return
        }
      case DocNodeId.orderedList:
        ol := elem as OrderedList
        out.print(" style='list-style-type:$ol.style.htmlType'")
      case DocNodeId.hr:
        out.printLine("/>")
        return
    }
    out.writeChar('>')
  }

  override Void elemEnd(DocElem elem)
  {
    if (elem.id == DocNodeId.image) return
    if (elem.id == DocNodeId.hr) return
    out.writeChar('<').writeChar('/').print(elem.htmlName).writeChar('>')

    // if hyperlink to code, then wrap in code element
    if (elem.id == DocNodeId.link && ((Link)elem).isCode)
      out.print("</code>")

    if (elem.isBlock) out.writeChar('\n')
  }

  override Void text(DocText text)
  {
    safeText(text.str)
  }

//////////////////////////////////////////////////////////////////////////
// Escapes
//////////////////////////////////////////////////////////////////////////

  private Void attr(Str name, Str val)
  {
    out.writeChar(' ').print(name).print("='")
    safeAttr(val)
    out.writeChar('\'')
  }

  private Void safeAttr(Str s)
  {
    s.each |Int ch|
    {
      if (ch == '<') out.print("&lt;")
      else if (ch == '&') out.print("&amp;")
      else if (ch == '\'') out.print("&#39;")
      else if (ch == '"') out.print("&#34;")
      else out.writeChar(ch)
    }
  }

  private Void safeText(Str s)
  {
    s.each |Int ch|
    {
      if (ch == '<') out.print("&lt;")
      else if (ch == '&') out.print("&amp;")
      else out.writeChar(ch)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream out

}

