#! /usr/bin/env fan

using util
using web
using webmod
using wisp
using compiler

**
** Samples for web and webmod pods.
**
class Boot : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  override Int run()
  {
    // create log dir if it doesn't exist
    logDir := homeDir + `demo/logs/`
    if (!logDir.exists) logDir.create

    // install sys log handler
    sysLogger := FileLogger { dir = logDir; filename = "sys.log" }
    Log.addHandler |rec| { sysLogger.writeLogRec(rec) }

    // check if doc directory exists
    docDir := Env.cur.homeDir + `doc/`
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
            "index":  FileMod { file = homeDir + `demo/index.html` },
            "flag":   FileMod { file = `fan://icons/x32/flag.png`.get },
            "doc":    FileMod { file = docDir },
            "logs":   FileMod { file = logDir },
            "upload": ScriptMod { file = homeDir + `demo/upload.fan` },
            "dump":   ScriptMod { file = homeDir + `demo/dump.fan` },
          ]
        }
      ]

      // steps to run after every request
      after =
      [
        LogMod { dir = logDir; filename = "web.log" }
      ]
    }

    // run WispService
    return runServices([ WispService { it.port = this.port; root = pipeline } ])
  }
}

**
** Shows how to load a WebMod from a script file which
** is re-compiled on the fly every time it changes.
**
const class ScriptMod : WebMod
{
  new make(|This|? f) { f?.call(this) }
  const File? file
  override Void onService()
  {
    errLog := Buf()
    try
    {
      t := Env.cur.compileScript(file, ["logOut":errLog.out])
      t.make->onService
    }
    catch (CompilerErr e)
    {
      e.trace
      res.headers["Content-Type"] = "text/plain"
      res.out.print(errLog.flip.readAllStr)
    }
  }
}

