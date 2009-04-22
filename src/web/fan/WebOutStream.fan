//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 May 06  Andy Frank  Creation
//

**
** WebOutStream provides methods for generating XML and XHTML content.
**
class WebOutStream : OutStream
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a WebOutStream that wraps the given OutStream.
  **
  new make(OutStream out)
    : super(out)
  {
  }

//////////////////////////////////////////////////////////////////////////
// General Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Convenience for writeChars(obj.toStr).
  **
  This w(Obj? obj)
  {
    writeChars(obj == null ? "null" : obj.toStr)
    return this
  }

  **
  ** Convenience for writeChars(Str.spaces(numSpaces)).
  **
  This tab(Int numSpaces := 2)
  {
    writeChars(Str.spaces(numSpaces))
    return this
  }

  **
  ** Convenience for writeChar('\n').
  **
  This nl()
  {
    writeChar('\n')
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Xml Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Write out a prolog statement using the streams
  ** current charset encoding.
  **
  This prolog()
  {
    writeChars("<?xml version='1.0' encoding='$charset'?>\n")
    return this
  }

  **
  ** Write a start tag. Use attrs to fully specify the attributes
  ** manually. Use empty to optionally close this element without
  ** using an end tag.
  **
  This tag(Str elemName, Str? attrs := null, Bool empty := false)
  {
    writeChar('<')
    writeChars(elemName)
    if (attrs != null) writeChar(' ').writeChars(attrs)
    if (empty) writeChars(" /")
    writeChar('>')
    return this
  }

  **
  ** Write an end tag.
  **
  This tagEnd(Str elemName)
  {
    writeChars("</").writeChars(elemName).writeChar('>')
    return this
  }

//////////////////////////////////////////////////////////////////////////
// DOCTYPE
//////////////////////////////////////////////////////////////////////////

  **
  ** Write the XHTML Strict DOCTYPE.
  **
  This docType()
  {
    writeChars("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n")
    writeChars(" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n")
    return this
  }

//////////////////////////////////////////////////////////////////////////
// html
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <html> tag.
  **
  This html()
  {
    return tag("html", "xmlns='http://www.w3.org/1999/xhtml'").nl
  }

  **
  ** End a <html> tag.
  **
  This htmlEnd()
  {
    return tagEnd("html").nl
  }

//////////////////////////////////////////////////////////////////////////
// head
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <head> tag.
  **
  This head() { return tag("head").nl }

  **
  ** End a <head> tag.
  **
  This headEnd() { return tagEnd("head").nl }

  **
  ** Write a complete <title> tag.
  **
  This title(Str? attrs := null) { return tag("title", attrs) }

  **
  ** End a <title> tag.
  **
  This titleEnd() { return tagEnd("title").nl }

  **
  ** Write a complete <link> tag for an external CSS stylesheet.
  ** If this URI has already been included in this WebOutStream
  ** instance, then this method does nothing.
  **
  This includeCss(Uri href)
  {
    if (cssUris == null) cssUris = Uri[,]
    if (!cssUris.contains(href))
    {
      attrs := "rel='stylesheet' type='text/css' href='$href.encode.toXml'"
      tag("link", attrs, true).nl
      cssUris.add(href)
    }
    return this
  }

  **
  ** Write a complete <script> tag for an external JavaScript file.
  ** If this URI has already been included in this WebOutStream
  ** instance, then this method does nothing.
  **
  This includeJs(Uri? href := null)
  {
    if (jsUris == null) jsUris = Uri[,]
    if (!jsUris.contains(href))
    {
      tag("script", "type='text/javascript' src='$href.encode.toXml'")
      tagEnd("script").nl
      jsUris.add(href)
    }
    return this
  }

  **
  ** Write a complete <link> tag for an Atom feed resource.
  **
  This atom(Uri href, Str? attrs := null)
  {
    return tag("link rel='alternate' type='application/atom+xml' href='$href.encode.toXml'", attrs, true).nl
  }

  **
  ** Write a complete <link> tag for a RSS feed resource.
  **
  This rss(Uri href, Str? attrs := null)
  {
    return tag("link rel='alternate' type='application/rss+xml' href='$href.encode.toXml'", attrs, true).nl
  }

  **
  ** Write a complete <link> tag for a favicon.  You must specifiy
  ** the MIME type for your icon in the 'attrs' argument:
  **
  **   out.favIcon(`/fav.png`, "type='image/png'")
  **
  This favIcon(Uri href, Str? attrs := null)
  {
    return tag("link rel='icon' href='$href.encode.toXml'", attrs, true).nl
  }

//////////////////////////////////////////////////////////////////////////
// style
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <style> tag.
  **
  This style(Str? attrs := "type='text/css'") { return tag("style", attrs).nl }

  **
  ** End a <style> tag.
  **
  This styleEnd() { return tagEnd("style").nl }

//////////////////////////////////////////////////////////////////////////
// script
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <script> tag.
  **
  This script(Str? attrs := "type='text/javascript'") { return tag("script", attrs).nl }

  **
  ** End a <script> tag.
  **
  This scriptEnd() { return tagEnd("script").nl }

//////////////////////////////////////////////////////////////////////////
// body
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <body> tag.
  **
  This body(Str? attrs := null) { return tag("body", attrs).nl }

  **
  ** End a <body> tag.
  **
  This bodyEnd() { return tagEnd("body").nl }

//////////////////////////////////////////////////////////////////////////
// h1, h2, h3, h4, h5, h6
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <h1> tag.
  **
  This h1(Str? attrs := null) { return tag("h1", attrs) }

  **
  ** End a <h1> tag.
  **
  This h1End() { return tagEnd("h1").nl }

  **
  ** Start a <h2> tag.
  **
  This h2(Str? attrs := null) { return tag("h2", attrs) }

  **
  ** End a <h2> tag.
  **
  This h2End() { return tagEnd("h2").nl }

  **
  ** Start a <h3> tag.
  **
  This h3(Str? attrs := null) { return tag("h3", attrs) }

  **
  ** End a <h3> tag.
  **
  This h3End() { return tagEnd("h3").nl }

  **
  ** Start a <h4> tag.
  **
  This h4(Str? attrs := null) { return tag("h4", attrs) }

  **
  ** End a <h4> tag.
  **
  This h4End() { return tagEnd("h4").nl }

  **
  ** Start a <h5> tag.
  **
  This h5(Str? attrs := null) { return tag("h5", attrs) }

  **
  ** End a <h5> tag.
  **
  This h5End() { return tagEnd("h5").nl }

  **
  ** Start a <h6> tag.
  **
  This h6(Str? attrs := null) { return tag("h6", attrs) }

  **
  ** End a <h6> tag.
  **
  This h6End() { return tagEnd("h6").nl }

//////////////////////////////////////////////////////////////////////////
// div
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <div> tag.
  **
  This div(Str? attrs := null) { return tag("div", attrs).nl }

  **
  ** End a <div> tag.
  **
  This divEnd() { return tagEnd("div").nl }

//////////////////////////////////////////////////////////////////////////
// span
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <span> tag.
  **
  This span(Str? attrs := null) { return tag("span", attrs) }

  **
  ** End a <span> tag.
  **
  This spanEnd() { return tagEnd("span") }

//////////////////////////////////////////////////////////////////////////
// p
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <p> tag.
  **
  This p(Str? attrs := null) { return tag("p", attrs).nl }

  **
  ** End a <p> tag.
  **
  This pEnd() { return tagEnd("p").nl }

//////////////////////////////////////////////////////////////////////////
// b
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <b> tag.
  **
  This b(Str? attrs := null) { return tag("b", attrs) }

  **
  ** End a <b> tag.
  **
  This bEnd() { return tagEnd("b") }

//////////////////////////////////////////////////////////////////////////
// i
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <i> tag.
  **
  This i(Str? attrs := null) { return tag("i", attrs)  }

  **
  ** End a <i> tag.
  **
  This iEnd() { return tagEnd("i") }

//////////////////////////////////////////////////////////////////////////
// em
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <em> tag.
  **
  This em(Str? attrs := null) { return tag("em", attrs) }

  **
  ** End a <em> tag.
  **
  This emEnd() { return tagEnd("em") }

//////////////////////////////////////////////////////////////////////////
// pre
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <pre> tag.
  **
  This pre(Str? attrs := null) { return tag("pre", attrs) }

  **
  ** End a <pre> tag.
  **
  This preEnd() { return tagEnd("pre").nl }

//////////////////////////////////////////////////////////////////////////
// code
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <code> tag.
  **
  This code(Str? attrs := null) { return tag("code", attrs) }

  **
  ** End a <code> tag.
  **
  This codeEnd() { return tagEnd("code") }

//////////////////////////////////////////////////////////////////////////
// hr
//////////////////////////////////////////////////////////////////////////

  **
  ** Write out a complete <hr/> tag.
  **
  This hr() { return tag("hr", null, true).nl }

//////////////////////////////////////////////////////////////////////////
// br
//////////////////////////////////////////////////////////////////////////

  **
  ** Write out a complete <br/> tag.
  **
  This br() { return tag("br", null, true) }

//////////////////////////////////////////////////////////////////////////
// a
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <a> tag.
  **
  This a(Uri href, Str? attrs := null)
  {
    return tag("a href='$href.encode.toXml'", attrs)
  }

  **
  ** End a <a> tag.
  **
  This aEnd() { return tagEnd("a") }

//////////////////////////////////////////////////////////////////////////
// img
//////////////////////////////////////////////////////////////////////////

  **
  ** Write a complete <img> tag.
  **
  This img(Uri src, Str? attrs := null)
  {
    return tag("img src='$src.encode.toXml'", attrs, true)
  }

//////////////////////////////////////////////////////////////////////////
// table
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <table> tag.
  **
  This table(Str? attrs := null) { return tag("table", attrs).nl }

  **
  ** End a <table> tag.
  **
  This tableEnd() { return tagEnd("table").nl }

//////////////////////////////////////////////////////////////////////////
// tr
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <tr> tag.
  **
  This tr(Str? attrs := null) { return tag("tr", attrs).nl }

  **
  ** End a <tr> tag.
  **
  This trEnd() { return tagEnd("tr").nl }

//////////////////////////////////////////////////////////////////////////
// th
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <th> tag.
  **
  This th(Str? attrs := null) { return tag("th", attrs) }

  **
  ** End a <th> tag.
  **
  This thEnd() { return tagEnd("th").nl }

//////////////////////////////////////////////////////////////////////////
// td
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <td> tag.
  **
  This td(Str? attrs := null) { return tag("td", attrs) }

  **
  ** End a <td> tag.
  **
  This tdEnd() { return tagEnd("td").nl }

//////////////////////////////////////////////////////////////////////////
// ul/ol/li
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <ul> tag.
  **
  This ul(Str? attrs := null) { return tag("ul", attrs).nl }

  **
  ** End a <ul> tag.
  **
  This ulEnd() { return tagEnd("ul").nl }

  **
  ** Start a <ol> tag.
  **
  This ol(Str? attrs := null) { return tag("ol", attrs).nl }

  **
  ** End a <ol> tag.
  **
  This olEnd() { return tagEnd("ol").nl }

  **
  ** Start a <li> tag.
  **
  This li(Str? attrs := null) { return tag("li", attrs).nl }

  **
  ** End a <li> tag.
  **
  This liEnd() { return tagEnd("li").nl }

//////////////////////////////////////////////////////////////////////////
// dl/dd/dt
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <dl> tag.
  **
  This dl(Str? attrs := null) { return tag("dl", attrs).nl }

  **
  ** End a <dl> tag.
  **
  This dlEnd() { return tagEnd("dl").nl }

  **
  ** Start a <dt> tag.
  **
  This dt(Str? attrs := null) { return tag("dt", attrs).nl }

  **
  ** End a <dt> tag.
  **
  This dtEnd() { return tagEnd("dt").nl }

  **
  ** Start a <dd> tag.
  **
  This dd(Str? attrs := null) { return tag("dd", attrs).nl }

  **
  ** End a <dd> tag.
  **
  This ddEnd() { return tagEnd("dd").nl }

//////////////////////////////////////////////////////////////////////////
// form
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <form> tag.
  **
  This form(Str? attrs := null) { return tag("form", attrs).nl }

  **
  ** End a <form> tag.
  **
  This formEnd() { return tagEnd("form").nl }

//////////////////////////////////////////////////////////////////////////
// input
//////////////////////////////////////////////////////////////////////////

  **
  ** Write a complete <input> tag.
  **
  This input(Str? attrs := null)
  {
    return tag("input", attrs, true)
  }

  **
  ** Convenience for input("type='text'" + attrs).
  **
  This textField(Str? attrs := null)
  {
    return tag("input type='text'", attrs, true)
  }

  **
  ** Convenience for input("type='password'" + attrs).
  **
  This password(Str? attrs := null)
  {
    return tag("input type='password'", attrs, true)
  }

  **
  ** Convenience for input("type='hidden'" + attrs).
  **
  This hidden(Str? attrs := null)
  {
    return tag("input type='hidden'", attrs, true)
  }

  **
  ** Convenience for input("type='button'" + attrs).
  **
  This button(Str? attrs := null)
  {
    return tag("input type='button'", attrs, true)
  }

  **
  ** Convenience for input("type='checkbox'" + attrs)
  **
  This checkbox(Str? attrs := null)
  {
    return tag("input type='checkbox'", attrs, true)
  }

  **
  ** Convenience for input("type='radio'" + attrs)
  **
  This radio(Str? attrs := null)
  {
    return tag("input type='radio'", attrs, true)
  }

  **
  ** Convenience for input("type='submit'" + attrs).
  **
  This submit(Str? attrs := null)
  {
    return tag("input type='submit'", attrs, true)
  }

//////////////////////////////////////////////////////////////////////////
// select
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <select> tag.
  **
  This select(Str? attrs := null) { return tag("select", attrs).nl }

  **
  ** End a <select> tag.
  **
  This selectEnd() { return tagEnd("select").nl }

  **
  ** Start a <option> tag.
  **
  This option(Str? attrs := null) { return tag("option", attrs) }

  **
  ** End a <option> tag.
  **
  This optionEnd() { return tagEnd("option").nl }

//////////////////////////////////////////////////////////////////////////
// textarea
//////////////////////////////////////////////////////////////////////////

  **
  ** Start a <textarea> tag.
  **
  This textArea(Str? attrs := null) { return tag("textarea", attrs).nl }

  **
  ** End a <textarea> tag.
  **
  This textAreaEnd() { return tagEnd("textarea").nl }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Write 'obj.toStr' to the stream as valid XML text.  The
  ** special control characters amp, lt, apos and quot are
  ** always escaped.  The gt char is escaped only if it is
  ** the first char or if preceeded by the ']' char.  Also
  ** see `sys::Str.toXml`.  If obj is null, then "null" is
  ** written.
  **
  This esc(Obj? obj)
  {
    if (obj == null) return w("null")
    return writeXml(obj.toStr, xmlEscQuotes)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Uri[]? cssUris  // what CSS uris have been added
  private Uri[]? jsUris   // what JavaScript uris have been added

}