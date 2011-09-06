//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Sep 2011  Andy Frank  Creation
//

using fandoc
using syntax
using web

**
** PageRenderer renders complete HTML pages for doc models.
**
** Breadcrumb
** ==========
**
**   <div class='breadcrumb'>
**     <ul>
**       <li><a>...</a></li>
**     </ul>
**   </div>
**
** Index
** =====
**
**   <div class='index'>
**     <div class='manuals'>
**       {IndexRenderer.writeManuals}
**     </div>
**     <div class='apis'>
**       {IndexRenderer.writeApis}
**     </div>
**   </div>
**
** Pod Index
** =========
**
**   <div class='mainSidebar'>
**     <div class='main type'>
**       {PodRenderer.writeIndex}
**     </div>
**     <div class='sidebar'>
**       <h3>All Types</h3>
**       <ul>
**         <li><a>{type.name}</a></li>
**       </ul>
**     </div>
**   </div>
**
**   <div class='mainSidebar'>
**     <div class='main pod-doc'>
**       {writeFandoc(podDoc)}
**     </div>
**     <div class='sidebar'>
**       <h3>Contents</h3>
**       {PodRenderer.writePodDocToc}
**     </div>
**   </div>
**
** Type
** ====
**
**   <div class='mainSidebar'>
**     <div class='main type'>
**       {TypeRenderer.writeType}
**     </div>
**     <div class='sidebar'>
**       {TypeRenderer.writeToc}
**     </div>
**   </div>
**
** Source
** ======
**
**   <div class='src'>
**    {SyntaxHtmlWriter.writeLines}
**   </div>
**
** Chapter
** =======
**
**   <div class='mainSidebar'>
**     <div class='main chapter'>
**       {ManualRenderer.writeChapterNav}
**       {ManualRenderer.writeChapter}
**       {ManualRenderer.writeChapterNav}
**     </div>
**     <div class='sidebar'>
**       {ManualRender.writeChapterToc}
**     </div>
**   </div>
**
class PageRenderer : DocRenderer
{
  ** Constructor with env, out params.
  new make(DocEnv env, WebOutStream out) : super(env, out)
  {
  }

  ** DocPod for `writePodIndex` and `writeManualIndex`.
  DocPod? pod

  ** DocType for `writeType`.
  DocType? type

  ** DocType for `writeChapter`.
  DocChapter? chapter

  ** Uri for `writeSource`
  Uri? sourceUri

  ** SyntaxDoc for `writeSource`
  SyntaxDoc? sourceDoc

//////////////////////////////////////////////////////////////////////////
// Page
//////////////////////////////////////////////////////////////////////////

  ** Begin the page.
  virtual Void writeStart()
  {
    // find title and resource path
    title   := ""
    resPath := "../"
    if (chapter != null) title = chapter.name
    else if (type != null) title = type.qname
    else if (sourceUri != null) title = sourceUri.name
    else if (pod != null) title = pod.name
    else { title="Doc Index"; resPath="" }

    // start document
    out.docType
    out.html
    out.head
      .title.esc(title).titleEnd
      .printLine("<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>")
      .includeCss(`${resPath}style.css`)
      .headEnd
    out.body
    writeBreadcrumb
  }

  ** Write breadcrumb for currrent configuration.
  virtual Void writeBreadcrumb()
  {
    out.div("class='breadcrumb'")
    if (chapter != null)
    {
      out.ul
        .li.a(`../index.html`).w("Doc Index").aEnd.w("</li>")
        .li.a(`index.html`).w(chapter.pod).aEnd.w("</li>")
        .li.a(`${chapter.name}.html`).w("${chapter.num}. $chapter.name").aEnd.w("</li>")
        .ulEnd
    }
    else if (type != null)
    {
      out.ul
        .li.a(`../index.html`).w("Doc Index").aEnd.w("</li>")
        .li.a(`index.html`).w(type.pod).aEnd.w("</li>")
        .li.a(`${type.name}.html`).w(type.name).aEnd.w("</li>")
        .ulEnd
    }
    else if (sourceUri != null)
    {
      types := pod.types.findAll { it.loc.file == sourceUri.name }
      multi := types.size > 1
      type  := sourceUri.basename
      out.ul
        .li.a(`../index.html`).w("Doc Index").aEnd.w("</li>")
        .li.a(`index.html`).w(pod.name).aEnd.w("</li>")
        .li.w(multi ? "Multiple" : "<a href='${type}.html'>$type</a>").w("</li>")
        .li.a(`$sourceUri.name`).w("Source").aEnd.w("</li>")
        .ulEnd
    }
    else if (pod != null)
    {
      out.ul
        .li.a(`../index.html`).w("Doc Index").aEnd.w("</li>")
        .li.a(`index.html`).w(pod.name).aEnd.w("</li>")
        .ulEnd
    }
    else
    {
      out.ul
        .li.a(`index.html`).w("Doc Index").aEnd.w("</li>")
        .ulEnd
    }
    out.divEnd
  }

  ** End the page.
  virtual Void writeEnd()
  {
    out.bodyEnd
    out.htmlEnd
  }

//////////////////////////////////////////////////////////////////////////
// Model Renderers
//////////////////////////////////////////////////////////////////////////

  ** Write docs index.
  virtual Void writeIndex()
  {
    // start
    writeStart
    out.div("class='index'")

    // manuals
    out.div("class='manuals'")
    IndexRenderer(env, out).writeManuals
    out.divEnd

    // apis
    out.div("class='apis'")
    IndexRenderer(env, out).writeApis
    out.divEnd

    // end
    out.divEnd
    writeEnd
  }

  **
  ** Write pod index.
  **
  ** Required fields: `pod`
  **
  virtual Void writePodIndex()
  {
    // start
    if (pod == null) throw ArgErr("pod not configured")
    writeStart

    // type table
    out.div("class='mainSidebar'")
    out.div("class='main type'")
    PodRenderer(env, out, pod).writeIndex
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
      // chapter
      out.div("class='mainSidebar'")
      out.div("class='main pod-doc' id='pod-doc'")
      writeFandoc(pod.podDoc, pod.podDoc.doc)
      out.divEnd

      // toc
      out.div("class='sidebar'")
      out.h3.w("Contents").h3End
      PodRenderer(env, out, pod).writePodDocToc
      out.divEnd
      out.divEnd
    }

    // end
    writeEnd
  }

  **
  ** Write Type index.
  **
  ** Required fields: `type`
  **
  virtual Void writeType()
  {
    if (type == null) throw ArgErr("type not configured")
    this.pod = env.pod(type.pod)
    renderer := TypeRenderer(env, out, type)

    // start
    writeStart

    // typedoc
    out.div("class='mainSidebar'")
    out.div("class='main type'")
    renderer.writeType
    out.divEnd

    // toc
    out.div("class='sidebar'")
    renderer.writeToc
    out.divEnd
    out.divEnd

    // end
    writeEnd
  }

  **
  ** Write source file.
  **
  ** Required fields: `pod`, `sourceUri`, `sourceDoc`
  **
  virtual Void writeSource()
  {
    if (pod == null) throw ArgErr("pod not configured")
    if (sourceUri == null) throw ArgErr("sourceUri not configured")
    if (sourceDoc == null) throw ArgErr("sourceDoc not configured")

    // write
    writeStart
    out.div("class='src'")
    HtmlSyntaxWriter(out).writeLines(sourceDoc)
    out.divEnd
    writeEnd
  }

  **
  ** Write Manual index.
  **
  ** Required fields: `pod`
  **
  virtual Void writeManualIndex()
  {
    if (pod == null) throw ArgErr("pod not configured")
    writeStart
    ManualRenderer(env, out, pod).writeIndex
    writeEnd
  }

  **
  ** Write a manual chapter.
  **
  ** Required fields: `chapter`
  **
  virtual Void writeChapter()
  {
    if (chapter == null) throw ArgErr("chapter not configured")
    this.pod = env.pod(chapter.pod)
    renderer := ManualRenderer(env, out, pod)

    // start
    writeStart

    // content
    out.div("class='mainSidebar'")
    out.div("class='main chapter'")
    renderer.writeChapterNav(chapter)
    renderer.writeChapter(chapter)
    renderer.writeChapterNav(chapter)
    out.divEnd

    // toc
    out.div("class='sidebar'")
    renderer.writeChapterToc(chapter)
    out.divEnd
    out.divEnd

    // end
    writeEnd
  }
}

