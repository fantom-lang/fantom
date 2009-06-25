#! /usr/bin/env fan

using fand
using webapp
using wisp

**
** Samples for web and webapp pods.
**
class Boot : BootScript
{
  override Service[] services :=
  [
    WispService
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
    Log.addHandler(&sysLogger.writeLogRecord)

    Sys.ns.create(`/homePage`, scriptDir + `index.fan`)
    Sys.ns.create(`/chrome`,   scriptDir + `chrome.fan`)

    Sys.mount(`/examples`, Namespace.makeDir(scriptDir + `examples/`))
    Sys.mount(`/dir`, Namespace.makeDir(scriptDir + `dir/`))
    try
      Sys.mount(`/doc`, Namespace.makeDir(Sys.homeDir + `doc/`))
    catch (Err e)
      log.error("Cannot mount /doc: $e")
  }
}