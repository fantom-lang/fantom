//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Aug 11  Brian Frank  Creation
//

**
** HtmlSyntaxWriter outputs a SyntaxDoc to HTML
**
class HtmlSyntaxWriter
{

  new make(OutStream out := Env.cur.out)
  {
    this.out = out
  }

  ** Close underlying output stream
  Bool close() { out.close }

  ** Write an entire HTML file with proper head, body
  ** types using default CSS
  This writeDoc(SyntaxDoc doc)
  {
    out.print(
      Str<|<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN"
            "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
           <html>
           <head>
              <meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>
              <style type='text/css'>
              pre { margin: 0px;
                    font: 9pt Monaco, "Courier New", monospace;}
              b   { color: #f00; font-weight: normal; }
              i   { color: #00f; font-style: normal; }
              em  { color: #077; font-style: normal; }
              q   { color: #070; font-style: normal; }
              q:before, q:after { content: ""; }
           </style>
           </head>
           <body>|>)
    writeLines(doc)
    out.print("</body></html>")
    return this
  }

  ** Write the lines of the document as HTML elements.  This
  ** method does not generate HTML head/body tags.
  This writeLines(SyntaxDoc doc)
  {
    doc.eachLine |line| { writeLine(line) }
    return this
  }

  ** Write a single syntax line as styled HTML
  This writeLine(SyntaxLine line)
  {
    out.print("<pre id='").print(line.num).print("'>&nbsp;")
    line.eachSegment |type, text|
    {
      if (type.html != null) out.print("<").print(type.html).print(">")
      out.writeXml(text)
      if (type.html != null) out.print("</").print(type.html).print(">")
    }
    out.print("\n</pre>")
    return this
  }

  private OutStream out

}

