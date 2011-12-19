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
  }

  ** Output dir to write files.
  const File outDir := Env.cur.workDir + `doc/`

  ** DocEnv for this writer.
  DocEnv env

  ** Pods to render. Defaults to all pods.
  DocPod[] pods

  ** Write top index and resource files.
  Bool index := true

  ** Return a new PageRenderer.
  virtual PageRenderer makePageRenderer(WebOutStream out)
  {
    PageRenderer(env, out)
  }

  ** Write pods and return any errors.
  virtual DocErr[] write()
  {
    if (index)
    {
      writeCss(outDir + `style.css`)
      writeTopIndex(outDir + `index.html`)
    }

    // pods
    pods.each |pod|
    {
      if (pods.size > 1) echo("Writing pod '$pod.name' ...")
      podDir := outDir + `${pod.name}/`

      if (!pod.isManual)
      {
        // pod index
        writePodIndex(podDir + `index.html`, pod)

        // types
        pod.types.each |type|
        {
          writeType(podDir + `${type.name}.html`, type)
        }

        // source files
        if (!pod.sources.isEmpty)
        {
          zip := Zip.open(pod.file)
          try
          {
            pod.sources.each |src|
            {
              rules := SyntaxRules.loadForExt(src.ext ?: "?") ?:SyntaxRules()
              doc   := SyntaxDoc.parse(rules, zip.contents[src].in)
              writeSource(podDir + `src-${src.name}.html`, pod, src, doc)
            }
          }
          finally zip.close
        }
      }
      else
      {
        // manual index
        writeManualIndex(podDir + `index.html`, pod)

        // chapters
        pod.chapters.each |chapter|
        {
          writeChapter(podDir + `${chapter.name}.html`, chapter)
        }

        // resources
        if (!pod.resources.isEmpty)
        {
          zip := Zip.open(pod.file)
          try
          {
            pod.resources.each |res|
            {
              buf := zip.contents[res].in.readAllBuf
              podDir.plus(res.name.toUri).out.writeBuf(buf).flush
            }
          }
          finally zip.close
        }
      }
    }

    // return errs
    return env.errHandler.errs
  }

  ** Write CSS file.
  virtual Void writeCss(File file)
  {
    css := typeof.pod.file(`/res/style.css`).readAllStr
    file.out.printLine(css).close
  }

  ** Write top level docs index.  Default organization is
  ** to group everything into manuals or APIs
  virtual Void writeTopIndex(File file)
  {
    // organize pods into manuals and apis
    manuals := DocPod[,]
    apis    := DocPod[,]
    pods.each |p|
    {
      if (p.isManual) manuals.add(p)
      else apis.add(p)
    }
    manuals.moveTo(manuals.find |p| { p.name == "docIntro" }, 0)
    manuals.moveTo(manuals.find |p| { p.name == "docLang" }, 1)

    // doc start
    out := WebOutStream(file.out)
    pr := makePageRenderer(out)
    pr.writeStart
    out.div("class='index'")

    // manual table
    out.div("class='manuals'")
    out.h2.w("Manuals").h2End
    writeTopIndexManuals(out, manuals)
    out.divEnd

    // api table
    out.div("class='apis'")
    out.h2.w("APIs").h2End
    writeTopIndexApis(out, apis)
    out.divEnd

    // doc end
    out.divEnd
    pr.writeEnd
    out.close
  }

  ** Write API table for a top-level index.
  Void writeTopIndexApis(WebOutStream out, DocPod[] pods)
  {
    out.table
    pods.each |pod|
    {
      out.tr
        .td.a(`${pod.name}/index.html`).w(pod.name).aEnd.tdEnd
        .td.w(pod.summary).tdEnd
        .trEnd
    }
    out.tableEnd
  }

  ** Write a table of manual pods for a top-level index
  Void writeTopIndexManuals(WebOutStream out, DocPod[] manuals)
  {
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
  }

  ** Write pod index.
  virtual Void writePodIndex(File file, DocPod pod)
  {
    out := WebOutStream(file.out)
    makePageRenderer(out) { it.pod = pod }.writePodIndex
    out.close
  }

  ** Write type index.
  virtual Void writeType(File file, DocType type)
  {
    out := WebOutStream(file.out)
    makePageRenderer(out) { it.type = type }.writeType
    out.close
  }

  ** Write manual index.
  virtual Void writeManualIndex(File file, DocPod pod)
  {
    out := WebOutStream(file.out)
    makePageRenderer(out) { it.pod = pod }.writeManualIndex
    out.close
  }

  ** Write manual chapter.
  virtual Void writeChapter(File file, DocChapter chapter)
  {
    out := WebOutStream(file.out)
    makePageRenderer(out) { it.chapter = chapter }.writeChapter
    out.close
  }

  ** Write source file.
  virtual Void writeSource(File file, DocPod pod, Uri uri, SyntaxDoc doc)
  {
    out := WebOutStream(file.out)
    makePageRenderer(out)
    {
      it.pod = pod
      it.sourceUri = uri
      it.sourceDoc = doc
    }.writeSource
    out.close
  }
}