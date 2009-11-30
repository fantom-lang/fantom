//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 08  Brian Frank  Creation
//

**
** WebMod defines a web modules which is plugged into a
** web server's URI namespace to service web requests.
**
** See [docLib::Web]`docLib::Web`
**
abstract const class WebMod : Weblet
{

  **
  ** Initialization callback.
  **
  virtual Void onStart() {}

  **
  ** Cleanup callback.
  **
  virtual Void onStop() {}

}