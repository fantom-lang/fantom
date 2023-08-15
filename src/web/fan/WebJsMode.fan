//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 2023  Brian Frank  Creation
//

using concurrent

**
** WebJsMode is a global variable used to switch between serving up
** classic prototyped-based vs class-based ECMA JavaScript in FilePack
** and WebOutStream.  The intention is that this global variable is
** only used during the transition period to provide side-by-side support.
**
**
@Js @NoDoc enum class WebJsMode
{
  ** Classic prototype-based JavaScript native model
  js,

  ** New class-based JavaScript native model
  es

  ** Is mode the new class-based model
  Bool isEs() { this === es }

  ** Current global mode
  static WebJsMode cur() { curRef.val }

  ** Set global mode - this should be once at startup before web pages
  ** are setup and not changed again since it may introduce race condtions.
  static Void setCur(WebJsMode cur) { curRef.val = cur }

  ** Global variable
  private static const AtomicRef curRef := AtomicRef(WebJsMode.js)
}