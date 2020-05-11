//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 May 2020  Brian Frank  Creation
//

using concurrent

**
** FilePackTest
**
class FilePackTest : Test
{

  Void testPack()
  {
    buf := Buf()
    FilePack.pack([
      "a\n".toBuf.toFile(`a.txt`),
      "b".toBuf.toFile(`b.txt`),
      "c\n".toBuf.toFile(`c.txt`),
      "".toBuf.toFile(`d.txt`),
      "e".toBuf.toFile(`e.txt`),
     ], buf.out)
     buf = buf.toImmutable
    verifyEq(buf.in.readAllStr, "a\nb\nc\ne\n")
  }
}