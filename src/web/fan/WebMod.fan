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

  **
  ** Create WebOutStream from socket output stream to use for 'WebRes.out'.
  ** This method is call on the current WebMod during the response commit.
  **
  @NoDoc virtual WebOutStream? makeResOut(OutStream out)
  {
    cout := WebUtil.makeContentOutStream(res.headers, out)
    if (cout == null) return null
    return WebOutStream(cout)
  }

}