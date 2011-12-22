#! /usr/bin/env fan
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 11  Andy Frank    Creation
//   22 Dec 11  Brian Frank   Refactor for new compilerDoc design
//

using compilerDoc
using compilerDoc::Main as DocMain
using syntax
using util
using web

**
** Main
**
class Main : AbstractMain
{

  @Opt { help = "Output dir for doc files" }
  File outDir := Env.cur.workDir + `doc/`

  override Int run()
  {
    env := FantomDocEnv()

    // delegate to compilerDoc Main
    main := DocMain()
    main.env     = env
    main.outDir  = this.outDir
    main.clean   = true
    main.allCore = true
    main.run

    // override top index and css
    main.writeTopIndex(env, DocTopIndex { it.spaces = main.spaces; it.renderer = FantomTopIndexRenderer# })
    outDir.plus(`style.css`).out.printLine(FantomCss.css).close

    // generate examples
    main.writeSpace(env, env.examples)
    return 0
  }
}

**************************************************************************
** FantomDocEnv
**************************************************************************

const class FantomDocEnv : DefaultDocEnv
{
  const DocExamples examples := DocExamples()
  override DocTheme theme() { FantomDocTheme() }
  override const DocTopIndex topIndex := DocTopIndex { renderer = FantomTopIndexRenderer# }
  Version version() { ((DocPod)space("sys")).version }
  const DateTime timestamp := DateTime.now.floor(1min)
  override DocSpace? space(Str name, Bool checked := true)
  {
    if (name == examples.spaceName) return examples
    return super.space(name, checked)
  }
}

**************************************************************************
** DocExamples
**************************************************************************

const class DocExamples : DocSpace
{
  new make(File srcDir := Env.cur.homeDir + `examples/`)
  {
    docs := Str:Doc[:]
    docs["index"] = index
    sections := Str:DocExample[][:] { ordered = true }
    curSection  := ""
    index := (Obj[])(srcDir + `index.fog`).readObj
    index.each |item|
    {
      if (item is Str) curSection = item
      else
      {
        // create doc
        uri := ((List)item).first as Uri
        summary := ((List)item)[1] as Str
        docName := uri.path[0] + "-" + uri.basename
        file := srcDir + uri
        ex := DocExample(this, docName, summary, file)

        // map by doc name
        docs[docName] = ex

        // keep track of sections
        sectionList := sections[curSection] ?: DocExample[,]
        sectionList.add(ex)
        sections[curSection] = sectionList
      }
    }
    this.docs = docs
    this.sections = sections
  }

  override Str spaceName() { "examples" }

  override Doc? doc(Str docName, Bool checked := true)
  {
    doc := docs[docName]
    if (doc != null) return doc
    echo("ERROR: broken example link: $docName")
    if (checked) throw UnknownDocErr("examples::$docName")
    return null
  }

  override Void eachDoc(|Doc| f) { docs.each(f) }

  const DocExampleIndex index := DocExampleIndex(this)
  const Str:Doc docs
  const Str:DocExample[] sections
}

**************************************************************************
** DocExampleIndex
**************************************************************************

const class DocExampleIndex : Doc
{
  new make(DocExamples space) { this.space = space }
  override const DocExamples space
  override Str docName() { "index" }
  override Str title() { "Examples" }
  override Type renderer() { DocExampleIndexRenderer# }
}

class DocExampleIndexRenderer : DocRenderer
{
  new make(DocEnv e, WebOutStream o, Doc d) : super(e, o, d) {}
  override Void writeContent()
  {
    space := ((DocExampleIndex)this.doc).space
    out.div("class='ex-index'")
    curSection := "???"
    space.sections.each |list, name|
    {
      out.h2("id='$name'").esc(name).h2End
      out.table
      list.each |ex|
      {
        out.tr
        out.td; writeLinkTo(ex, ex.file.basename); out.tdEnd
        out.td.esc(ex.summary).tdEnd
        out.trEnd
      }
      out.tableEnd
    }
    out.divEnd
  }
}

**************************************************************************
** DocExample
**************************************************************************

const class DocExample : Doc
{
  new make(DocExamples space, Str docName, Str summary, File file)
  {
    this.space   = space
    this.docName = docName
    this.summary = summary
    this.file    = file
  }
  override const DocExamples space
  override const Str docName
  override Str breadcrumb() { docName + "." + file.ext }
  const Str summary
  const File file
  override Str title() { file.name }
  override Type renderer() { DocExampleRenderer# }
}

class DocExampleRenderer : DocRenderer
{
  new make(DocEnv e, WebOutStream o, Doc d) : super(e, o, d) {}
  override Void writeContent()
  {
    example := (DocExample)this.doc
    rules := SyntaxRules.loadForExt(example.file.ext ?: "?") ?: SyntaxRules()
    syntaxDoc := SyntaxDoc.parse(rules, example.file.in)
    out.div("class='src'")
    HtmlSyntaxWriter(out).writeLines(syntaxDoc)
    out.divEnd
  }
}

**************************************************************************
** FantomDocTheme
**************************************************************************

const class FantomDocTheme : DocTheme
{
  override Void writeStart(DocRenderer r)
  {
    out := r.out
    resPath := r.doc.isTopIndex ? "" : "../"
    // start HTML doc
    out.docType
    out.html
    out.head
      .title.esc(r.doc.title).titleEnd
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

  }

  override Void writeBreadcrumb(DocRenderer r)
  {
    out := r.out

    // subheader breadcrumb
    out.div("class='subHeader'")
    out.div
    super.writeBreadcrumb(r)
    out.divEnd
    out.divEnd

    // content
    out.div("class='content'")
    out.div
  }

  override Void writeEnd(DocRenderer r)
  {
    env := (FantomDocEnv)r.env
    out := r.out
    out.divEnd.divEnd // content
    out.div("class='footer'")
     .w("$env.version").span.w(" &#x2219; ").spanEnd.w(env.timestamp.toLocale)
     .divEnd
    out.bodyEnd
    out.htmlEnd
  }
}

**************************************************************************
** FantomTopIndexRenderer
**************************************************************************

class FantomTopIndexRenderer : DocTopIndexRenderer
{
  new make(DocEnv env, WebOutStream out, Doc doc) : super(env, out, doc) {}
  override Void writeContent()
  {
    out.div("class='index'")

    // manuals
    out.div("class='float'")
    out.div("class='manuals'")
    out.h2.w("Manuals").h2End
    writeManuals(index.pods.findAll |p| { p.isManual })
    out.divEnd

    // examples
    out.div("class='examples'")
    out.h2.w("Examples").h2End
    out.table
    examples := ((FantomDocEnv)env).examples
    examples.sections.each |list, name|
    {
      out.tr
      out.td; writeLinkTo(examples.index, name, name); out.tdEnd
      out.td.div
      list.each |ex, i|
      {
        if (i > 0) out.w(", ")
        writeLinkTo(ex, ex.file.basename)
      }
      out.divEnd.tdEnd
      out.trEnd
    }
    out.tableEnd
    out.divEnd
    out.divEnd

    // apis
    out.div("class='apis'")
    out.h2.w("APIs").h2End
    writeApis(index.pods.findAll |p| { !p.isManual })
    out.divEnd

    // end
    out.divEnd
  }
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