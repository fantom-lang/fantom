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
    if (index)
    {
      writeCss(outDir + `style.css`)
      writeIndex(outDir + `index.html`)
    }

    // pods
    pods.each |pod|
    {
      echo("Writing pod '$pod.name' ...")
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
          zip := pod.open
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

  ** Write CSS file.
  virtual Void writeCss(File file)
  {
    css := typeof.pod.file(`/res/style.css`).readAllStr
    file.out.printLine(css).close
  }

  ** Write docs index.
  virtual Void writeIndex(File file)
  {
    out := WebOutStream(file.out)
    PageRenderer(env, out).writeIndex
    out.close
  }

  ** Write pod index.
  virtual Void writePodIndex(File file, DocPod pod)
  {
    out := WebOutStream(file.out)
    PageRenderer(env, out) { it.pod = pod }.writePodIndex
    out.close
  }

  ** Write type index.
  virtual Void writeType(File file, DocType type)
  {
    out := WebOutStream(file.out)
    PageRenderer(env, out) { it.type = type }.writeType
    out.close
  }

  ** Write manual index.
  virtual Void writeManualIndex(File file, DocPod pod)
  {
    out := WebOutStream(file.out)
    PageRenderer(env, out) { it.pod = pod }.writeManualIndex
    out.close
  }

  ** Write manual chapter.
  virtual Void writeChapter(File file, DocChapter chapter)
  {
    out := WebOutStream(file.out)
    PageRenderer(env, out) { it.chapter = chapter }.writeChapter
    out.close
  }

  ** Write source file.
  virtual Void writeSource(File file, DocPod pod, Uri uri, SyntaxDoc doc)
  {
    out := WebOutStream(file.out)
    PageRenderer(env, out)
    {
      it.pod = pod
      it.sourceUri = uri
      it.sourceDoc = doc
    }.writeSource
    out.close
  }
}