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

    results := FindInFiles.find("foo", tempDir+`alpha.txt`)
    verifyEq(results.size, 1)
    verifyMark(results[0], "alpha.txt", 1, 1)

    results = FindInFiles.find("foo", tempDir)
    verifyEq(results.size, 6)
    verifyMark(results[0], "alpha.txt", 1, 1)
    verifyMark(results[1], "beta.java", 3, 10)
    verifyMark(results[2], "beta.java", 3, 13)
    verifyMark(results[3], "gamma.fan", 3, 3)
    verifyMark(results[4], "gamma.fan", 3, 9)
    verifyMark(results[5], "gamma.fan", 6, 3)

    results = FindInFiles.find("", tempDir)
    verifyEq(results.size, 0)

    //verifyErr(ArgErr#) |,| { FindInFiles(null, "foo").find }
    //verifyErr(ArgErr#) |,| { FindInFiles(tempDir, null).find }
    verifyErr(ArgErr#) |,| { FindInFiles.find("foo", tempDir+`dne/`) }
  }

  Void verifyMark(Str result, Str name, Int line, Int col)
  {
    a := result.indexr("\\")
    b := result.index("(", a)
    c := result.index(",", b)
    d := result.index(")", c)

    testName := result[a+1..<b]
    testLine := result[b+1..<c].toInt
    testCol  := result[c+1..<d].toInt

    verifyEq(testName, name)
    verifyEq(testLine, line)
    verifyEq(testCol, col)
  }

}