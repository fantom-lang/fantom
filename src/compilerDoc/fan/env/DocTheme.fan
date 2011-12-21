//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Dec 11  Brian Frank  Creation
//

using web

**
** DocTheme is responsible for providing the common chrome, styling,
** and breadcrumb across different DocRenderers.  The theme used by
** renderers is defined by `DocEnv.theme`.
**
const class DocTheme
{

  **
  ** Write opening HTML for page.  This should generate the
  ** doc type, html, head, and opening body tags.  Any common
  ** header should always be generated here.
  **
  virtual Void writeStart(DocRenderer r)
  {
    out := r.out
    out.docType
    out.html
    out.head
      .title.esc(r.doc.title).titleEnd
      .printLine("<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>")
      .includeCss(r.doc is DocTopIndex ? `style.css` : `../style.css`)
      .headEnd
    out.body
  }

  **
  ** Write navigation breadcrumbs for given renderer
  **
  virtual Void writeBreadcrumb(DocRenderer r)
  {
    out := r.out
    doc := r.doc
    out.div("class='breadcrumb'").ul
    if (doc is DocTopIndex)
    {
      out.li.a(`index.html`).w("Doc Index").aEnd.liEnd
    }
    else
    {
      out.li.a(`../index.html`).w("Doc Index").aEnd.liEnd
      out.li.a(`index.html`).w(r.doc.space.breadcrumb).aEnd.liEnd
      if (doc isnot DocSrc) out.li.a(`${doc.docName}.html`).w(r.doc.breadcrumb).aEnd.liEnd
      else
      {
        src := (DocSrc)doc
        type := src.pod.type(src.uri.basename, false)
        if (type != null)
          out.li.a(`${type.docName}.html`).w(type.breadcrumb).aEnd.liEnd
        out.li.a(`${doc.docName}.html`).w(src.breadcrumb).aEnd.liEnd
      }
    }
    out.ulEnd.divEnd
  }

  **
  ** Write closing HTML for page.  This should generate the
  ** common footer and close the body and html tags.
  **
  virtual Void writeEnd(DocRenderer r)
  {
    out := r.out
    out.bodyEnd
    out.htmlEnd
  }

}