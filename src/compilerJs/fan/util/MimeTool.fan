//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 20  Matthew Giannini  Creation
//

**
** Tool for managing JS MIME types
**
class MimeTool
{
  new make() { }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Log log := Log.get("MimeTool")

  private const File js := Env.cur.homeDir + `etc/sys/mime.js`
  private const File ext2mime := Env.cur.homeDir + `etc/sys/ext2mime.props`

  private Bool gen := false
  private Str:Str byExt := [:]

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  Void run()
  {
    parseArgs
    if (gen) generateMime
  }

  private Void generateMime()
  {
    loadExt2Mime
    writeMimeJs
  }

  private Void loadExt2Mime()
  {
    if (!ext2mime.exists) log.err("$ext2mime does not exist")
    else this.byExt = ext2mime.readProps
  }

  private Void writeMimeJs()
  {
    jsOut := js.out
    try
    {
      jsOut.printLine(
        "(function() {
          ${JsPod.requireSys}
          var c=fan.sys.MimeType.cache\$;
          ")

      byExt.each |mime, ext|
      {
        log.debug("$ext = $mime")
        jsOut.printLine("c($ext.toCode,$mime.toCode);")
        // m       := MimeType.fromStr(mime)
        // charset := m.params["charset"]
        // jsOut.print("c($ext.toCode,$m.mediaType.toCode,$m.subType.toCode")
        // if (charset != null) jsOut.print(",\"charset=${charset.lower}\"")
        // jsOut.printLine(");")
      }

      jsOut.printLine("}).call(this);")
    }
    finally jsOut.flush.close
    log.info("Wrote: ${js.osPath ?: js}")
  }

//////////////////////////////////////////////////////////////////////////
// Args
//////////////////////////////////////////////////////////////////////////

  private Void parseArgs()
  {
    args := Env.cur.args.dup.reverse
    if (args.isEmpty) usage()
    while (!args.isEmpty)
    {
      arg := args.pop
      switch (arg)
      {
        case "-gen":
          this.gen = true
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
    main := Env.cur.mainMethod?.parent?.name ?: "MimeTool"
    out.printLine(
      "Usage:
         $main [options]
       Options:
         -gen          Generate mime.js
         -verbose, -v  Enable verbose logging
         -help, -?     Print usage help
       ")
    Env.cur.exit(1)
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  static Void main()
  {
    MimeTool().run
  }
}