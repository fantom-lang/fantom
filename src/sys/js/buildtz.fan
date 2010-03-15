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
    if (name == "UTC") return true
    if (name == "New_York") return true
    if (name == "Chicago") return true
    if (name == "Denver") return true
    if (name == "Los_Angeles") return true
    if (name.contains("GMT")) return true

    // timezones used in testSys
    if (name == "London") return true
    if (name == "Amsterdam") return true
    if (name == "Kiev") return true
    if (name == "Sao_Paulo") return true
    if (name == "Sydney") return true
    if (name == "Riga") return true
    if (name == "Jerusalem") return true
    if (name == "St_Johns") return true
    if (name == "Godthab") return true

    return false
  }

  Void loadIndex()
  {
    db = Env.cur.homeDir + `etc/sys/timezones.ftz`
    if (!db.exists) throw Err("tz databse not found: $db")
    in := db.in

    try
    {
      // check magic "fantz 02"
      magic := in.readS8
      if (magic != 0x66616e747a203032)
        throw IOErr("Invalid magic 0x$magic.toHex");
      in.readUtf

      // load prefixes
      numPrefixes := in.readU1
      numPrefixes.times { prefixes.add(in.readUtf) }

      // load the name/offset pairs and verify in sort order
      num := in.readU2
      num.times |i|
      {
        indexPrefixes.add(in.readU1)
        indexNames.add(in.readUtf)
        indexOffsets.add(in.readU4)
        if (i != 0 && (indexNames[i-1] <=> indexNames[i]) >= 0)
          throw IOErr("Index not sorted");
      }
    }
    finally { in.close }
  }

  Void loadTimeZone(Str x, OutStream out)
  {
    name  := x
    slash := x.indexr("/")
    if (slash != null) name = name[slash+1..-1]

    // find index, which maps the file offset
    ix := indexNames.binarySearch(name)
    if (ix < 0) return
    seekOffset := indexOffsets[ix]

    // map full name
    fullName := name
    prefix   := prefixes[indexPrefixes[ix].and(0xff)]
    if (prefix.size != 0) fullName = "$prefix/$name"
    if (slash != null && x != fullName) throw Err("Unexpected")

    // read time zone definition from database file
    buf := db.mmap("rw", seekOffset)
    try
    {
      out.printLine(
       "// $fullName
        tz = new fan.sys.TimeZone();
        tz.m_name = \"$name\";
        tz.m_fullName = \"$fullName\";
        tz.m_rules = [];")

      numRules := buf.readU2();
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
  Str[] prefixes      := Str[,]
  Int[] indexPrefixes := Int[,]
  Str[] indexNames    := Str[,]
  Int[] indexOffsets  := Int[,]
}