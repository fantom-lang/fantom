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
** Working with sys::Log
**
class Logging
{

  // get or create a log named "acme"
  const static Log log := Log.get("acme")

  Void main()
  {
    // list all the active logs
    echo("\n--- Log.list ---")
    echo(Log.list.join("\n"))

    // get the standard log for a type's pod
    echo("\n--- sysLog ---")
    echo(Str#.pod.log)
    echo(Pod.of("foo").log)

    // find an existing log
    echo("\n--- find existing ---")
    log := Log.find("acme")
    echo(log)

    // log at different levels
    echo("\n--- logging ---")
    log.err("The freaking file didn't load", IOErr())
    log.info("CatchRoadRoader service started")
    log.warn("Something fishy is going on here")
    log.debug("Not logged by default")

    // setting log level
    echo("\n--- log level ---")
    echo("old level = $log.level")
    log.level = LogLevel.debug
    echo("new level = $log.level")

    // this code performs string concatenation on every call
    x := 1; y := 2; z := 3
    log.debug("The vals are x=$x, y=$y, and z=$z")

    // this code performs string concatenation only when needed
    if (log.isDebug)
      log.debug("The vals are x=$x, y=$y, and z=$z")

    // installing log handler
    echo("\n--- installing log handler ---")
    Log.addHandler |rec| { echo("My Handler: $rec") }
    log.info("log with handler!")
  }

}




