#! /usr/bin/env fan
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 11  Andy Frank  Creation
//

using compilerDoc
using syntax
using util
using web

**
** Main
**
class Main : AbstractMain
{

  @Opt { help = "Generate top index" }
  Bool topindex

  @Opt { help = "Generate everything (topindex and all pods)" }
  Bool all

  @Arg { help = "Name of pods to compile" }
  Str[] pods := [,]

  @Opt { help = "Output dir for doc files" }
  File outDir := Env.cur.workDir + `doc/`

  override Int run()
  {
    // must generate topindex or at least one pod
    if (!topindex && !all && pods.isEmpty) { usage; return 1 }

    // create default DocEnv instance
    env := DocEnv()

    // figure out which pods to render
    DocPod[] docPods := all ? env.pods : pods.map |n->DocPod| { env.pod(n) }

    // render pods
    docWriter := FantomDocWriter
    {
      it.env    = env
      it.pods   = docPods
      it.index  = all || topindex
      it.outDir = this.outDir
    }
    return docWriter.write.isEmpty ? 0 : 1
  }
}

**
** FantomDocWriter
**
class FantomDocWriter : FileDocWriter
{
  ** Constructor.
  new make(|This| f) : super(f) {}

  ** Include example if index flag is specified
  override DocErr[] write()
  {
    super.write
    if (index) writeExamples
    return env.errHandler.errs
  }

  ** Start a HTML page.
  override Void writeStart(WebOutStream out, Str title, Obj? obj)
  {
    // path to resource files
    path := obj == null ? "" : "../"

    // start HTML doc
    out.docType
    out.html
    out.head
      .title.esc(title).titleEnd
      .printLine("<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>")
      .includeJs(`${path}../docres/doc.js`)
      .includeCss(`${path}style.css`)
      .w("<!--[if lte IE 7]>
          <style type='text/css'>
            div.header li { display:inline; }
            div.subHeader li { display:inline; }
          </style>
          <![endif]-->")
      .headEnd
    out.body("onload='Login.check();'")

    // header
    out.div("class='header'")
     .div
     .a(`/`).w("Fantom").aEnd
     .p("id='sidewalkLogin_'").w("&nbsp;").pEnd
     .form("method='get' action='/sidewalk/search'")
       .p.textField("name='q' size='30' placeholder='Search...'").pEnd
       .formEnd
     .ul
       .li.a(`/`).w("Home").aEnd.w("</li>")
       .li("class='active'").a(`index.html`).w("Docs").aEnd.w("</li>")
       .li.a(`/sidewalk/blog/`).w("Blog").aEnd.w("</li>")
       .li.a(`/sidewalk/ticket/`).w("Tickets").aEnd.w("</li>")
       .li.a(`/sidewalk/topic/`).w("Discuss").aEnd.w("</li>")
       .ulEnd
     .divEnd
     .divEnd

    // subheader
    out.div("class='subHeader'")
    out.div
    switch (obj?.typeof)
    {
      case DocPod#:
          out.ul
            .li.a(`../index.html`).w("Doc Home").aEnd.w("</li>")
            .li.a(`index.html`).w(obj->name).aEnd.w("</li>")
            .ulEnd

      case DocType#:
      case DocChapter#:
          out.ul
            .li.a(`../index.html`).w("Doc Home").aEnd.w("</li>")
            .li.a(`index.html`).w(obj->pod).aEnd.w("</li>")
            .li.a(`${obj->name}.html`).w(obj->name).aEnd.w("</li>")
            .ulEnd

      case Str[]#:
          list := (Str[])obj
          out.ul("class='nav'")
            .li.a(`../index.html`).w("Home").aEnd.liEnd
            .li.a(`index.html`).w(list[0]).aEnd.liEnd
            .li.a(`${list[1]}.html`).w(list[1]).aEnd.liEnd
            .li.a(`src-${list[2]}.html`).w("Source").aEnd.liEnd
            .ulEnd

       default:
          out.ul
            .li.a(`../index.html`).w("Doc Home").aEnd.w("</li>")
            .ulEnd
    }
    out.divEnd
    out.divEnd

    // content
    out.div("class='content'")
    out.div
  }

  ** End a HTML page.
  override Void writeEnd(WebOutStream out)
  {
    out.divEnd.divEnd // content
    out.bodyEnd
    out.htmlEnd
  }

//////////////////////////////////////////////////////////////////////////
// Index
//////////////////////////////////////////////////////////////////////////

  ** Write top index.
  override Void writeIndex(WebOutStream out)
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
    out.div("class='float'")
    out.div("class='manuals'")
    out.h2.w("Manuals").h2End
    out.table
    ["docIntro", "docLang", "docTools", "docFanr"].each |name|
    {
      pod := manuals.find |m| { m.name == name }
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

    // examples
    out.div("class='examples'")
    out.h2.w("Examples").h2End
    //out.table
    //out.tableEnd
    out.divEnd
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
// Examples
//////////////////////////////////////////////////////////////////////////

  private Void writeExamples()
  {
    // load toc
    srcDir := Env.cur.homeDir + `examples/`
    index := (srcDir + `index.fog`).readObj as Obj[]

    // write example index
    dir := outDir + `examples/`
    out := WebOutStream(dir.plus(`index.html`).out)
    writeExampleIndex(out, index)
    out.close

    // write example source code
    index.each |item|
    {
      // only iterating [Uri,Str] pairs
      if (item isnot List) return
      uri := item->get(0) as Uri

      // parse source file as SyntaxDoc
      srcFile := srcDir.plus(uri)
      if (!srcFile.exists) throw IOErr("example file not found: $srcFile")
      rules := SyntaxRules.loadForExt(srcFile.ext ?: "?") ?:SyntaxRules()
      syntaxDoc := SyntaxDoc.parse(rules, srcFile.in)

      // write HTML file
      filename := exampleUriToFilename(uri)
      out = WebOutStream(dir.plus(filename.toUri).out)
      writeExampleFile(out, uri.name, syntaxDoc)
      out.close
    }
  }

  private Void writeExampleIndex(WebOutStream out, Obj[] items)
  {
    items.each |item|
    {
      if (item is Str) out.h2.w(item).h2End
      else
      {
        uri := item->get(0) as Uri
        summary := item->get(1) as Str
        link := uri.path[0] + "-" + uri.basename + ".html"
        out.p.a(exampleUriToFilename(uri).toUri).w(uri.basename).aEnd.w(" - ").w(summary).pEnd
      }
    }
  }

  private Void writeExampleFile(WebOutStream out, Str name, SyntaxDoc doc)
  {
    writeStart(out, name, ["examples", "TODO", "TODO"])
    out.div("class='src'")
    HtmlSyntaxWriter(out).writeLines(doc)
    out.divEnd
    writeEnd(out)
  }

  private static Str exampleUriToFilename(Uri uri)
  {
    uri.path[0] + "-" + uri.basename + ".html"
  }

//////////////////////////////////////////////////////////////////////////
// CSS
//////////////////////////////////////////////////////////////////////////

  override Str css()
  {
   "body {
      font:10pt Arial, sans-serif;
      margin:0 0 3em 0; padding: 0;
    }
    a { color:#185098; }
    input { font:10pt Arial, sans-serif; }
    code,pre,textarea { font:9pt Monaco, 'Courier New', monospace; }
    pre { overflow-y:hidden; overflow-x:auto; }
    blockquote {
      margin:1em 0;
      padding-left:1em;
      color:#a0a;
      border-left:1px solid #ccc;
    }

    code { color:#080; }
    code.sig a { color:#080; }
    pre {
      color:#333; background:#f7f7ed; border:1px solid #dfe0cd; padding:10px;
      -webkit-border-radius:5px; -moz-border-radius:5px; border-radius:5px;
    }

    h1 { color: #2f5381; }
    h2 { color: #ad4e00; }
    h3 { color: #25272a; }

    table { border-collapse:collapse; border-top:1px solid #d0dae5; }
    table tr { border-bottom:1px solid #d0dae5; }
    table tr:nth-child(odd) { background:#f2f6f8; }
    table td { padding:5px; }
    table td div { font-size:8pt; }

    /*************************************************************************
     * Header
     ************************************************************************/

    div.header {
      color:#fff;
      border-bottom:5px solid #2f5381;
      background:#14253c;
      background:-webkit-gradient(linear, 0 0, 0 100%, from(#14253c), to(#0a121e));
      background:-moz-linear-gradient(top, #14253c, #0a121e);
      background:linear-gradient(top, #14253c, #0a121e);
    }
    div.header > div {
      width:850px; height:41px; margin:0 auto;
      padding:10px 0 35px 0; position:relative;
    }
    div.header > div > a:first-child {
      background:url(../docres/fantom.png) no-repeat 0 0;
      float:left; width:161px; height:37px;
      margin-top:2px; overflow:hidden;
      text-indent:-9999px; outline-style:none;
    }
    div.header p {
      margin:0; padding:0; position:absolute;
      top:14px; right:0; color:#fff; font-size:8pt;
    }
    div.header p a { color:#fff; }
    div.header form { display:inline; }
    div.header form p { top:40px; }
    div.header ul {
      position:absolute; bottom:0; left:0;
      margin:0; padding:0; list-style:none;
      white-space:nowrap;
    }
    div.header li { margin:0 2px 0 0; padding:0; display:inline-block; font-size:11pt; }
    div.header li a {
      display:inline-block; padding:5px 12px 7px 12px;
      color:#fff; text-decoration:none; outline:none;
      border-top:2px solid #264368;
      background:#203858;
      background:-webkit-gradient(linear, 0 75%, 0 100%, from(#203858), to(#1b2f49));
      background:-moz-linear-gradient(top, #203858 75%, #1b2f49);
      background:linear-gradient(top, #203858 75%, #1b2f49);
    }
    div.header li a:hover { border-top:2px solid #345988; background:#27466f; }
    div.header li.active a { border-top:2px solid #4971a5; background:#2f5381; }

    /*************************************************************************
     * SubHeader
     ************************************************************************/

    div.subHeader
    {
      background:#d7d7c9;
      border-top:1px solid #1e3554;
      border-bottom:1px solid #bebea8;
      background:-webkit-gradient(linear, 0 0, 0 25%, from(#a4a490), to(#d7d7c9));
      background:-moz-linear-gradient(top, #a4a490, #d7d7c9 25%);
      background:linear-gradient(top, #a4a490, #d7d7c9 25%);
    }
    div.subHeader > div { width:850px; margin:0 auto; }
    div.subHeader ul { margin:0; padding:10px; list-style:none; white-space:nowrap; }
    div.subHeader li { display:inline-block; color:#9d9a7b; font:10pt 'Arial Narrow', Arial; }
    div.subHeader li a { color:#4e4d3a; font:10pt Arial; }
    div.subHeader li:after { margin:0 0.5em; content:'>'; }
    div.subHeader li:last-child:after { content:''; }

    /*************************************************************************
     * Content
     ************************************************************************/

    div.content > div { width:850px; margin:0 auto; position:relative; }

    div.article { padding-right:220px; font-size:11pt; position:relative; }
    div.article table,
    div.article div.sidebar { font-size:10pt; }

    div.pod-doc { border-top:1px solid #ccc; margin-top:2em; }
    div.pod-doc div.sidebar { margin-top:1em; }

    div.sidebar { position:absolute; right:0; top:0; width:200px; }
    div.sidebar > p { font-weight:bold; }
    div.sidebar > p:first-child { margin-top:3em; }
    div.sidebar ul { margin: 0 0 0 1.5em; padding: 0; line-height:1.3em; }
    div.sidebar ul ul { padding-left:1.2em; }
    div.sidebar li { margin: 3px 3px 3px 0; }
    div.sidebar > ol { padding:0 0 0 2em; margin:0; line-height:1.5em; color:#777; }
    div.sidebar ol ol { list-style:none; padding-left:0; }
    div.sidebar ol ol li:first-child { counter-reset:section; }
    div.sidebar ol ol li:before {
      content:counter(chapter) '.' counter(section) '. ';
      counter-increment:section;
    }

    dl { margin:2em 0 1em 0; }
    dl dt {
      border-top:1px solid #d0dae5;
      background:#f2f6f8;
      font-weight:bold;
      padding:5px;
    }
    dl dd { position:relative; margin:1em 0 2em 2em; }
    dl dd a.src {
      position:absolute;
      top:-36px; right:5px;
      font-size:8pt; color:#7aa3c0;
    }

    div.type { width:630px; }
    div.type table { width:100%; }
    div.type table td:last-child { width:100%; }
    div.type h1 > span:first-child { display:block; font-size:60%; }
    div.type > p > a.src { display:none; }
    div.type + div.sidebar > ul { list-style:none; }

    div.toc ol li { margin-bottom:1em; }
    div.toc ol li p { margin:1px 0 1px 1em; }
    div.toc ol li p:last-child { font-size:12px; }

    ul.chapter-nav { list-style:none; margin:1em 0; padding:0; position:relative; font-size:10pt; }
    ul.chapter-nav li { display:block; color:#999; }
    ul.chapter-nav li.next { text-align:right; }
    ul.chapter-nav li + li.next { position:absolute; top:0; right:0; }
    ul.chapter-nav li.prev:before { content:'\\00ab '; }
    ul.chapter-nav li.next:after { content:' \\00bb'; margin:0 }

    div.index > div.float { float:left; width:50%; }
    div.index div.manuals > h2 { margin-top:0; }
    div.index div.manuals table { border:none; }
    div.index div.manuals table tr { background:none; border:none; }
    div.index div.manuals table td { padding:0.5em 1em; }
    div.index div.manuals table td:last-child { padding-right:2em; }
    div.index div.manuals table td:first-child { vertical-align:top; }
    div.index div.apis { padding-left:1em; }

    div.src pre { margin:1em 0; padding:0; color:#000; border:none; background:none; }
    div.src pre b { color:#f00; font-weight:normal; }
    div.src pre i   { color:#00f; font-style:normal; }
    div.src pre em  { color:#077; font-style:normal; }
    div.src pre q   { color:#070; font-style:normal; }
    div.src pre q:before, div.src pre q:after { content: ''; }
    "
  }
}