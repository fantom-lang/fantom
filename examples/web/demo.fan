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

    UriSpace.root.create(`/homePage`, scriptDir + `index.fan`)
    UriSpace.root.create(`/chrome`,   scriptDir + `chrome.fan`)

    UriSpace.mount(`/examples`, UriSpace.makeDir(scriptDir + `examples/`))
    UriSpace.mount(`/dir`, UriSpace.makeDir(scriptDir + `dir/`))
    try
      UriSpace.mount(`/doc`, UriSpace.makeDir(Sys.homeDir + `doc/`))
    catch (Err e)
      log.error("Cannot mount /doc: $e")
  }
}