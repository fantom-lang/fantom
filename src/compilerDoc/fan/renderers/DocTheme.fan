//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

**
** DocTheme implements standardized HTML look & feel and
** navigation chrome for DocRenderer.
**
const class DocTheme
{
  **
  ** Write opening HTML for page. This method is responsible for:
  **
  **   "Content-Type" response header
  **   <!DOCTYPE>
  **   <html>
  **     <head>
  **       <title/>
  **       {r.writeHeadIncludes}
  **     </head>
  **     <body>
  **
  virtual Void writeStart(DocRenderer r, Str titleStr)
  {
    // head
    out := r.out
    out.docType
    out.html
    out.head
      .title.w("$titleStr.toXml").titleEnd
      .style.w(
        "body {
           font:10pt Lucida Grande, Segoe UI, Arial, sans-serif;
           margin:1em;
         }
         #page-header {
           margin:1em 0;
           position:relavite;
           border-bottom:1px solid #ccc;
         }
         #page-header p {
           position:absolute;
           top:0.75em; right:1em;
         }
         ").styleEnd
      r.writeHeadIncludes
      out.headEnd

    // body
    out.body
  }

  **
  ** Write closing HTML for page. This method is responsible for:
  **
  **   </body>
  **   </html>
  **
  virtual Void writeEnd(DocRenderer r)
  {
    out := r.out
    out.bodyEnd
    out.htmlEnd
  }

}

