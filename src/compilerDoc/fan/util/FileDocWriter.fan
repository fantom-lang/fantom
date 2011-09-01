//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Aug 2011  Andy Frank  Creation
//

using util
using web
using syntax

**
** FileDocWriter
**
class FileDocWriter
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
  virtual DocErr[] write()
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
      echo("Writing pod '$pod.name' ...")
      podDir := outDir + `${pod.name}/`
      if (!pod.isManual)
      {
        // pod index
        out = WebOutStream(podDir.plus(`index.html`).out)
        writePodIndex(out, pod)
        out.close

        // types
        pod.types.each |type|
        {
          out = WebOutStream(podDir.plus(`${type.name}.html`).out)
          writeType(out, pod, type)
          out.close
        }

        // source files
        if (!pod.sources.isEmpty)
        {
          zip := pod.open
          try
          {
            pod.sources.each |src|
            {
              rules := SyntaxRules.loadForExt(src.ext ?: "?") ?:SyntaxRules()
              syntaxDoc := SyntaxDoc.parse(rules, zip.contents[src].in)
              out = WebOutStream(podDir.plus(`src-${src.name}.html`).out)
              writeSource(out, pod, src, syntaxDoc)
              out.close
            }
          }
          finally zip.close
        }
      }
      else
      {
        // manual index
        out = WebOutStream(podDir.plus(`index.html`).out)
        writeManualIndex(out, pod)
        out.close

        // chapters
        pod.chapters.each |chapter|
        {
          out = WebOutStream(podDir.plus(`${chapter.name}.html`).out)
          writeChapter(out, pod, chapter)
          out.close
        }

        // resources
        if (!pod.resources.isEmpty)
        {
          zip := pod.open
          try
          {
            pod.resources.each |res|
            {
              zip.contents[res].in.pipe(podDir.plus(res.name.toUri).out)
            }
          }
          finally zip.close
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

      case Obj[]#:
          list  := (Obj[])obj
          pod   := (Str)list[0]
          multi := (Bool)list[1]
          src   := (Str)list[2]
          type  := src[0..<src.index(".")]
          out.ul("class='nav'")
            .li.a(`../index.html`).w("Home").aEnd.liEnd
            .li.a(`index.html`).w(pod).aEnd.liEnd
            .li.w(multi ? "Multiple" : "<a href='${type}.html'>$type</a>").liEnd
            .li.a(`src-${list[2]}.html`).w("Source").aEnd.liEnd
            .ulEnd
    }
  }

  ** End HTML page.
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
      if (p.isManual)
        manuals.add(p)
      else
        apis.add(p)
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
  virtual Void writePodIndex(WebOutStream out, DocPod pod)
  {
    // header
    writeStart(out, pod.name, pod)

    // type table
    out.div("class='article'")
    out.div("class='type'")
    IndexRenderer(env, out, pod).writeTypeIndex
    out.divEnd

    // type list
    out.div("class='sidebar'")
    out.h3.w("All Types").h3End
    out.ul
    pod.types.each |t|
    {
      out.li.a(`${t.name}.html`).w(t.name).aEnd.liEnd
    }
    out.ulEnd
    out.divEnd
    out.divEnd

    // pod doc
    if (pod.podDoc != null)
    {
      // chapter content
      out.div("class='pod-doc article' id='pod-doc'")
      ChapterRenderer(env, out, pod.podDoc).writeChapter
      out.div("class='sidebar'")
      out.h3.w("Contents").h3End
      IndexRenderer(env, out, pod).writePodDocToc
      out.divEnd
      out.divEnd
    }

    writeEnd(out)
  }

  ** Write Type.
  virtual Void writeType(WebOutStream out, DocPod pod, DocType type)
  {
    // header
    writeStart(out, type.qname, type)

    // type docs
    out.div("class='article'")
    out.div("class='type'")
    TypeRenderer(env, out, type).writeType
    out.divEnd

    // src
    out.div("class='sidebar'")
    out.h3.w("Source").h3End
    out.ul
    src := pod.source(type.doc.loc.file, false)
    if (src == null) out.li.w("Not available").liEnd
    else out.li.a(`src-${src.name}.html`).w("View Source").aEnd.liEnd
    out.ulEnd

    // src/slot list
    out.h3.w("Slots").h3End
    out.ul
    type.slots.each |slot|
    {
      out.li.a(`#$slot.name`).w(slot.name).aEnd.liEnd
    }
    out.ulEnd
    out.divEnd
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
    IndexRenderer(env, out, pod).writeChapterIndex
    writeEnd(out)
    out.close
  }

  ** Write chapter.
  virtual Void writeChapter(WebOutStream out, DocPod pod, DocChapter chapter)
  {
    writeStart(out, chapter.qname, chapter)
    out.div("class='article'")

    // chapter
    writeChapterNav(out, chapter)
    out.h1.span.w("${chapter.num}.").spanEnd.w(" ").esc(chapter.name).h1End
    ChapterRenderer(env, out, chapter).writeChapter
    writeChapterNav(out, chapter)

    // toc
    out.div("class='sidebar'")
    out.p.a(`index.html`).esc(pod.name).aEnd.pEnd
    IndexRenderer(env, out, pod).writeChapterToc(chapter)
    out.divEnd

    out.divEnd
    writeEnd(out)
    out.close
  }

  ** Write chapter prev/next navigation.
  virtual Void writeChapterNav(WebOutStream out, DocChapter chapter)
  {
    out.ul("class='chapter-nav'")
    if (chapter.prev != null)
      out.li("class='prev'")
        .a(`${chapter.prev.name}.html`)
        .w("${chapter.prev.num}. ").esc(chapter.prev.name)
        .aEnd
        .liEnd
    if (chapter.next != null)
      out.li("class='next'")
        .a(`${chapter.next.name}.html`)
        .w("${chapter.next.num}. ")
        .esc(chapter.next.name).aEnd
        .liEnd
    out.ulEnd
  }

//////////////////////////////////////////////////////////////////////////
// Source
//////////////////////////////////////////////////////////////////////////

  ** Write source code file
  virtual Void writeSource(WebOutStream out, DocPod pod, Uri src, SyntaxDoc doc)
  {
    types := pod.types.findAll { it.loc.file == src.name }
    multi := types.size > 1
    writeStart(out, src.name, [pod.name, multi, src.name])
    out.div("class='src'")
    HtmlSyntaxWriter(out).writeLines(doc)
    out.divEnd
    writeEnd(out)
  }

//////////////////////////////////////////////////////////////////////////
// CSS
//////////////////////////////////////////////////////////////////////////

  ** Return css to use for HTML files.
  virtual Str css()
  {
   "body {
      font:14px Helvetica Neue, Arial, sans-serif;
      padding:0; margin:1em auto 4em auto;
      width:900px;
    }

    a { color:#00c; }
    pre, code { font-size:13px; color:#555; }
    pre { margin:1em 2em; overflow-y:hidden; overflow-x:auto; }
    code.sig, code.sig a { color:#070; }

    table { border-collapse:collapse; border-top:1px solid #d9d9d9; }
    table tr { border-bottom:1px solid #d9d9d9; }
    table tr:nth-child(odd) { background:#f5f5f5; }
    table td { padding:0.25em 0.5em; }
    table td div { font-size:12px; }

    dl { margin:2em 0 1em 0; }
    dl dt {
      border-top:1px solid #ccc;
      font-weight:bold;
      padding:0.5em 0 0 0;
    }
    dl dd { position:relative; margin-bottom:1em; }
    dl dd a.src { position:absolute; top:-2.5em; right:0; font-size:12px; color:#999; }

    ul.nav { margin:0; padding:0 0 1em 0; border-bottom:1px solid #ccc; }
    ul.nav li { display:inline-block; margin:0; padding:0; }
    ul.nav li:after { margin:0 0.5em; content:'\\00bb'; color:#999; }
    ul.nav li:last-child:after { content:''; }

    div.article { padding-right:14em; position:relative; }

    div.sidebar { position:absolute; top:3em; right:0; width:12em; }
    div.sidebar > h3:first-child { margin-top:0; }
    div.sidebar > p { font-weight:bold; }
    div.sidebar > p:first-child { margin-top:0; }
    div.sidebar > ul { padding:0; margin:0 0 0 1.5em; line-height:1.5em; }
    div.sidebar > ul ul { padding-left:1.2em; line-height:1.3em; }
    div.sidebar > ol { padding:0 0 0 2em; margin:0; line-height:1.5em; }
    div.sidebar ol ol { list-style:none; padding-left:0; }
    div.sidebar ol ol li:first-child { counter-reset:section; }
    div.sidebar ol ol li:before {
      content:counter(chapter) '.' counter(section) '. ';
      counter-increment:section;
    }

    div.index > div.manuals { float:left; width:50%; }
    div.index > div.manuals > h2 { margin-top:0; }
    div.index > div.manuals table { border:none; }
    div.index > div.manuals table tr { background:none; border:none; }
    div.index > div.manuals table td { padding:0.5em 1em; }
    div.index > div.manuals table td:last-child { padding-right:2em; }
    div.index > div.manuals table td:first-child { vertical-align:top; }
    div.index div.apis { padding-left:1em; }

    div.pod-doc {
      border-top:1px solid #ccc;
      margin-top:2em;
    }

    div.type table { width:100%; }
    div.type table td:last-child { width:100%; }
    div.type h1 > span:first-child { display:block; font-size:60%; }
    div.type + div.sidebar > ul { list-style:none; }
    div.type > p > a.src { display:none; margin-left:0; }

    div.toc ol li { margin-bottom:1em; }
    div.toc ol li p { margin:1px 0 1px 1em; }
    div.toc ol li p:last-child { font-size:12px; }

    ul.chapter-nav { list-style:none; margin:1em 0; padding:0; position:relative; }
    ul.chapter-nav li { display:block; color:#999; }
    ul.chapter-nav li.next { text-align:right; }
    ul.chapter-nav li + li.next { position:absolute; top:0; right:0; }
    ul.chapter-nav li.prev:before { content:'\\00ab '; }
    ul.chapter-nav li.next:after { content:' \\00bb'; margin:0 }

    div.src pre { margin:1em 0; padding:0; color:#000; }
    div.src pre b { color:#f00; font-weight:normal; }
    div.src pre i   { color:#00f; font-style:normal; }
    div.src pre em  { color:#077; font-style:normal; }
    div.src pre q   { color:#070; font-style:normal; }
    div.src pre q:before, div.src pre q:after { content: ''; }
    "
  }
}