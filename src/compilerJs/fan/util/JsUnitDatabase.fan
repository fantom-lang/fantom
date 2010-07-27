//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 10  Andy Frank  Creation
//

**
** JsUnitDatabase
**
class JsUnitDatabase
{
  Void write(OutStream out)
  {
    // parse etc/sys/units.fog as big serialized list which contains
    // lists for each quantity (first item being the name)
    in  := Env.cur.findFile(`etc/sys/units.fog`).in
    all := (Obj[])in.readObj
    in.close

    // map lists to quantity data structures
    all.each |obj|
    {
      q := (Obj[])obj
      n := q.removeAt(0)

      // quanity
      out.printLine(
        "// $n
         fan.sys.Unit.m_quantityNames.add('$n');
         with (fan.sys.Unit.m_quantities['$n'] = fan.sys.List.make(fan.sys.Unit.\$type))
         {")

      // units
      q.each |Unit u| { out.printLine(" add(fan.sys.Unit.fromStr('$u'));") }
      out.printLine("}")
    }

    // finish up
    out.printLine("fan.sys.Unit.m_quantityNames = fan.sys.Unit.m_quantityNames.toImmutable();")
  }
}

