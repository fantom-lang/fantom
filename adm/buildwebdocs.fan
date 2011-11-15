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

    // load example index
    exampleSrcDir := Env.cur.homeDir + `examples/`
    exampleUris   := Str:Uri[:]
    exampleIndex  := loadExampleIndex(exampleSrcDir, exampleUris)

    // create customized env instance
    env := FantomDocEnv(exampleUris)

    // figure out which pods to render
    DocPod[] docPods := all ? env.pods : pods.map |n->DocPod| { env.pod(n) }

    // render pods
    docWriter := FantomDocWriter
    {
      it.env           = env
      it.pods          = docPods
      it.index         = all || topindex
      it.outDir        = this.outDir
      it.version       = env.pod("sys").version
      it.exampleSrcDir = exampleSrcDir
      it.exampleIndex  = exampleIndex
    }
    return docWriter.write.isEmpty ? 0 : 1
  }

  static Str:Obj loadExampleIndex(File srcDir, Str:Uri uris)
  {
    uris["index"] = `../examples/index.html`
    map   := Str:Obj[][:] { ordered=true }
    last  := ""
    index := (Obj[])(srcDir + `index.fog`).readObj
    index.each |item|
    {
      if (item is Str) last = item
      else
      {
        uri := ((List)item).first as Uri
        key := uri.path[0] + "-" + uri.basename
        uris[key] = `../examples/${key}.html`

        list := map[last] ?: Obj[,]
        list.add(item)
        map[last] = list
      }
    }
    return map.ro
  }

}

**************************************************************************
** FantomDocLinker
**************************************************************************

internal class FantomDocEnv : DocEnv
{
  new make(Str:Uri exampleUris)
  {
    this.exampleUris = exampleUris
    this.linker = FantomDocLinker#
  }

  Str:Uri exampleUris
}

**************************************************************************
** FantomDocLinker
**************************************************************************

** Add support for examples
internal class FantomDocLinker : DocLinker
{
  new make(|This| f) : super(f) {}

  override DocLink? resolve()
  {
    if (podPart == "examples") return resolveExamples
    return super.resolve
  }

  private DocLink? resolveExamples()
  {
    exampleUris := ((FantomDocEnv)env).exampleUris
    uri := exampleUris[namePart]
    if (uri == null) throw err("Unknown example file: $namePart")
    return DocLink(uri, namePart)
  }
}

**************************************************************************
** FantomDocWriter
**************************************************************************

class FantomDocWriter : FileDocWriter
{
  ** Constructor.
  new make(|This| f) : super(f) {}

  ** Build version
  Version version

  Str timestamp := DateTime.now.toLocale

  ** Example source dir.
  File exampleSrcDir

  ** Example index.fog
  Str:Obj[] exampleIndex

  ** Include example if index flag is specified
  override DocErr[] write()
  {
    super.write
    if (index) writeExamples
    return env.errHandler.errs
  }

  ** Return customized PageRenderer
  override PageRenderer makePageRenderer(WebOutStream out)
  {
    FantomPageRenderer(this, env, out)
  }

  ** Customize CSS
  override Void writeCss(File file)
  {
    file.out.printLine(FantomCss.css).close
  }

//////////////////////////////////////////////////////////////////////////
// Examples
//////////////////////////////////////////////////////////////////////////

  private Void writeExamples()
  {
    // write example index
    dir := outDir + `examples/`
    writeExampleIndex(dir + `index.html`)

    // write example source code
    exampleIndex.each |list|
    {
      list.each |item|
      {
        uri := item->get(0) as Uri

        // parse source file as SyntaxDoc
        srcFile := exampleSrcDir.plus(uri)
        if (!srcFile.exists) throw IOErr("example file not found: $srcFile")
        rules := SyntaxRules.loadForExt(srcFile.ext ?: "?") ?:SyntaxRules()
        doc   := SyntaxDoc.parse(rules, srcFile.in)

        // write HTML file
        file := dir + exampleUriToFilename(uri).toUri
        writeExampleFile(file, uri, doc)
      }
    }
  }

  ** Write example index.
  Void writeExampleIndex(File file)
  {
    out := WebOutStream(file.out)
    r := FantomPageRenderer(this, env, out) { exampleUri=`index.html` }

    r.writeStart
    out.div("class='ex-index'")
    exampleIndex.each |list, name|
    {
      out.h2("id='$name'").esc(name).h2End
      out.table
      list.each |item|
      {
        uri := item->get(0) as Uri
        summary := item->get(1) as Str
        link := uri.path[0] + "-" + uri.basename + ".html"
        out.tr
          .td.a(exampleUriToFilename(uri).toUri).esc(uri.basename).aEnd.tdEnd
          .td.esc(summary).tdEnd
          .trEnd
      }
      out.tableEnd
    }
    out.divEnd
    r.writeEnd
    out.close
  }

  ** Write example source file.
  Void writeExampleFile(File file, Uri uri, SyntaxDoc doc)
  {
    out := WebOutStream(file.out)
    FantomPageRenderer(this, env, out)
    {
      exampleUri = uri
      exampleDoc = doc
    }.writeExample
    out.close
  }

  ** Return URI for example.
  Str exampleUriToFilename(Uri uri)
  {
    uri.path[0] + "-" + uri.basename + ".html"
  }
}

**************************************************************************
** FantomPageRenderer
**************************************************************************

class FantomPageRenderer : PageRenderer
{
  new make(FantomDocWriter parent, DocEnv env, WebOutStream out) : super(env, out)
  {
    this.parent = parent
  }

  ** Example URI.
  Uri? exampleUri

  ** Example source file
  SyntaxDoc? exampleDoc

  override Str title()
  {
    if (exampleDoc != null) return exampleUri.name
    if (exampleUri != null) return "Examples"
    return super.title
  }

  override Str resPath()
  {
    if (exampleUri != null) return "../"
    return super.resPath
  }

  override Void writeStart()
  {
    // start HTML doc
    out.docType
    out.html
    out.head
      .title.esc(title).titleEnd
      .printLine("<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>")
      .includeJs(`${resPath}../docres/doc.js`)
      .includeCss(`${resPath}style.css`)
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
    if (exampleUri == null) writeBreadcrumb
    else
    {
      out.div("class='breadcrumb'")
        .ul
          .li.a(`../index.html`).w("Doc Index").aEnd.w("</li>")
          .li.a(`index.html`).w("Examples").aEnd.w("</li>")
          if (exampleDoc != null)
            out.li.a(exampleUri.name.toUri).w(exampleUri.name).aEnd.w("</li>")
          out.ulEnd
        .divEnd
    }
    out.divEnd
    out.divEnd

    // content
    out.div("class='content'")
    out.div
  }

  override Void writeEnd()
  {
    out.divEnd.divEnd // content
    out.div("class='footer'")
     .w("$parent.version $parent.timestamp")
     .divEnd
    out.bodyEnd
    out.htmlEnd
  }

  override Void writeIndex()
  {
    // start
    writeStart
    out.div("class='index'")

    // manuals
    out.div("class='float'")
    out.div("class='manuals'")
    IndexRenderer(env, out).writeManuals
    out.divEnd

    // examples
    out.div("class='examples'")
    out.h2.w("Examples").h2End
    out.table
    parent.exampleIndex.each |list,name|
    {
      names := list.join(", ") |v|
      {
        uri  := (Uri)v->first
        file := parent.exampleUriToFilename(uri)
        return "<a href='examples/$file'>$uri.basename</a>"
      }
      out.tr
        .td.a(`examples/index.html#$name`).esc(name).aEnd.tdEnd
        .td.div.w(names).divEnd.tdEnd
        .trEnd
    }
    out.tableEnd
    out.divEnd
    out.divEnd

    // apis
    out.div("class='apis'")
    IndexRenderer(env, out).writeApis
    out.divEnd

    // end
    out.divEnd
    writeEnd
  }


  Void writeExample()
  {
    writeStart
    out.div("class='src'")
    HtmlSyntaxWriter(out).writeLines(exampleDoc)
    out.divEnd
    writeEnd
  }

  private FantomDocWriter parent
}

**************************************************************************
** CSS
**************************************************************************

class FantomCss
{
  static const Str css :=
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
    p.sig code a { color:#080; }
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
    table td div { font-size:9pt; }

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

    div.mainSidebar { padding-right:220px; font-size:11pt; position:relative; }
    div.mainSidebar table,
    div.mainSidebar div.sidebar { font-size:10pt; }
    div.mainSidebar + div.mainSidebar {
      border-top: 1px solid #ccc;
      margin-top: 2em;
    }
    div.chapter + div.sidebar { margin-top:2em; }

    div.sidebar { position:absolute; right:0; top:0; width:200px; }
    div.sidebar > p { font-weight:bold; }
    div.sidebar > p:first-child { margin-top:3em; }
    div.sidebar ul { margin: 0 0 0 1.5em; padding: 0; line-height:1.3em; }
    div.sidebar ul ul { padding-left:1.2em; }
    div.sidebar li { margin: 3px 3px 3px 0; }
    div.sidebar > ol { padding:0 0 0 2em; margin:0; line-height:1.5em; color:#777; }
    div.sidebar > ol > li > ol { list-style:none; padding-left:0;counter-reset:section; }
    div.sidebar > ol > li > ol li:before {
      content:counter(chapter) '.' counter(section) '. ';
      counter-increment:section;
    }
    div.sidebar ol ol ol { list-style:none; padding-left:1em; }
    div.sidebar ol ol ol li:first-child { counter-increment: heading; }
    div.sidebar ol ol ol li:before {
      content: counter(chapter) '.' counter(section) '.' counter(heading) '. ';
      counter-increment: heading;
    }
    div.pod-doc + div.sidebar { margin-top:1em; }
    div.chapter + div.sidebar h3 { counter-reset: part; margin-bottom:1.75em; }
    div.chapter + div.sidebar h4:before {
      color:#777;
      content: counter(part, upper-roman) '. ';
      counter-increment: part;
    }
    div.chapter + div.sidebar h3 a {
      color:#4e4d3a;
      background:#f7f7ed;
      padding:10px 12px;
      border:1px solid #dfe0cd;
      -webket-border-radius:5px;
      -moz-border-radius:5px;
      border-radius:5px;
      font-size:10pt;
    }

    dl { margin:2em 0 1em 0; }
    dl dt {
      border-top:1px solid #d0dae5;
      background:#f2f6f8;
      font-weight:bold;
      padding:5px;
    }
    dl dd { position:relative; margin:1em 0 2em 2em; }
    dl dd p.src a {
      position:absolute;
      top:-36px; right:5px;
      font-size:8pt; color:#7aa3c0;
    }

    div.type { width:630px; }
    div.type table { width:100%; }
    div.type table td:last-child { width:100%; }
    div.type h1 > span:first-child { display:block; font-size:60%; }
    div.type > p.src { display:none; }
    div.type + div.sidebar > ul { list-style:none; }

    div.toc { counter-reset: part; }
    div.toc h2:before {
      content: counter(part, upper-roman) '. ';
      counter-increment: part;
    }
    div.toc ol li { margin-bottom:1em; }
    div.toc ol li p { margin:1px 0 1px 1em; }
    div.toc ol li p:last-child { font-size:9pt; }

    ul.chapter-nav { list-style:none; margin:1em 0; padding:0; position:relative; font-size:10pt; }
    ul.chapter-nav li { display:block; color:#999; }
    ul.chapter-nav li.next { text-align:right; }
    ul.chapter-nav li + li.next { position:absolute; top:0; right:0; }
    ul.chapter-nav li.prev:before { content:'\\00ab '; }
    ul.chapter-nav li.next:after { content:' \\00bb'; margin:0 }

    div.index > div.float { float:left; width:48%; padding-right:2em; }
    div.index div.manuals > h2 { margin-top:0; }
    div.index div.manuals table td { padding:0.5em 1em; }
    div.index div.manuals table td:last-child { padding-right:2em; }
    div.index div.manuals table td:first-child { vertical-align:top; padding-left:5px; }
    div.index div.examples table { margin-right:2em; }
    div.index div.apis { padding-left:1em; }

    div.ex-index table { width:630px; }
    div.ex-index table td:first-child { padding-right:2em; }
    div.ex-index table td:last-child { width:100%; }

    div.src pre { margin:1em 0; padding:0; color:#000; border:none; background:none; }
    div.src pre b { color:#f00; font-weight:normal; }
    div.src pre i   { color:#00f; font-style:normal; }
    div.src pre em  { color:#077; font-style:normal; }
    div.src pre q   { color:#070; font-style:normal; }
    div.src pre q:before, div.src pre q:after { content: ''; }

    /*************************************************************************
     * Footer
     ************************************************************************/

    div.footer
    {
      width: 850px;
      margin: 3em auto 1em auto;
      font-size: 8pt;
      color: #999;
    }
    "
}