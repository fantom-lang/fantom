//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler
using fandoc

**
** CopyResources copies master resource files like fandoc.css
** to the target directory.
**
class CopyResources : DocCompilerSupport
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    copy(`/res/doc.css`, compiler.outDir)
    copy(`/res/doc.js`, compiler.outDir)
    copy(`/res/go-previous.png`, compiler.outDir)
    copy(`/res/go-next.png`, compiler.outDir)
    copy(`/res/eximg.png`, compiler.outDir)
    copy(`/res/fanLogo.png`, compiler.outDir)
    copy(`/res/slotBg.png`, compiler.outDir)
    copy(`/res/slotHiddenBg.png`, compiler.outDir)
    copy(`/res/subHeaderBg.png`, compiler.outDir)
  }

  Void copy(Uri uri, File dir)
  {
    from := type.pod.files[uri]
    to := dir + uri.name.toUri
    if (from == null)
    {
      log.warn("Missing resource file $uri")
      return
    }

    log.debug("  Copy [$to]")

    to.create
    out := to.out
    from.in.pipe(out)
    out.close
  }

}
