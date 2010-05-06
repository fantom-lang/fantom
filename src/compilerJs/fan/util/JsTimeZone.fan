//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 May 10  Andy Frank  Creation
//

**
** JsTimeZone
**
class JsTimeZone
{
  new make(TimeZone tz)
  {
    this.tz = tz
  }

  Void write(OutStream out)
  {
    // tz,rule defined in sys.js
    out.printLine(
     """// $tz.fullName
        tz = new fan.sys.TimeZone();
        tz.m_name = "$tz.name";
        tz.m_fullName = "$tz.fullName";
        tz.m_rules = [];""")

    rules := ([Str:Obj][])tz->rules
    rules.each |r|
    {
      startYear := r["startYear"]
      offset    := r["offset"]
      stdAbbr   := r["stdAbbr"]
      dstOffset := r["dstOffset"]

      out.printLine(
       """rule = new fan.sys.TimeZone\$Rule();
           rule.startYear = $startYear;
           rule.offset = $offset;
           rule.stdAbbr = "$stdAbbr";
           rule.dstOffset = $dstOffset;""")

      if (dstOffset != 0)
      {
        dstAbbr := r["stdAbbr"]
        out.printLine(""" rule.dstAbbr = "$dstAbbr";""")
        out.print(" rule.dstStart = "); writeDstTime(r["dstStart"], out)
        out.print(" rule.dstEnd = "); writeDstTime(r["dstEnd"], out)
      }

      out.printLine(" tz.m_rules.push(rule);")
    }

    out.printLine(
     """fan.sys.TimeZone.cache["$tz.name"] = tz;
        fan.sys.TimeZone.cache["$tz.fullName"] = tz;
        fan.sys.TimeZone.names.push("$tz.name");
        fan.sys.TimeZone.fullNames.push("$tz.fullName");
        """)
  }

  private Void writeDstTime(Str:Obj map, OutStream out)
  {
    mon       := map["mon"]
    onMode    := map["onMode"]
    onWeekday := map["onWeekday"]
    onDay     := map["onDay"]
    atTime    := map["atTime"]
    atMode    := map["atMode"]
    out.printLine("new fan.sys.TimeZone\$DstTime($mon,$onMode,$onWeekday,$onDay,$atTime,$atMode)")
  }

  TimeZone tz
}

