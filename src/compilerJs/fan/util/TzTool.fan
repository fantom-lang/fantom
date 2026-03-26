//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Feb 2016  Matthew Giannini  Creation
//   27 Jun 2023  Matthew Giannini  Refactor for ES
//

**
** Tool for managing JS time zones.
**
class TzTool
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Str[] args := Env.cur.args)
  {
    this.args = args
  }

  private const Str[] args

  private Log log := Log.get("TzTool")

  // gen
  private File js := Env.cur.homeDir + `etc/sys/fan_tz.js`
  private File aliasProps := Env.cur.homeDir + `etc/sys/timezone-aliases.props`
  private Str:Str aliases := [:]
  private Str:TimeZone[] byContinent := [:]

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  Void run()
  {
    parseArgs
    if (gen) generateTimeZones
  }

//////////////////////////////////////////////////////////////////////////
// Gen
//////////////////////////////////////////////////////////////////////////


  private Void generateTimeZones()
  {
    loadAliases
    orderByContinent
    writeTzJs
  }

  private Void loadAliases()
  {
    // load aliases
    if (!aliasProps.exists) log.warn("$aliasProps does not exist")
    else this.aliases = aliasProps.readProps
  }

  private Void orderByContinent()
  {
    TimeZone.listFullNames.each |fullName|
    {
      byContinent.getOrAdd(continent(fullName)) { [,] }.add(TimeZone.fromStr(fullName))
    }
    // sort time zones by city name
    byContinent.vals.each { it.sort |a,b| { a.name <=> b.name } }
  }

  ** Get the continent name from the full name, or ""
  ** if the full name doesn't have a continent.
  private Str continent(Str fullName)
  {
    fullName.contains("/") ? fullName.split('/').first : ""
  }

  private Void writeTzJs()
  {
    jsOut := js.out
    try
    {
      typeRef := this.embed ? "TimeZone" : "sys.TimeZone"
      if (!embed)
      {
        jsOut.printLine("import * as sys from './sys.js'");
      }
      jsOut.printLine("const c=${typeRef}.__cache;")

      // write built-in timezones
      byContinent.each |TimeZone[] timezones, Str continent|
      {
        timezones.each |TimeZone tz|
        {
          log.debug("$tz.fullName")
          encoded := encodeTimeZone(tz)
          jsOut.printLine("c(${tz.fullName.toCode},${encoded.toBase64.toCode});")
        }
      }

      // write aliases
      jsOut.printLine("const a=${typeRef}.__alias;")
      aliases.each |target, alias|
      {
        log.debug("Alias $alias = $target")
        jsOut.printLine("a(${alias.toCode},${target.toCode});")
      }
    }
    finally jsOut.close
    log.info("Wrote: ${js.osPath ?: js}")
  }

  private Buf encodeTimeZone(TimeZone tz)
  {
    buf   := Buf().writeUtf(tz.fullName);
    rules := ([Str:Obj][])tz->rules
    rules.each |r| { encodeRule(r, buf.out) }
    return buf
  }

  private Void encodeRule(Str:Obj r, OutStream out)
  {
    dstOffset := r["dstOffset"]
    out.writeI2(r["startYear"])
       .writeI4(r["offset"])
       .writeUtf(r["stdAbbr"])
       .writeI4(dstOffset)
    if (dstOffset != 0)
    {
      out.writeUtf(r["dstAbbr"])
      encodeDst(r["dstStart"], out)
      encodeDst(r["dstEnd"], out)
    }
  }

  private Void encodeDst(Str:Obj dst, OutStream out)
  {
    out.write(dst["mon"])
       .write(dst["onMode"])
       .write(dst["onWeekday"])
       .write(dst["onDay"])
       .writeI4(dst["atTime"])
       .write(dst["atMode"])
  }


//////////////////////////////////////////////////////////////////////////
// Args
//////////////////////////////////////////////////////////////////////////

  private Bool gen   := false
  private Bool embed := false

  private Void parseArgs()
  {
    if (args.isEmpty) usage()
    i :=0
    while (i < args.size)
    {
      arg := args[i++]
      switch (arg)
      {
        case "-gen":
          this.gen = true
        case "-embed":
          this.embed = true
        case "-outDir":
          outDir := args[i++].toUri.toFile
          if (!outDir.isDir) throw ArgErr("Not a directory: ${outDir}")
          this.js = outDir.plus(`fan_tz.js`)
        case "-silent":
          this.log.level = LogLevel.silent
        case "-verbose":
        case "-v":
          log.level = LogLevel.debug
        case "-help":
        case "-?":
          usage()
        default:
          Env.cur.err.printLine("Bad option: ${arg}")
          usage()
      }
    }
  }

  private Void usage()
  {
    out  := Env.cur.out
    main := Env.cur.mainMethod?.parent?.name ?: "TzTool"
    out.printLine(
      "Usage:
         $main [options]
       Options:
         -gen          Generate fan_tz.js
         -embed        Generate code to be embedded directly in sys.js
         -outDir       (optional) generate fan_tz.js in this directory
         -verbose, -v  Enable verbose logging
         -silent       Suppress all logging
         -help, -?     Print usage help
       ")
    Env.cur.exit(1)
  }
//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  static Void main() { TzTool().run }
}
