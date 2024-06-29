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
@Js
class ConsoleTest : Test
{
  static Void main()
  {
    c := Console.cur
    // c = Console.wrap(Env.cur.out)
    echo("Console $c [$c.typeof]")
    echo("width  = $c.width")
    echo("height = $c.height")

    // basic logging
    c.debug("Debug message!")
    c.info("Info message!")
    c.warn("Warn message!")
    c.err("Error message!")

    // table - null
    c.info("")
    c.table(null)

    // table - scalar
    c.info("")
    c.table(123)

    // table - list of scalars
    c.info("")
    c.table(["a", "b", "c"])

    // table - list of maps
    c.info("")
    c.table([
      ["First Name":"Bob", "Last Name":"Smith"],
      ["First Name":"John", "Last Name":"Apple", "Approx Age":52],
      ["First Name":"Alice", "Last Name":"Bobby", "Job":"Programmer"],
      ])

    // table - 2d grid
    c.info("")
    c.table([
      ["Name",    "Age", "Hire Month"],
      ["Alpha",   "30",  "Jan-2020"],
      ["Beta",    "40",  "Feb-1996"],
      ["Charlie", "50",  "Mar-2024"]
      ])
    c.info("")

    // group
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

    // group collapsed
    c.group("Collapsed", true)
    c.info("alpha")
    c.info("beta")
    c.info("gamma")
    c.groupEnd

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

