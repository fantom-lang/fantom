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
** See [pod doc]`pod-doc#webmod`.
**
abstract const class WebMod : Weblet
{

  **
  ** Initialization callback when web server is started.
  **
  virtual Void onStart() {}

  **
  ** Cleanup callback when web server is stoppped.
  **
  virtual Void onStop() {}

}