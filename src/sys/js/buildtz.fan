#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Jul 09  Andy Frank  Creation
//   8 Jul 09  Andy Frank  Split webappClient into sys/dom
//

using build

**
** Generate the TimeZone rules for JavaScript.
**
class BuildTz
{
  Void main()
  {
    js  := Env.cur.homeDir + `src/sys/js/fan/timezones.js`
    out := js.out
    try
    {
      out.printLine(
       "//
        // Copyright (c) 2009, Brian Frank and Andy Frank
        // Licensed under the Academic Free License version 3.0
        //
        // Auto-generated $DateTime.now
        //

        var tz,rule;
        ")

      loadIndex
      indexNames.each |name| {
        if (include(name))
          loadTimeZone(name, out)
      }

      // DateTime.defVal
      out.printLine(
       "// DateTime.defVal
        fan.sys.DateTime.m_defVal = fan.sys.DateTime.make(2000, fan.sys.Month.m_jan, 1, 0, 0, 0, 0, fan.sys.TimeZone.utc());
        fan.sys.DateTime.m_boot = fan.sys.DateTime.now();
        ")
    }
    finally { out.close }
  }

  Bool include(Str name)
  {
    if (name == "Etc/UTC") return true
    if (name == "America/New_York") return true
    if (name == "America/Chicago") return true
    if (name == "America/Denver") return true
    if (name == "America/Los_Angeles") return true
    if (name.contains("GMT")) return true
    return false
  }

  Void loadIndex()
  {
    db = Env.cur.homeDir + `etc/sys/timezones.ftz`
    if (!db.exists) throw Err("tz databse not found: $db")
    in := db.in

    try
    {
      // check magic "fantz 01"
      magic := in.readS8
      if (magic != 0x66616e747a203031)
        throw IOErr("Invalid magic 0x$magic.toHex");
      in.readUtf

      // load the name/offset pairs and verify in sort order
      num := in.readU4
      num.times |i|
      {
        indexNames.add(in.readUtf)
        indexTypes.add(in.read)
        indexOffsets.add(in.readU4)
        if (i != 0 && (indexNames[i-1] <=> indexNames[i]) >= 0)
          throw IOErr("Index not sorted");
      }
    }
    finally { in.close }
  }

  Void loadTimeZone(Str tz, OutStream out)
  {
    // find index, which maps the file offset
    ix := indexNames.binarySearch(tz)
    if (ix < 0) return
    seekOffset := indexOffsets[ix]

    // read time zone definition from database file
    buf := db.mmap("rw", seekOffset)
    try
    {
      name     := buf.readUtf();
      fullName := buf.readUtf();
      numRules := buf.readU2();

      out.printLine(
       "// $fullName
        tz = new fan.sys.TimeZone();
        tz.m_name = \"$name\";
        tz.m_fullName = \"$fullName\";
        tz.m_rules = [];")

      numRules.times
      {
        startYear := buf.readU2();
        offset    := buf.readS4();
        stdAbbr   := buf.readUtf();
        dstOffset := buf.readU4();

        out.printLine(
         "rule = new fan.sys.TimeZone\$Rule();
           rule.startYear = $startYear;
           rule.offset = $offset;
           rule.stdAbbr = \"$stdAbbr\";
           rule.dstOffset = $dstOffset;")

        if (dstOffset != 0)
        {
          dstAbbr   := buf.readUtf();
          dstStart  := loadDstTime(buf);
          dstEnd    := loadDstTime(buf);

          out.printLine(
           " rule.dstAbbr = \"$dstAbbr\";
             rule.dstStart = $dstStart;
             rule.dstEnd = $dstEnd;")
        }

        out.printLine(" tz.m_rules.push(rule);")
      }

      out.printLine("fan.sys.TimeZone.cache[\"$name\"] = tz;")
      out.printLine("fan.sys.TimeZone.cache[\"$fullName\"] = tz;")
      out.printLine("fan.sys.TimeZone.names.push(\"$name\");")
      out.printLine("fan.sys.TimeZone.fullNames.push(\"$fullName\");")
      out.printLine("")
    }
    finally { buf.close() }
  }

  Str loadDstTime(Buf buf)
  {
    mon       := buf.read();
    onMode    := buf.read();
    onWeekday := buf.read();
    onDay     := buf.read();
    atTime    := buf.readU4();
    atMode    := buf.read();
    return "new fan.sys.TimeZone\$DstTime($mon, $onMode, $onWeekday, $onDay, $atTime, $atMode)"
  }

  File? db
  Str[] indexNames   := Str[,]
  Int[] indexTypes   := Int[,]
  Int[] indexOffsets := Int[,]
}