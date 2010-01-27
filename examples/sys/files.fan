#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 07  Brian Frank  Creation
//   08 Sep 09  Brian Frank  Rework fandoc -> example
//

**
** Working with sys::File
**
class Files
{
  File temp := Env.cur.tempDir

  Void main()
  {
    constructors
    naming
    dirs
    textIO
    binaryIO
    objIO
  }

  Void constructors()
  {
    echo("\n--- constructors ---")
    // construct from Uri
    show(File.make(`dir/foo.txt`), "File.make(Uri) longhand")
    show(File(`dir/foo.txt`),      "File.make(Uri) shorthand")
    show(`dir/foo.txt`.toFile,     "Uri.toFile")

    // construct from OS specific path
    show(File.os("bin\\command.exe"),               "File.os")
    show(File.os("bin" + File.sep + "command.exe"), "File.os with separator")

    // construct File instance against base directory
    dir := `/somedir/`.toFile
    show(dir + `foo.txt`,          "/somedir/foo.txt")
    show(dir + `subdir/foo.txt`,   "/somedir/subdir/foo.txt")
    show(dir + `../foo.txt`,       "/foo.txt")
  }

  Void naming()
  {
    echo("\n--- naming ---")
    f := `/files/today/foo.txt`.toFile
    show(f.uri,          "/files/today/foo.txt")
    show(f.path,         "[files, today, foo.txt]")
    show(f.pathStr,      "/files/today/foo.txt")
    show(f.name,         "foo.txt")
    show(f.basename,     "foo")
    show(f.ext,          "txt")
    show(f.parent.path,  "[files, today]")
    show(f.osPath,       "\\files\\today\\foo.txt")
  }

  Void dirs()
  {
    echo("\n--- dirs ---")

    // check if file is a directory
    dir := Env.cur.homeDir
    show(dir.isDir,  "dir.isDir")

    // list all files in a directory (files and dirs)
    show(dir.list, "dir.list")

    // list file names in a directory
    show(dir.list.map |f->Str| { f.name }, "dir.list mapped to names")

    // get sub directories (filter out files)
    show(dir.list.findAll |f| { f.isDir }, "list sub-directories hard way")
    show(dir.listDirs,                     "list sub-directories easy way")

    // get child files (filter out sub directories)
    show(dir.list.findAll |f| { !f.isDir }, "list child files hard way")
    show(dir.listFiles,                     "list child files easy way")

    // create directory (uri must end in / slash)
    testDir := temp + `testdir/`
    testDir.create
    show(testDir, "create directory")
  }

  Void textIO()
  {
    echo("\n--- text IO ---")
    f := temp + `text-io.txt`
    show(f, "creating text file")

    // write text file (overwrites existing)
    f.out.printLine("hello").close

    // append to existing text file
    f.out(true).printLine("world").close

    // read text file as big string
    echo("\nreadAllStr:")
    echo(f.readAllStr.toCode)

    // read text file into list of lints
    echo("\nreadAllLines:")
    echo(f.readAllLines)

    // read text file, line by line
    echo("\neachLine:")
    f.eachLine |line| { echo(line.toCode) }
  }

  Void binaryIO()
  {
    echo("\n--- binary IO ---")
    f := temp + `binary-io.txt`
    show(f, "creating binary file")

    // write some binary data
    out := f.out
    out.write(0x11)
    out.writeI2(0x2233)
    out.writeI4(0x44556677)
    out.writeUtf("abc")
    out.close

    // read binary data back again
    show(f.readAllBuf.toHex, "read entire file into memory buffer")
    in := f.in
    show(in.read.toHex,      "read single 8-bit byte")
    show(in.readU2.toHex,    "read unsigned 16-bit int")
    show(in.readU4.toHex,    "read unsigned 32-bit int")
    show(in.readUtf,         "read UTF string")
    in.close
  }

  Void objIO()
  {
    echo("\n--- object IO ---")
    f := temp + `obj-io.txt`
    echo("creating:")
    echo(f)

    // write a serialized object (list of things)
    f.writeObj([2, "hello", 5sec])

    // read object back again
    show(f.readObj, "File.readObj")
  }

  Void show(Obj? result, Str what)
  {
    resultStr := "" + result
    if (resultStr.size > 40) resultStr = resultStr[0..40] + "..."
    echo(what.padr(40) + " => " + resultStr)
  }

}




