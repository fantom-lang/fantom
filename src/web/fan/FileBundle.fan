//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 2020  Brian Frank  Creation
//

using concurrent

**
** FileBundle is an in-memory cache of multiple text files to service
** static resources via HTTP.  It takes one or more text files and
** creates one compound file.  The result is stored in RAM using GZIP
** compression.
**
** The `onService` method is used to service GET requests for the bundle.
** The Content-Type header is set based on file extension of files bundled.
** It also implictly supports ETag/Last-Modified for 304 optimization.
**
** The core factory is the `makeFiles` constructor.  A suite of utility
** methods is provided for standard bundling of Fantom JavaScrit and CSS
** files.
**
const class FileBundle
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
    compress := true
    out := compress ? Zip.gzipOutStream(buf.out) : buf.out
    files.each |f|
    {
      f.in.pipe(out)
      out.printLine // insert extra newline between each file
    }
    out.close
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
// Methods
//////////////////////////////////////////////////////////////////////////

  ** The in-memory file contents in GZIP encoding
  const Buf buf

  ** Entity tag provides a SHA-1 hash for the bundle contents
  const Str etag

  ** Modified time is when bundle was generated
  const DateTime modified

  ** Inferred mime type from file extensions
  const MimeType mimeType

  ** Service an HTTP GET request for this bundle file
  Void onService(WebReq req, WebRes res)
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
// JavaScript Utils
//////////////////////////////////////////////////////////////////////////

  ** Given a set of pods return a list of JavaScript files that
  ** form a complete Fantom application:
  **   - flatten the pods using `sys::Pod.flattenDepends`
  **   - order them by dependencies using `sys::Pod.orderByDepends`
  **   - insert `toEtcJsFiles` immediately after "sys.js"
  static File[] toAppJsFiles(Pod[] pods, Bool flattenAndOrder := true)
  {
    pods = Pod.flattenDepends(pods)
    pods = Pod.orderByDepends(pods)
    files := toPodJsFiles(pods)
    files.insertAll(1, toEtcJsFiles)
    return files
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
      js := pod.file(`/${pod.name}.js`, false)
      if (js != null) acc.add(js)
    }
    return acc
  }

  ** Return the required sys etc files:
  **  - add `toUnitsJsFile`
  **  - add `toTimezonesJsFile`
  **  - add `toIndexPropsJsFile`
  static File[] toEtcJsFiles()
  {
    [toUnitsJsFile, toTimezonesJsFile, toIndexPropsJsFile]
  }

  ** Compile the unit database into a JavaScript file "unit.js"
  static File toUnitsJsFile()
  {
    buf := Buf(50_000)
    c := Type.find("compilerJs::JsUnitDatabase").make
    c->write(buf.out)
    return buf.toFile(`units.js`)
  }

  ** Compile the timezone database into a JavaScript file "tz.js"
  static File toTimezonesJsFile()
  {
    Env.cur.homeDir + `etc/sys/tz.js`
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