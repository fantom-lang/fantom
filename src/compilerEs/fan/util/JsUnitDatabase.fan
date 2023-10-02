//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 2010  Andy Frank  Creation
//   07 Jul 2023  Matthew Giannini  Refactor for ES
//

**
** JsUnitDatabase
**
class JsUnitDatabase
{
  new make(ModuleSystem ms) { this.ms = ms }

  private ModuleSystem ms;

  Void write(OutStream out)
  {
    ms.writeBeginModule(out)
    ms.writeInclude(out, "sys.ext")

    // open etc/sys/units.txt
    in := Env.cur.findFile(`etc/sys/units.txt`).in
    out.printLine("const qn=sys.List.make(sys.Str.type\$,[]);")
    out.printLine("let q;")

    // parse each line
    curQuantityName := ""
    in.readAllLines.each |line|
    {
      // skip comment and blank lines
      line = line.trim
      if (line.startsWith("//") || line.size == 0) return

      // quanity sections delimited as "-- name (dim)"
      if (line.startsWith("--"))
      {
        name := line[2..<line.index("(")].trim
        if (name != curQuantityName)
        {
          // close off last def
          if (curQuantityName.size > 0)
          {
            out.printLine("sys.Unit.__quantityUnits('${curQuantityName}', q);\n")
          }

          // start new def
          curQuantityName = name
          out.printLine(
            "// $curQuantityName
             qn.add('${curQuantityName}');
             q = sys.List.make(sys.Unit.type\$, []);")
        }
        return
      }

      // add unit
      out.printLine("q.add(sys.Unit.define('${line}'));")
    }

    // close off last def
    out.printLine("sys.Unit.__quantityUnits('${curQuantityName}', q);\n")

    // finish up
    out.printLine("sys.Unit.__quantities(qn);")
    ms.writeEndModule(out)
  }
}

