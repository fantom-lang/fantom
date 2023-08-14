//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 2020  Brian Frank  Creation
//

using concurrent

**
** FilePack is an in-memory cache of multiple text files to service
** static resources via HTTP.  It takes one or more text files and
** creates one compound file.  The result is stored in RAM using GZIP
** compression.  Or you can use the `pack` utility method to store
** the result to your own files/buffers.
**
** The `onGet` method is used to service GET requests for the bundle.
** The Content-Type header is set based on file extension of files bundled.
** It also implictly supports ETag/Last-Modified for 304 optimization.
**
** The core factory is the `makeFiles` constructor.  A suite of utility
** methods is provided for standard bundling of Fantom JavaScrit and CSS
** files.
**
const class FilePack : Weblet
{
//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Construct a bundle for the given list of text files
  static new makeFiles(File[] files)
  {
    // calculate buffer size to avoid resizes assuming 25% gzip compression
    totalSize := 0
    files.each |f| { totalSize += f.size ?: 0 }
    buf := Buf(totalSize/4)

    // derive mime type from file ext (assume they are all the same)
    mimeType := files[0].mimeType ?: throw Err("Ext to mimeType: $files.first")

    // write each file to the buffer
    out := Zip.gzipOutStream(buf.out)
    pack(files, out).close
    return make(buf, mimeType)
  }

  ** Private constructor
  private new make(Buf buf, MimeType mimeType)
  {
    buf = buf.trim.toImmutable
    this.buf      = buf
    this.etag     = buf.toDigest("SHA-1").toBase64Uri
    this.modified = DateTime.now
    this.mimeType = mimeType
  }

//////////////////////////////////////////////////////////////////////////
// Identity (NoDoc fields subject to change)
//////////////////////////////////////////////////////////////////////////

  ** Valid values are 'js' or 'es'
  @NoDoc static const AtomicRef mode := AtomicRef("js")
  static Bool isEs() { FilePack.mode.val == "es" }

  ** The in-memory file contents in GZIP encoding
  @NoDoc const Buf buf

  ** Entity tag provides a SHA-1 hash for the bundle contents
  @NoDoc const Str etag

  ** Modified time is when bundle was generated
  @NoDoc const DateTime modified

  ** Inferred mime type from file extensions
  @NoDoc const MimeType mimeType

//////////////////////////////////////////////////////////////////////////
// Weblet
//////////////////////////////////////////////////////////////////////////

  ** Service an HTTP GET request for this bundle file
  override Void onGet()
  {
    // only process GET requests
    if (res.isDone) return
    if (req.method != "GET") return res.sendErr(501)

    // set identity headers
    res.headers["ETag"] = etag
    res.headers["Last-Modified"] = modified.toHttpStr

    // check if we can return a 304 not modified
    if (FileWeblet.doCheckNotModified(req, res, etag, modified)) return

    // we only respond using gzip
    res.statusCode = 200
    res.headers["Content-Encoding"] = "gzip"
    res.headers["Content-Type"] = mimeType.toStr
    res.headers["Content-Length"] = buf.size.toStr
    res.out.writeBuf(buf).close
  }

//////////////////////////////////////////////////////////////////////////
// File Utils
//////////////////////////////////////////////////////////////////////////

  ** Pack multiple text files together and write to the given output
  ** stream.  A trailing newline is automatically added if the file is
  ** missing one.  Empty files are skipped.  The stream is not closed.
  ** Return the given out stream.
  static OutStream pack(File[] files, OutStream out)
  {
    files.each |f| { pipeToPack(f, out) }
    return out
  }

  ** Pack a file to the given outstream and ensure there is a trailing newline
  private static Void pipeToPack(File f, OutStream out)
  {
    chunkSize := f.size.min(4096)
    if (chunkSize == 0) return // skip empty files
    buf := Buf(chunkSize)
    in := f.in(chunkSize)
    try
    {
      lastIsNewline := false
      while (true)
      {
        n := in.readBuf(buf.clear, chunkSize)
        if (n == null) break
        if (n > 0) lastIsNewline = buf[-1] == '\n'
        out.writeBuf(buf.flip, buf.remaining)
      }
      if (!lastIsNewline) out.writeChar('\n')
    }
    finally { in.close }
  }

//////////////////////////////////////////////////////////////////////////
// JavaScript Utils
//////////////////////////////////////////////////////////////////////////

  ** Given a set of pods return a list of JavaScript files that
  ** form a complete Fantom application:
  **   - flatten the pods using `sys::Pod.flattenDepends`
  **   - order them by dependencies using `sys::Pod.orderByDepends`
  **   - insert `toEtcJsFiles` immediately after "sys.js"
  static File[] toAppJsFiles(Pod[] pods)
  {
    pods = Pod.flattenDepends(pods)
    pods = Pod.orderByDepends(pods)
    files := toPodJsFiles(pods)
    files.insertAll(1, toEtcJsFiles)
    if (FilePack.isEs) files.insert(0, toPodJsFile(Pod.find("sys"), "fan"))
    return files
  }

  ** Get the standard pod JavaScript file or null if no JS code.  The
  ** standard location used by the Fantom JS compiler is "/{pod-name}.js"
  static File? toPodJsFile(Pod pod, Str name := pod.name)
  {
    uri := (FilePack.isEs ? `/js/` : `/`).plus(`${name}.js`)
    return pod.file(uri, false)
  }

  ** Map a set of pods to "/{name}.js" JavaScript files.
  ** Ignore pods that are missing a JavaScript file.
  ** This method does *not* flatten/order the pods.
  static File[] toPodJsFiles(Pod[] pods)
  {
    acc := File[,]
    acc.capacity = pods.size
    pods.each |pod|
    {
      js := toPodJsFile(pod)
      if (js != null) acc.add(js)
    }
    return acc
  }

  ** Return the required sys etc files:
  **  - add `toMimeJsFile`
  **  - add `toUnitsJsFile`
  **  - add `toIndexPropsJsFile`
  static File[] toEtcJsFiles()
  {
    FilePack.isEs
      ? [toMimeJsFile, toUnitsJsFile]
      : [toMimeJsFile, toUnitsJsFile, toIndexPropsJsFile]
  }

  @NoDoc static Obj moduleSystem()
  {
    Type.find("compilerEs::CommonJs").make([Env.cur.tempDir.plus(`file_pack/`)])
  }

  private static File toJsFile(Str cname, Uri fname)
  {
    buf := Buf(4096)
    c := FilePack.isEs
      ? Type.find("compilerEs::${cname}").make([moduleSystem])
      : Type.find("compilerJs::${cname}").make
    c->write(buf.out)
    return buf.toFile(fname)
  }

  ** Compile the mime type database into a Javascript file "mime.js"
  static File toMimeJsFile() { toJsFile("JsExtToMime", `mime.js`) }

  ** Compile the unit database into a JavaScript file "unit.js"
  static File toUnitsJsFile() { toJsFile("JsUnitDatabase", `units.js`) }

  ** Compile the timezone database into a JavaScript file "tz.js"
  @Deprecated { msg="tz.js is now included by default in sys.js" }
  static File toTimezonesJsFile()
  {
    // return empty file
    Buf().toFile(`tz.js`)
  }

  ** Compile the indexed props database into a JavaScript file "index-props.js"
  static File toIndexPropsJsFile(Pod[] pods := Pod.list)
  {
    buf := Buf(10_000)
    c := Type.find("compilerJs::JsIndexedProps").make
    c->write(buf.out, pods)
    return buf.toFile(`index-props.js`)
  }

  ** Compile the locale props into a JavaScript file "{locale}.js"
  static File toLocaleJsFile(Locale locale, Pod[] pods := Pod.list)
  {
    buf := Buf(1024)
    m := Slot.findMethod("compilerJs::JsProps.writeProps")
    path := `locale/${locale.toStr}.props`
    pods.each |pod| { m.call(buf.out, pod, path, 1sec) }
    return buf.toFile(`${locale}.js`)
  }

  ** Compile a list of pod JavaScript files into a single unified source
  ** map file.  The list of files passed to this method should match
  ** exactly the list of files used to create the corresponding JavaScript
  ** FilePack.  If the file is the standard pod JS file, then we will include
  ** an offset version of "{pod}.js.map" generated by the JavaScript compiler.
  ** Otherwise if the file is another JavaScript file (such as units.js) then
  ** we just add the appropiate offset.
  **
  ** The 'sourceRoot' option may be passed in to replace "/dev/{podName}"
  ** as the root URI used to fetch source files from the server.
  static File toPodJsMapFile(File[] files, [Str:Obj]? options := null)
  {
    buf := Buf(4 * 1024 * 1024)
    m := Slot.findMethod("compilerJs::SourceMap.pack")
    m.call(files, buf.out, options)
    return buf.toFile(`js.map`)
  }

//////////////////////////////////////////////////////////////////////////
// CSS Utils
//////////////////////////////////////////////////////////////////////////

  ** Given a set of pods return a list of CSS files that
  ** form a complete Fantom application:
  **   - flatten the pods using `sys::Pod.flattenDepends`
  **   - order them by dependencies using `sys::Pod.orderByDepends`
  **   - return `toPodCssFiles`
  static File[] toAppCssFiles(Pod[] pods)
  {
    pods = Pod.flattenDepends(pods)
    pods = Pod.orderByDepends(pods)
    return toPodCssFiles(pods)
  }

  ** Map a set of pods to "/res/css/{name}.css" CSS files.
  ** Ignore pods that are missing a CSS file.
  ** This method does *not* flatten/order the pods.
  static File[] toPodCssFiles(Pod[] pods)
  {
    acc := File[,]
    pods.each |pod|
    {
      css := pod.file(`/res/css/${pod.name}.css`, false)
      if (css != null) acc.add(css)
    }
    return acc
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  ** Test program
  @NoDoc static Void main(Str[] args)
  {
    pods := args.map |n->Pod| { Pod.find(n) }
    mainReport(toAppJsFiles(pods))
    mainReport(toAppCssFiles(pods))
  }

  private static Void mainReport(File[] f)
  {
    b := makeFiles(f)
    gzip := b.buf.size.toLocale("B")
    echo("$f.first.ext: $f.size files, $gzip, $b.mimeType")
  }

}