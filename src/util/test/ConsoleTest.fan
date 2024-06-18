//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Jun 24  Brian Frank  Creation
//

**
** ConsoleTest isn't an actual test, just a program to run to see results
**
//@Js
class ConsoleTest : Test
{
  Void main()
  {
    c := Console.cur
    c.info("Console $c [$c.typeof]")
    c.info("width  = $c.width")
    c.info("height = $c.height")

    // basic logging
    c.debug("Debug message!")
    c.info("Info message!")
    c.warn("Warn message!")
    c.err("Error message!")

    // tables
    c.table("scalar")

    // indent/unindent
    c.group("indent 0")
    c.info("line 1")
    c.warn("line 2")
    c.group("indent 1")
    c.err("line 3")
    c.table("scalar")
    c.groupEnd
    c.err("line 4")
    c.groupEnd
    c.info("line 5 back to zero")

    // prompt
    c.info("Prompt 1>")
    x := c.prompt
    c.info(x)
    x = c.prompt("Prompt 2> ")
    c.info(x)

    // promptPassword
    c.info("Password 1>")
    x = c.promptPassword
    c.info(x)
    x = c.promptPassword("Passwor 2> ")
    c.info(x)

    c.info("")
    c.info("All done!")
  }
}

