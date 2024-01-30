//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Mar 2022  Brian Frank  Creation
//

using concurrent

**
** GraphicsEnv encapsulates a graphics toolkit.  It is responsible
** image loading and caching.
**
@Js
const mixin GraphicsEnv
{
  ** Default environment for the VM
  static GraphicsEnv cur()
  {
    // lazily initialize
    cur := curRef.val
    if (cur == null) curRef.val = cur = init
    return cur
  }
  private static const AtomicRef curRef := AtomicRef(null)

  ** Initialize default for environment
  private static GraphicsEnv? init()
  {
    if (Env.cur.runtime == "js")
      return Type.find("dom::DomGraphicsEnv").make
    else
      return Type.find("graphicsJava::ServerGraphicsEnv").make
  }

  ** Install new cur default for the VM
  @NoDoc static Void install(GraphicsEnv env) { curRef.val = env }

  ** Get an image for the given uri.  The uri is the unique key for the image
  ** in this environment.  If file data is null, then asynchronously load and
  ** cache the image on the first load.  Standard supported formats are: PNG,
  ** JPEG, and SVG.
  abstract Image image(Uri uri, Buf? data := null)

  ** Make a new rendered image instance or throw 'Err' if not supported.
  @NoDoc virtual Image renderImage(MimeType mime, Size size, |Graphics| f)
  {
    throw Err("Not supported in this env")
  }
}