//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 08  Brian Frank  Creation
//

using web

**
** FileMod is a web module which publishes a file or directory.
**
** See [pod doc]`pod-doc#file`
**
const class FileMod : WebMod
{
  **
  ** Constructor with it-block.
  **
  new make(|This|? f)
  {
    f?.call(this)
    if (file === noFile) throw ArgErr("Must configure ${Type.of(this)}.file field")
    if (!file.exists) throw ArgErr("${Type.of(this)}.file does not exist: $file")
  }

  **
  ** File or directory to publish.  This field must be
  ** configured in the constructor's it-block.
  **
  const File? file := noFile
  private static const File noFile := File(`no-file-configured`)

  override Void onService()
  {
    // if servicing a single file, we handle specially
    if (!file.isDir)
    {
      // don't publish a single file with path longer than mod itself
      if (!req.modRel.path.isEmpty) { res.sendErr(404); return }

      // publish the file and we ar don
      FileWeblet(file).onService
      return
    }

    // get file under directory
    f := this.file.plus(req.modRel, false)

    // if we've resolved a directory
    if (f.isDir)
    {
      // if trailing slash wasn't used by req, redirect to use slash
      if (!req.uri.isDir) { res.redirect(req.uri.plusSlash); return }

      // map to "index.html"
      f = f + `index.html`
    }

    // if it doesn't exist then 404
    if (!f.exists) { res.sendErr(404); return }

    // publish the file
    FileWeblet(f).onService
  }

}