#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Nov 08  Andy Frank  Creation
//

**
** Crush runs pngcrush to reduce PNG file sizes.
**
class Crush
{

  static Void main()
  {
    c := Crush()
    {
      root = Sys.args.size == 0 ? Sys.appDir : Sys.args[0].toUri.toFile
    }
    c.run()
    echo("$c.count files crushed removing $c.bytes bytes")
  }

  Void run(File orig := root)
  {
    if (orig.isDir) orig.list.each |File kid| { run(kid) }
    else if (orig.ext == "png")
    {
      crush := (orig.uri.toStr + "_crush").toUri.toFile
      cmd   := ["pngcrush", "-brute", "-rem", "alla", orig.osPath, crush.osPath]

      r := Process.make(cmd) { out = Buf.make.out }.run.join
      if (r != 0) throw Err.make("*** Failed ***")

      diff := orig.size - crush.size
      if (diff > 0)
      {
        echo(orig.uri.toStr[root.uri.toStr.size..-1] + " ($diff)")
        count++
        bytes += diff
        crush.copyTo(orig, ["overwrite":true])
      }
      crush.delete
    }
  }

  File root
  Int count
  Int bytes

}