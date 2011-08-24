//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Aug 2011  Andy Frank  Creation
//

using util
using web

**
** LocalDocWriter
**
class LocalDocWriter
{
  ** Constructor.
  new make(|This| f)
  {
    f(this)
    if (pods == null) pods = env.pods
  }

  ** Output dir to write files.
  const File outDir := Env.cur.workDir + `doc/`

  ** DocEnv for this writer.
  DocEnv env

  ** Pods to render. Defaults to all pods.
  DocPod[] pods

  ** Write top index and resource files.
  Bool index := true

  ** Write pods and return any errors.
  DocErr[] write()
  {
    WebOutStream? out

    if (index)
    {
      // css
      outDir.plus(`style.css`).out.printLine(css).close

      // index
      out = WebOutStream(outDir.plus(`index.html`).out)
      writeIndex(out)
      out.close
    }

    // pods
    pods.each |pod|
    {
      if (pod.chapters.isEmpty)
      {
        // pod index
        out = WebOutStream(outDir.plus(`${pod.name}/index.html`).out)
        writePodIndex(out, pod)
        out.close

        // types
        pod.types.each |type|
        {
          out = WebOutStream(outDir.plus(`${pod.name}/${type.name}.html`).out)
          writeType(out, type)
          out.close
        }
      }
      else
      {
        // manual index
        out = WebOutStream(outDir.plus(`${pod.name}/index.html`).out)
        writeManualIndex(out, pod)
        out.close

        // chapters
        pod.chapters.each |chapter|
        {
          out = WebOutStream(outDir.plus(`${pod.name}/${chapter.name}.html`).out)
          writeChapter(out, chapter)
          out.close
        }
      }
    }

    // return errs
    return env.errHandler.errs
  }

//////////////////////////////////////////////////////////////////////////
// HTML
//////////////////////////////////////////////////////////////////////////

  ** Start a HTML page.
  virtual Void writeStart(WebOutStream out, Str title, Obj? obj)
  {
    // path to resource files
    path := obj == null ? "" : "../"

    // start HTML doc
    out.docType
    out.html
    out.head
      .title.esc(title).titleEnd
      .printLine("<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>")
      .includeCss(`${path}style.css`)
      .headEnd
    out.body

    // navigation
    switch (obj?.typeof)
    {
      case DocPod#:
          out.ul("class='nav'")
            .li.a(`../index.html`).w("Home").aEnd.liEnd
            .li.a(`index.html`).w(obj->name).aEnd.liEnd
            .ulEnd

      case DocType#:
      case DocChapter#:
          out.ul("class='nav'")
            .li.a(`../index.html`).w("Home").aEnd.liEnd
            .li.a(`index.html`).w(obj->pod).aEnd.liEnd
            .li.a(`${obj->name}.html`).w(obj->name).aEnd.liEnd
            .ulEnd
    }
  }

  ** Start a HTML page.
  virtual Void writeEnd(WebOutStream out)
  {
    out.bodyEnd
    out.htmlEnd
  }

//////////////////////////////////////////////////////////////////////////
// Index
//////////////////////////////////////////////////////////////////////////

  ** Write top index.
  virtual Void writeIndex(WebOutStream out)
  {
    // header
    writeStart(out, "Home", null)
    out.div("class='index'")

    // sort pods by manual/api
    manuals := DocPod[,]
    apis    := DocPod[,]
    env.pods.each |p|
    {
      if (p.chapters.isEmpty) apis.add(p)
      else manuals.add(p)
    }

    // manuals
    out.div("class='manuals'")
    out.h2.w("Manuals").h2End
    out.table
    manuals.each |pod|
    {
      out.tr
        .td.a(`${pod.name}/index.html`).w(pod.name).aEnd.tdEnd
        .td.w(pod.summary)
        .div
        pod.chapters.each |ch,i|
        {
          if (i > 0) out.w(", ")
          out.a(`${pod.name}/${ch.name}.html`).w("$ch.name").aEnd
        }
        out.divEnd
        out.tdEnd
     out.trEnd
    }
    out.tableEnd
    out.divEnd

    // apis
    out.div("class='apis'")
    out.h2.w("APIs").h2End
    out.table
    apis.each |pod|
    {
      out.tr
        .td.a(`${pod.name}/index.html`).w(pod.name).aEnd.tdEnd
        .td.w(pod.summary).tdEnd
        .trEnd
    }
    out.tableEnd
    out.divEnd

    out.divEnd
    writeEnd(out)
  }

//////////////////////////////////////////////////////////////////////////
// Pod
//////////////////////////////////////////////////////////////////////////

  ** Write pod index.
  private Void writePodIndex(WebOutStream out, DocPod pod)
  {
    // header
    writeStart(out, pod.name, pod)

    // TODO FIXT: should this just be all done here?
    // type table
    out.div("class='article'")
    IndexRenderer(env, out).writeTypeIndex(pod)

    // type list
    out.ul("class='sidebar'")
    pod.types.each |t|
    {
      out.li.a(`${t.name}.html`).w(t.name).aEnd.liEnd
    }
    out.ulEnd
    out.divEnd

    // pod doc
    if (pod.podDoc != null)
    {
      // chapter content
      out.div("class='pod-doc article'")
      writeChapterContent(out, pod.podDoc)
      out.divEnd
    }

    writeEnd(out)
  }

  ** Write Type.
  private Void writeType(WebOutStream out, DocType type)
  {
    // header
    writeStart(out, type.qname, type)

    // type docs
    out.div("class='article'")
    TypeRenderer(env, out, type).writeType

    // slot list
    out.ul("class='sidebar'")
    type.slots.each |slot|
    {
      out.li.a(`#$slot.name`).w(slot.name).aEnd.liEnd
    }
    out.ulEnd
    out.divEnd
    writeEnd(out)
  }

//////////////////////////////////////////////////////////////////////////
// Manual
//////////////////////////////////////////////////////////////////////////

  ** Write manual index.
  virtual Void writeManualIndex(WebOutStream out, DocPod pod)
  {
    writeStart(out, pod.name, pod)
    IndexRenderer(env, out).writeChapterIndex(pod)
    writeEnd(out)
    out.close
  }

  ** Write chapter.
  virtual Void writeChapter(WebOutStream out, DocChapter chapter)
  {
    writeStart(out, chapter.qname, chapter)
    out.div("class='article'")
    out.h1.esc(chapter.name).h1End
    writeChapterContent(out, chapter)
    out.divEnd
    writeEnd(out)
    out.close
  }

  ** Write chapter content.
  virtual Void writeChapterContent(WebOutStream out, DocChapter chapter)
  {
    // content
    r := ChapterRenderer(env, out, chapter)
    r.writeChapter

    // TODO FIXIT: DocChapter.headings
    // headings
    out.ul("class='sidebar'")
    r.headings.each |h|
    {
      out.li.a(`#$h.anchorId`).esc(h.title).aEnd.liEnd
    }
    out.ulEnd
  }

//////////////////////////////////////////////////////////////////////////
// CSS
//////////////////////////////////////////////////////////////////////////

  private static const Str css :=
   "body {
      font:14px Helvetica Neue, Arial, sans-serif;
      padding:0; margin:1em auto 4em auto;
      width:900px;
    }

    a {
      color:#00c;
    }

    pre, code {
      font-size:13px;
      color:#666;
    }

    pre {
      margin:1em 2em;
      overflow-y:hidden;
      overflow-x:auto;
    }

    code.sig,
    code.sig a {
      color:#070;
    }

    table {
      border-collapse:collapse;
      border-top:1px solid #d9d9d9;
    }

    table tr {
      border-bottom:1px solid #d9d9d9;
    }

    table tr:nth-child(odd) {
      background:#f5f5f5;
    }

    table td {
      padding:0.25em 0.5em;
    }

    table td div {
      font-size:12px;
    }

    table tr.section {
      background:none;
    }

    table tr.section td {
      font-weight:bold;
      padding:1em 0em;
    }

    h1 > span:first-child {
      display:block;
      font-size:60%;
    }

    dl {
      margin:2em 0 1em 0;
    }

    dl dt {
      border-top:1px solid #ccc;
      font-weight:bold;
      padding:0.5em 0 0 0;
    }

    ul.nav {
      margin:0;
      padding:0 0 1em 0;
      border-bottom:1px solid #ccc;
    }

    ul.nav li {
      display:inline-block;
      margin:0;
      padding:0;
    }

    ul.nav li:after {
      margin:0 0.5em;
      content:'\\00bb';
      color:#999;
    }

    ul.nav li:last-child:after {
      content:'';
    }

    div.article {
      padding-right:12em;
      position:relative;
    }

    ul.sidebar {
      position:absolute;
      top:3em;
      right:0;
      width:10em;
      list-style:none;
      padding:0;
      margin:0;
      line-height:1.5em;
    }

    div.pod-doc {
      border-top:1px solid #ccc;
      margin-top:2em;
    }

    div.index > div.manuals {
      float:left;
      width:50%;
    }

    div.index > div.manuals > h2 {
      margin-top:0;
    }

    div.index > div.manuals table {
      border:none;
    }

    div.index > div.manuals table tr {
      background:none;
      border:none;
    }

    div.index > div.manuals table td {
     padding:0.5em 1em;
    }

    div.index > div.manuals table td:last-child {
      padding-right:2em;
    }

    div.index > div.manuals table td:first-child {
      vertical-align:top;
    }

    div.index div.apis {
      padding-left:1em;
    }"
}