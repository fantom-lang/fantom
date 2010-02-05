//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Apr 09  Brian Frank  Creation
//

**
** ImageTest
**
@Js
class ImageTest : Test
{

  Void test()
  {
    // not actually an image obviously
    file := (Env.cur.homeDir+`lib/fan/gfx.pod`).normalize

    verify := |Image img|
    {
      verifyEq(img.uri, file.uri)
      verifyEq(img, Image.make(file.uri))
      verifyEq(img, Image.makeFile(file))
      verifyEq(img.file, file)
      verifyEq(img.file, file)
    }

    verify(Image(file.uri))
    verify(Image.makeFile(file))

    bad := `/some/really/bad/uri/for/a/image.xyz`
    verifyNull(Image(bad, false))
    verifyNull(Image.makeFile(bad.toFile, false))
    verifyErr(UnresolvedErr#) { Image(bad) }
    verifyErr(UnresolvedErr#) { Image(bad, true) }
    verifyErr(UnresolvedErr#) { Image.makeFile(bad.toFile) }
    verifyErr(UnresolvedErr#) { Image.makeFile(bad.toFile, true) }

    buf := Buf().writeObj(Image(file.uri))
    Image x := buf.flip.readObj
    verifyEq(x.uri, file.uri)
  }

}