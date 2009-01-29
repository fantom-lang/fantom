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
** HtmlGenerator is the base class for HTML generation which
** handles all the navigation and URI concerns
**
abstract class HtmlGenerator : HtmlDocWriter
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(DocCompiler compiler, Location loc, OutStream out)
    : super(out)
  {
    this.compiler = compiler
    this.loc = loc
  }

//////////////////////////////////////////////////////////////////////////
// Generator
//////////////////////////////////////////////////////////////////////////

  Void generate()
  {
    out.print("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n")
    out.print(" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n")
    out.print("<html xmlns='http://www.w3.org/1999/xhtml'>\n")
    out.print("<head>\n")
    out.print("  <title>$title</title>\n")
    out.print("  <meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>\n")
    out.print("  <link rel='stylesheet' type='text/css' href='${pathToRoot}doc.css'/>\n")
    out.print("  <script type='text/javascript' src='${pathToRoot}doc.js'></script>\n")
    //out.print("  <script type='text/javascript' src='${pathToRoot}searchIndex.js'></script>\n")
    out.print("<!--[if lt IE 7]>\n")
    out.print("<script src='http://ie7-js.googlecode.com/svn/version/2.0(beta3)/IE7.js'")
    out.print(" type='text/javascript'></script>\n")
    out.print("<![endif]-->\n")

    out.print("</head>\n")
    out.print("<body onload='Login.check();'>\n")

    // header
    out.print("<div class='header'>\n")
    out.print("<div>\n")
    out.print("<h1><a href='/'>Fan</a></h1>\n")
    out.print("<p id='sidewalkLogin_'>&nbsp;</p>\n")
    out.print("<form method='get' action='/sidewalk/search/'>\n")
    out.print("<p>\n")
    out.print("<input type='text' name='q' size='30' value='Search...'")
    out.print(" onfocus='if (value==\"Search...\") value=\"\"' onblur='if (value==\"\") value=\"Search...\"' />\n")
    out.print("</p>\n")
    out.print("</form>\n")
    out.print("<ul>\n")
    out.print("<li><a href='/'>Home</a></li>\n")
    out.print("<li class='active'><a href='${pathToRoot}index.html'>Docs</a></li>\n")
    out.print("<li><a href='/sidewalk/blog/'>Blog</a></li>\n")
    out.print("<li><a href='/sidewalk/topic/'>Discuss</a></li>\n")
    out.print("</ul>")
    out.print("</div>\n")
    out.print("</div>\n")

    out.print("<div class='subHeader'>\n")
    out.print("<div>\n")
    header
    out.print("</div>\n")
    out.print("</div>\n")

    out.print("<div class='content'>\n")
    out.print("<div>\n")
    out.print("<div class='fandoc'>\n")
    content
    out.print("</div>\n")
    out.print("<div class='sidebar'>\n")
    sidebar
    out.print("</div>\n")
    out.print("</div>\n")
    out.print("</div>\n")

    out.print("<div class='footer'>\n")
    out.print("<div>\n")
    footer
    out.print("</div>\n")
    out.print("</div>\n")

    out.print("</body>\n")
    out.print("</html>\n")
    out.close
  }

//////////////////////////////////////////////////////////////////////////
// Hooks
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the title for this document.
  **
  virtual Str title()
  {
    return "Fandoc"
  }

  **
  ** Returnt the relative path to the document root.
  **
  virtual Str pathToRoot()
  {
    return "../"
  }

  **
  ** Generate the header section of the document.
  **
  virtual Void header()
  {
  }

  **
  ** Generate the content section of the document.
  **
  virtual Void content()
  {
  }

  **
  ** Generate the footer section of the document.
  **
  virtual Void footer()
  {
    out.print("<p>\n")
    if (compiler.pod != null)
      out.print("$compiler.pod.name $compiler.pod.version\n");
    out.print("[$DateTime.now.toLocale]\n");
    out.print("</p>\n")
  }

  **
  ** Generate the sidebar section of the document.
  **
  virtual Void sidebar()
  {
  }

  **
  ** Generate the search box.
  **
  Void searchBox()
  {
    out.print("<div class='fandocSearch'>\n")
    out.print("<form action='' onsubmit='return false;'>\n")
    out.print("  <div>\n")
    out.print("    <input type='text' id='fandocSearchBox' value='Search...' class='hint'\n")
    out.print("     onkeyup='SearchBox.search(event);'\n");
    out.print("     onfocus='SearchBox.onfocus();' onblur='SearchBox.onblur();' />\n")
    out.print("  </div>\n")
    out.print("  <div id='fandocSearchResults'></div>\n")
    out.print("</form>\n")
    out.print("</div>\n")
  }

//////////////////////////////////////////////////////////////////////////
// HtmlDocWriter
//////////////////////////////////////////////////////////////////////////

  override Void elemStart(DocElem elem)
  {
    if (elem.id === DocNodeId.link)
    {
      link := elem as Link
      if (!link.uri.endsWith(".html"))
      {
        link.uri = compiler.uriMapper.map(link.uri, loc).toStr
        link.isCode = compiler.uriMapper.targetIsCode
      }
    }

    super.elemStart(elem)
  }

//////////////////////////////////////////////////////////////////////////
// Filters
//////////////////////////////////////////////////////////////////////////

  static Bool showType(Type t)
  {
    if (t.isInternal) return false
    if (t.isSynthetic) return false
    if (t.fits(Test#) && t != Test#) return false
    if (t.facet("nodoc") == true) return false
    return true
  }

  static Bool showSlot(Type t, Slot s)
  {
    if (s.isSynthetic) return false
    if (s.facet("nodoc") == true) return false
    return t == s.parent
  }

  static Bool showByDefault(Type t, Slot s)
  {
    v := s.isPublic || s.isProtected
    v &= t == Obj# || s.parent != Obj#
    v &= t == s.parent
    return v
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  DocCompiler compiler
  Location loc
  Str docHome := "Doc Home"
}