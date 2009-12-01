#! /usr/bin/env fan

using util
using web
using webmod
using wisp

**
** Samples for web and webmod pods.
**
class Boot : AbstractMain
{
  @opt="http port"
  Int port := 8080

  override Void run()
  {
    // create log dir is it doesn't exist
    logDir := homeDir + `demo/logs/`
    if (!logDir.exists) logDir.create

    // install sys log handler
    sysLogger := FileLogger { file = logDir + `sys.log` }
    Log.addHandler |rec| { sysLogger.writeLogRecord(rec) }

    // check if doc directory exists
    docDir := Repo.boot.home + `doc/`
    if (!docDir.exists) docDir = homeDir + `demo/`

    // configure our web pipeline
    pipeline := PipelineMod
    {
      // pipeline steps
      steps =
      [
        RouteMod
        {
          routes =
          [
            "index": FileMod { file = homeDir + `demo/index.html` },
            "flag":  FileMod { file = `fan:/sys/pod/icons/x32/flag.png`.get },
            "doc":   FileMod { file = docDir },
            "logs":  FileMod { file = logDir },
            "dump":  TestMod("dump"),
          ]
        }
      ]

      // steps to run after every request
      after =
      [
        LogMod { file = logDir + `web.log` }
      ]
    }

    // run WispService
    runServices([ WispService { it.port = this.port; root = pipeline } ])
  }
}

const class TestMod : WebMod
{
  new make(Str name) { this.name = name }
  const Str name
  override Str toStr() { "DumpMod $name" }
  override Void onGet()
  {
    s := req.session
    res.cookies.add(Cookie("foo", "a,b,c"))
    res.cookies.add(Cookie("bar", "some \"quoted\" text!"))
    res.cookies.add(Cookie("baz", "xy;zfoo;".toBuf.toBase64))
    if (s["testcounter"] == 10) s.delete

    res.statusCode = 200
    res.headers["Content-Type"] = "text/html"
    res.out.printLine("<a href='/'>Index</a> |")
    res.out.printLine("<a href='/dump'>/dump</a> |")
    res.out.printLine("<a href='/dump/'>/dump/</a> |")
    res.out.printLine("<a href='/dump/a'>/dump/a</a> |")
    res.out.printLine("<a href='/dump/a/b'>/dump/a/b</a> |")
    res.out.printLine("<pre>")
    res.out.printLine("uri:       $req.uri")
    res.out.printLine("absUri:    $req.absUri")
    res.out.printLine("mod:       $req.mod")
    res.out.printLine("modBase:   $req.modBase")
    res.out.printLine("modRel:    $req.modRel")
    res.out.printLine("version:   $req.version")
    res.out.printLine("method:    $req.method")
    res.out.printLine("stash:     $req.stash")
    res.out.printLine("cookies:   $req.cookies")
    res.out.printLine("  foo:     " + req.cookies["foo"])
    res.out.printLine("  bar:     " + req.cookies["bar"])
    res.out.printLine("  baz:     " + Buf.fromBase64(req.cookies.get("baz", "")).readAllStr)
    res.out.printLine("headers:")
    req.headers.each |Str v, Str k| { res.out.printLine("  $k: $v") }
    res.out.printLine("session:   $req.session.id")
    req.session.map.each |Obj? v, Str k| { res.out.printLine("  $k: $v") }
    res.out.printLine("</pre>")

    s["testcounter"] = (Int)s.map.get("testcounter", 0) + 1
    s["foobar"] = "hi there"
  }
}