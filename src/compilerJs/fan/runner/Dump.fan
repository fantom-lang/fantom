//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Jul 09  Andy Frank  Creation
//

**
** Dump the JavaScript source for a pod.
**
class Dump
{

  Void main()
  {
    if (Sys.args.size == 0)
    {
      help
      Sys.exit(-1)
    }

    pod  := Sys.args.first
    line := Sys.args.size > 1 ? Sys.args[1].toInt : null
    cx   := Sys.args.size > 2 ? Sys.args[2].toInt : 4

    Pod.find(pod).files[`/${pod}.js`].readAllLines.each |s,i|
    {
      // if lineNum specific print out a few lines before/after for context
      if (line != null && (line-i).abs > cx) return
      echo("${i.toStr.padl(4)}: $s")
    }
  }

  Void help()
  {
    echo("compilerJs Dump Utility");
    echo("Usage:");
    echo("  dump <pod> [line] [context]");
    echo("Options:");
    echo("  line     dump a specific line number");
    echo("  context  number of lines to print around [line]; defaults to 4");
  }

}

