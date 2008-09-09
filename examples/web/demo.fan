#! /usr/bin/env fan

using fand
using webapp
using wisp

**
** Samples for web and webapp pods.
**
class Boot : BootScript
{
  override Thread[] services :=
  [
    WispService("web")
    {
      port = 8080
      pipeline =
      [
        FindResourceStep {},
        FindViewStep {},
        FindChromeStep { chrome = `/chrome` },
        ServiceViewStep {},
        LogStep { file = scriptDir + `logs/web.log` },
      ]
    }
  ]

  override Void setup()
  {
    sysLogger := FileLogger { file = scriptDir + `logs/sys.log` }
    sysLogger.start
    Log.addHandler(&sysLogger.writeLogRecord)

    Sys.ns.create(`/homePage`, scriptDir + `index.fan`)
    Sys.ns.create(`/chrome`,   scriptDir + `chrome.fan`)

    Sys.mount(`/examples`, Namespace.makeDir(scriptDir + `examples/`))
    Sys.mount(`/dir`, Namespace.makeDir(scriptDir + `dir/`))
    Sys.mount(`/doc`, Namespace.makeDir(Sys.homeDir + `doc/`))
  }
}
