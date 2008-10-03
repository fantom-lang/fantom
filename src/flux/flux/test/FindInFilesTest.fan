//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Oct 08  Andy Frank  Creation
//

internal class FindInFilesTest : Test
{

  Void test()
  {
    type.pod.files.each |File f|
    {
      if (f.uri.toStr.startsWith("/test/files/"))
        f.copyTo(tempDir + f.uri.toStr["/test/files/".size..-1].toUri)
    }

    marks := FindInFiles(tempDir+`alpha.txt`, "foo").find
    verifyEq(marks.size, 1)
    verifyMark(marks[0], "alpha.txt", 0, 0)

    marks = FindInFiles(tempDir, "foo").find
    verifyEq(marks.size, 6)
    verifyMark(marks[0], "alpha.txt", 0, 0)
    verifyMark(marks[1], "beta.java", 2, 9)
    verifyMark(marks[2], "beta.java", 2, 12)
    verifyMark(marks[3], "sub/gamma.fan", 2, 2)
    verifyMark(marks[4], "sub/gamma.fan", 2, 8)
    verifyMark(marks[5], "sub/gamma.fan", 5, 2)

    verifyErr(ArgErr#) |,| { FindInFiles(null, "foo").find }
    verifyErr(ArgErr#) |,| { FindInFiles(tempDir, null).find }
    verifyErr(ArgErr#) |,| { FindInFiles(tempDir, "").find }
    verifyErr(ArgErr#) |,| { FindInFiles(tempDir+`dne/`, "foo").find }
  }

  Void verifyMark(Mark mark, Str name, Int line, Int col)
  {
    verifyEq(mark.uri, tempDir.uri + name.toUri)
    verifyEq(mark.line, line)
    verifyEq(mark.col, col)
  }

}