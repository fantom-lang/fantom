#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Sep 07  Brian Frank  Creation
//   21 Jul 09  Brian Frank  Update to latest language changes
//   21 Jul 09  Brian Frank  Upgrade to more compressed format
//

using build

**
** This build script parses the text input files from the Olsen
** tz database and compiles it into the Fan timezone database.
**
** We strip out most of the older historical timezones - see minYear.
**
** Refer to the "zic.8.txt" source file the code distribution
** to describe the format of the input text files.
**
** http://www.twinsun.com/tz/tz-link.htm
** ftp://elsie.nci.nih.gov/pub/
**
** Refer to TimeZone.java for the time zone binary database format.
**
class Build : BuildScript
{

//////////////////////////////////////////////////////////////////////////
// Inputs
//////////////////////////////////////////////////////////////////////////

  // directory of input files
  Uri srcDir := `/dev/tools/tz/`

  // input files from Olsen database
  Uri[] srcUris :=
  [
    `africa`,
    `antarctica`,
    `asia`,
    `australasia`,
    `europe`,
    `northamerica`,
    `southamerica`,
    `etcetera`,
    `systemv`,
  ]

  // we don't include any historical rules older than this
  Int minYear := 1995

  // we don't include any rules after this date (applies
  // to Israeli time which is calculated out into the future)
  Int maxYear := 2020

  // parsed zones
  Zone[] zones := Zone[,]
  Rule[] rules := Rule[,]

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  @Target { help = "compile tz database" }
  Void compile()
  {
    log.info("compile [$srcDir]")

    // parse input files into rules and zones
    srcUris.each |Uri uri| { parse(uri) }

    // find Etc/UTC and make copy for Etc/Rel
    addEtcRel

    // normalize zone items and rules
    normalize

    // dump
//    zones.each |Zone z| { z.dump }

    // write tzdb
    writeDatabase()
  }

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  Void parse(Uri uri)
  {
    log.info("parse [$uri]")
    lineNum := 0
    Zone? lastZone := null
    rules := Rule[,]

    f := srcDir.toFile + uri
    f.eachLine |Str line|
    {
      lineNum++
      try
      {
        // strip and skip comments
        if (line.size == 0) return
        leadingWs := line[0].isSpace
        line = line.trim
        if (line.size == 0 || line[0] == '#') return
        pound := line.indexr("#")
        if (pound != null) line = line[0..<pound]

        toks := line.split
        switch (toks.first)
        {
          case "Rule":
            parseRule(toks)
          case "Zone":
            parseZone(null, toks)
          case "Link":
            echo("IGNORE: $line")
          default:
            if (leadingWs)
              parseZone(zones.last, toks)
            else
              throw Err(line)
        }
      }
      catch (Err e)
      {
        echo("ERROR: parsing $f [Line $lineNum]")
        e.trace
        throw FatalBuildErr()
      }
    }
  }

  Void parseZone(Zone? zone, Str[] toks)
  {
    // if zone is non-null this is a continuation,
    // otherwise we need to create the zone
    n := 0
    if (zone == null)
    {
      n++
      zone = Zone()
      zone.name = toks[n++]
      zones.add(zone)
    }

    item := ZoneItem()
    item.offset = AtTime.parse(toks[n++])
    item.rule   = toks[n++]
    item.format = toks[n++]
    item.until  = n < toks.size ? toks[n++].toInt : null

    // if we have more tokens then this item ends in the
    // middle of the year which Fan doesn't handle - we
    // normalize everything cleanly into years
    if (n != toks.size && item.until >= minYear)
      echo("#### WARNNING: Non-year boundary: $zone.name $toks")

    // skip really old stuff
    if (item.until != null && item.until < minYear) return

    zone.items.add(item)
  }

  Void parseRule(Str[] toks)
  {
    n := 1
    rule := Rule()
    rule.name   = toks[n++]
    rule.from   = toRuleTo(null, toks[n++])
    rule.to     = toRuleTo(rule.from, toks[n++])
    rule.kind   = toks[n++]
    rule.in     = toMonth(toks[n++])
    rule.on     = OnDay.parse(toks[n++])
    rule.at     = AtTime.parse(toks[n++])
    rule.save   = AtTime.parse(toks[n++])
    rule.letter = toks[n++][0]

    // skip really old stuff
    if (rule.to != null && rule.to < minYear) return

    rules.add(rule)
  }

  Int? toRuleTo(Int? from, Str s)
  {
    if (s == "min")  return 1900
    if (s == "only") return from
    if (s == "max")  return null
    return s.toInt
  }

  static Weekday toWeekday(Str s)
  {
    x := weekdays[s]
    if (x == null) throw ParseErr(s)
    return x
  }
  static const Str:Weekday weekdays :=
  [
    "Sun":Weekday.sun,
    "Mon":Weekday.mon,
    "Tue":Weekday.tue,
    "Wed":Weekday.wed,
    "Thu":Weekday.thu,
    "Fri":Weekday.fri,
    "Sat":Weekday.sat,
  ].toImmutable

  static Month toMonth(Str s)
  {
    x := months[s]
    if (x == null) throw ParseErr(s)
    return x
  }
  static const Str:Month months :=
  [
    "Jan":Month.jan, "Feb":Month.feb, "Mar":Month.mar, "Apr":Month.apr,
    "May":Month.may, "Jun":Month.jun, "Jul":Month.jul, "Aug":Month.aug,
    "Sep":Month.sep, "Oct":Month.oct, "Nov":Month.nov, "Dec":Month.dec
  ].toImmutable

//////////////////////////////////////////////////////////////////////////
// Etc/Rel
//////////////////////////////////////////////////////////////////////////

  Void addEtcRel()
  {
    utc := zones.find |zone| { zone.name == "Etc/UTC" }
    if (utc.items.size != 1) throw Err();
    if (utc.rules != null) throw Err();
    rel := Zone
    {
      name = "Etc/Rel"
      items = [ZoneItem
      {
        format = "Rel";
        offset = utc.items.first.offset
        rule   = utc.items.first.rule
        until  = utc.items.first.until
      }]
    }
    zones.add(rel)
  }

//////////////////////////////////////////////////////////////////////////
// Normalize
//////////////////////////////////////////////////////////////////////////

  Void normalize()
  {
    zones.each |Zone z| { normalizeZone(z) }
  }

  Void normalizeZone(Zone z)
  {
    debug := false // z.name == "Australia/Sydney"
    if (debug) { echo("-------> $z.name"); z.items.each |ZoneItem item| { echo("  $item") } }

    // map all the zone items into normalized rules
    z.rules = NormRule[,]
    from := null
    z.items.each |ZoneItem item|
    {
      if (debug) echo("  ---> from=$from  item=$item")
      z.rules.addAll(normalizeZoneItem(z, item, from))
      from = item.until
      if (debug) { echo("  <---"); z.rules.each |NormRule r| { echo("     $r") } }
    }

    // sanity check that we have at least one rule
    if (z.rules.isEmpty)
      throw Err("Big problem in $z.name")

    // reverse sort by year
    z.rules.sortr |NormRule a, NormRule b->Int| { return a.startYear <=> b.startYear }
  }

  NormRule[] normalizeZoneItem(Zone z, ZoneItem item, Int? from)
  {
    // map intersection of item and rules into normalized rules
    rules := this.rules.findAll |Rule r->Bool| { return r.name == item.rule }
    norm := NormRule[,]

    // since performance isn't a big concern we just brute force
    // computation of every year to keep things simple
    startYear := from != null ? from : minYear
    endYear   := item.until != null ? item.until-1 : maxYear
    for (yr:=startYear; yr<=endYear; ++yr)
    {
      n := NormRule()
      n.startYear = yr
      n.offset    = item.offset
      n.stdAbbr   = item.format.replace("%s", "S")
      norm.add(n)

      // get the rules which apply to this year
      yrRules := rules.findAll |Rule r->Bool| { return r.includes(yr) }
      if (yrRules.isEmpty) continue

      // this happens for a couple odd cases where either the
      // item or dst is terminated without a clean year boundary;
      // need to incorporate these cases into the test suite
      if (yrRules.size == 1)
      {
        if (!yrRules[0].save.isZero)
          echo("WARNING: only one rule save != 0 for $yr $z.name $yrRules")
        continue
      }

      // we should have one or two rules for this year
      if (yrRules.size != 2)
        throw Err("Problem for year $yr $z.name: $yrRules")

      // figure out which is start and which is end, note
      // in the southern hemisphere typically fall is start
      // of daylight savings time
      a := yrRules[0]
      b := yrRules[1]
      if (a.save.isZero)
      {
        if (b.save.isZero) throw Err("Both rules zero save $z.name")
        b = yrRules[0]
        a = yrRules[1]
      }
      else
      {
        if (!b.save.isZero) throw Err("Neither rules zero save $z.name")
      }

      // start of dst
      n.dst         = true
      n.dstAbbr     = item.toAbbr(a.letter)
      n.dstStartMon = a.in
      n.dstStartOn  = a.on
      n.dstStartAt  = a.at
      n.dstOffset   = a.save

      // end of dst
      n.dstEndMon   = b.in
      n.stdAbbr     = item.toAbbr(b.letter)
      n.dstEndOn    = b.on
      n.dstEndAt    = b.at
    }

    return coalesce(z, norm)
  }

  NormRule[] coalesce(Zone z, NormRule[] rules)
  {
    rules.sortr |NormRule a, NormRule b->Int| { return a.startYear <=> b.startYear }

    result := NormRule[,]
    rules.eachr |NormRule r|
    {
      if (result.last == null || !result.last.same(r))
        result.add(r)
    }

    return result
  }

//////////////////////////////////////////////////////////////////////////
// Write Database
//////////////////////////////////////////////////////////////////////////

  **
  ** Refer to TimeZone.java for the time zone binary database format.
  **
  Void writeDatabase()
  {
    // magic "fantz 02"
    buf := Buf()
    buf.write('f').write('a').write('n').write('t')
       .write('z').write(' ').write('0').write('2')

    buf.writeUtf("\n" +
      "buildTool:adm/buildtz.fan\n" +
      "buildTime:${DateTime.now}\n" +
      "buildUser:${Env.cur.user}\n" +
      "buildHost:${Env.cur.host}\n"
    )

    // create map of all the prefix/names
    prefixes := Str:Int[:]
    names := Str:Zone[:]
    zones.each |Zone z|
    {
      prefixes[z.prefix] = 0
      if (names[z.fanName] != null)
        echo("ERROR: Duplicate simple name $z.fanName")
      else
        names[z.fanName] = z
    }

    // sort, write, assign ids to prefixes
    if (prefixes.size >= 0xff) throw Err()
    buf.write(prefixes.size)
    prefixes.keys.sort.each |Str p, Int i|
    {
      prefixes[p] = i
      buf.writeUtf(p)
    }

    // sort names and write index items
    if (prefixes.size >= 0xffff) throw Err()
    buf.writeI2(names.size)
    names.keys.sort.each |name|
    {
      z := names[name]
      buf.write(prefixes[z.prefix])
      buf.writeUtf(name)
      z.offsetPos = buf.pos
      buf.writeI4(0)
    }

    // write time zone definitions
    zones.each |Zone z|
    {
      // back patch current offset into index
      cur := buf.pos
      buf.seek(z.offsetPos).writeI4(cur)
      buf.seek(cur)

      // write time zone
      buf.writeI2(z.rules.size)
      z.rules.each |NormRule r|
      {
        buf.writeI2(r.startYear)
        buf.writeI4(r.offset.toSec)
        buf.writeUtf(r.stdAbbr)

        if (!r.dst) { buf.writeI4(0); return }

        buf.writeI4(r.dstOffset.toSec)
        buf.writeUtf(r.dstAbbr)

        buf.write(r.dstStartMon.ordinal)
        buf.write(r.dstStartOn.mode)
        buf.write(r.dstStartOn.weekday.ordinal)
        buf.write(r.dstStartOn.day)
        buf.writeI4(r.dstStartAt.toSec)
        buf.write(r.dstStartAt.wall)

        buf.write(r.dstEndMon.ordinal)
        buf.write(r.dstEndOn.mode)
        buf.write(r.dstEndOn.weekday.ordinal)
        buf.write(r.dstEndOn.day)
        buf.writeI4(r.dstEndAt.toSec)
        buf.write(r.dstEndAt.wall)
      }
    }

    // write to file
    f := devHomeDir + `etc/sys/timezones.ftz`
    log.info("Write (" + buf.size/1024 + "kb) [$f]")
    f.out.writeBuf(buf.flip).close
  }

}

**************************************************************************
** Rule
**************************************************************************

class Rule
{
  override Str toStr()
  {
    return "$name $from $to $kind $in $on $at $save $letter.toChar"
  }

  Bool includes(Int year)
  {
    if (to == null)
      return from <= year
    else
      return from <= year && year <= to
  }

  Str? name
  Int? from
  Int? to
  Str? kind
  Month? in
  OnDay? on
  AtTime? at
  AtTime? save
  Int? letter
}

**************************************************************************
** Zone
**************************************************************************

class Zone
{
  override Str toStr() { return name + "\n  " + items.join("\n  ") }

  override Int compare(Obj obj) { return name <=> obj->name }

  Str prefix()
  {
    i := name.indexr("/")
    if (i == null) return ""
    return name[0..<i]
  }

  Str fanName()
  {
    i := name.indexr("/")
    if (i == null) return name
    return name[i+1..-1]
  }

  Str zoneInfoName()
  {
    return name
  }

  Int nameCode(Str n)
  {
    if (n == fanName && n == zoneInfoName) return 3
    if (n == fanName) return 1
    return 2
  }

  Void dump()
  {
    echo(name)
    rules.each |NormRule r| { echo("  $r") }
  }

  Str? name
  ZoneItem[] items := ZoneItem[,]
  NormRule[]? rules  // normalized rules
  Int? offsetPos     // to backpatch
}

**************************************************************************
** ZoneItem
**************************************************************************

class ZoneItem
{
  override Str toStr() { return "$offset $rule $format $until" }

  Str toAbbr(Int letter)
  {
    if (letter == '-')
      return format.replace("%s", "")
    else
      return format.replace("%s", letter.toChar)
  }

  AtTime? offset
  Str? rule
  Str? format
  Int? until
}

**************************************************************************
** NormRule
**************************************************************************

class NormRule
{
  override Str toStr()
  {
    s := "$startYear $offset $stdAbbr"
    if (dst)
      s += " $dstOffset [$dstAbbr ($dstStartMon $dstStartOn $dstStartAt) to ($dstEndMon $dstEndOn $dstEndAt) +$dstOffset]"
    return s
  }

  Bool same(NormRule x)
  {
    // check everything *but* startYear so that we can use
    // this method to uniquify a list of normalized rules
    return offset      == x.offset      &&
           stdAbbr     == x.stdAbbr     &&
           dst         == x.dst         &&
           dstOffset   == x.dstOffset   &&
           dstAbbr     == x.dstAbbr     &&
           dstStartMon == x.dstStartMon &&
           dstStartOn  == x.dstStartOn  &&
           dstStartAt  == x.dstStartAt  &&
           dstEndMon   == x.dstEndMon   &&
           dstEndOn    == x.dstEndOn    &&
           dstEndAt    == x.dstEndAt
  }

  Int? startYear
  AtTime? offset
  Str? stdAbbr

  Bool? dst := false
  AtTime? dstOffset
  Str? dstAbbr

  Month? dstStartMon
  OnDay? dstStartOn
  AtTime? dstStartAt

  Month? dstEndMon
  OnDay? dstEndOn
  AtTime? dstEndAt
}

**************************************************************************
** OnDay
**   Gives the day on which the rule takes effect.
**   Recognized forms include:
**
**     'd'  5        the fifth of the month
**     'l'  lastSun  the last Sunday in the month
**     'l'  lastMon  the last Monday in the month
**     '>'  Sun>=8   first Sunday on or after the eighth
**     '<'  Sun<=25  last Sunday on or before the 25th (not used)
**
**  Names of days of the week may be abbreviated or
**  spelled out in full.  Note that there must be no
**  spaces within the ON field.
**************************************************************************

class OnDay
{
  static OnDay parse(Str s)
  {
    x := make
    x.str = s

    if (s.startsWith("last"))
    {
      x.mode = 'l'
      x.weekday = Build.toWeekday(s[4..-1])
      return x
    }

    gt := s.index(">=")
    if (gt != null)
    {
      x.mode = '>'
      x.weekday = Build.toWeekday(s[0..<gt])
      x.day = s[gt+2..-1].toInt
      return x
    }

    x.mode = 'd'
    x.day  = s.toInt
    return x
  }

  override Bool equals(Obj? obj)
  {
    x := (OnDay)obj
    return mode    == x.mode    &&
           weekday == x.weekday &&
           day     == x.day
  }

  override Str toStr() { return str }

  Str? str
  Int mode         // 'd', 'l', '>', '<'
  Weekday weekday := Weekday.sun
  Int day := 0
}

**************************************************************************
** AtTime
**   Gives the time of day at which the rule takes
**   effect.  Recognized forms include:
**
**     2        time in hours
**     2:00     time in hours and minutes
**     15:00    24-hour format time (for times after noon)
**     1:28:14  time in hours, minutes, and seconds
**     -        equivalent to 0
**
**  where hour 0 is midnight at the start of the day,
**  and hour 24 is midnight at the end of the day.  Any
**  of these forms may be followed by the letter w if
**  the given time is local "wall clock" time, s if the
**  given time is local "standard" time, or u (or g or
**  z) if the given time is universal time; in the
**  absence of an indicator, wall clock time is assumed.
**************************************************************************

class AtTime
{
  static AtTime parse(Str s)
  {
    t := make
    if (s.endsWith("w")) { s = s[0..<-1]; }
    if (s.endsWith("s")) { s = s[0..<-1]; t.wall = 's' }
    if (s.endsWith("u")) { s = s[0..<-1]; t.wall = 'u' }

    toks := s.split(':')
    t.hr = toks[0].toInt
    if (toks.size > 1)
    {
      t.min = toks[1].toInt
      if (toks.size > 2)
      {
        t.sec = toks[2].toInt
        if (toks.size > 3)
          throw ParseErr()
      }
    }
    return t
  }

  Bool isZero()
  {
    return (hr == 0  || hr == null) &&
           (min == 0 || min == null) &&
           (sec == 0 || sec == null)
  }

  Int toSec()
  {
    x := hr.abs * 3600
    if (min != null) x += min * 60
    if (sec != null) x += sec
    if (hr < 0) x = -x
    return x
  }

  override Str toStr()
  {
    if (min == null) return "$hr"
    if (sec == null) return "$hr:$min"
    return "$hr:$min:$sec"
  }

  override Bool equals(Obj? obj)
  {
    x := (AtTime)obj
    return hr   == x.hr  &&
           min  == x.min &&
           sec  == x.sec &&
           wall == x.wall
  }

  Int? hr
  Int? min
  Int? sec
  Int wall := 'w'  // 'w', 's', or 'u'
}



