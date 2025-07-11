//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 22  Brian Frank  Creation
//

class FileLocTest : Test
{

  Void test()
  {
    verifyLoc(FileLoc("foo"),       "foo", 0, 0)
    verifyLoc(FileLoc("foo", 2),    "foo", 2, 0)
    verifyLoc(FileLoc("foo", 2, 3), "foo", 2, 3)

    verifyCmd(FileLoc("a"), FileLoc("a"), 0)
    verifyCmd(FileLoc("a"), FileLoc("b"), -1)
    verifyCmd(FileLoc("b"), FileLoc("a"), 1)
    verifyCmd(FileLoc("a", 2), FileLoc("a", 2), 0)
    verifyCmd(FileLoc("a", 2), FileLoc("a", 4), -1)
    verifyCmd(FileLoc("a", 4), FileLoc("a", 2), 1)
    verifyCmd(FileLoc("a", 2, 5), FileLoc("a", 2, 5), 0)
    verifyCmd(FileLoc("a", 2, 5), FileLoc("a", 2, 7), -1)
    verifyCmd(FileLoc("a", 2, 9), FileLoc("a", 2, 7), 1)

    verifyLoc(FileLoc("foo.txt").toFilenameOnly, "foo.txt", 0, 0)
    verifyLoc(FileLoc("foo.txt", 1, 2).toFilenameOnly, "foo.txt", 1, 2)
    verifyLoc(FileLoc("/path/foo.txt").toFilenameOnly, "foo.txt", 0, 0)
    verifyLoc(FileLoc("\\path\\foo.txt", 1, 2).toFilenameOnly, "foo.txt", 1, 2)
    verifyLoc(FileLoc("/long/path/here/foo.txt", 2, 3).toFilenameOnly, "foo.txt", 2, 3)
  }

  Void verifyLoc(FileLoc loc, Str file, Int line, Int col)
  {
    verifyEq(loc.file, file)
    verifyEq(loc.line, line)
    verifyEq(loc.col, col)
    verifyEq(FileLoc(file, line, col), loc)
    verifyEq(FileLoc.parse(loc.toStr), loc)
  }

  Void verifyCmd(FileLoc a, FileLoc b, Int expected)
  {
    verifyEq(a <=> b, expected)
    verifyEq(a == b, expected == 0)
    verifyEq(a < b, expected < 0)
    verifyEq(a > b, expected > 0)
  }
}

