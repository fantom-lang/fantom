//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * DesktopPeer.
 */
var fwt_DesktopPeer = sys_Obj.$extend(sys_Obj);
fwt_DesktopPeer.prototype.$ctor = function(self) {}

fwt_DesktopPeer.platform  = function() { return "browser"; }
fwt_DesktopPeer.isWindows = function() { return false; }
fwt_DesktopPeer.isMac     = function() { return false; }

// TODO
//fwt_DesktopPeer.bounds()
//fwt_DesktopPeer.focus()
//fwt_DesktopPeer.callAsync(|,| f)

//////////////////////////////////////////////////////////////////////////
// Dispose
//////////////////////////////////////////////////////////////////////////

//fwt_DesktopPeer.disposeColor(Color c)
//fwt_DesktopPeer.disposeFont(Font f)
//fwt_DesktopPeer.disposeImage(Image i)

//////////////////////////////////////////////////////////////////////////
// System Fonts
//////////////////////////////////////////////////////////////////////////

fwt_DesktopPeer.sysFont = function()
{
  // TODO - grab CSS from body elem?
  return fwt_DesktopPeer.$sysFont;
}

fwt_DesktopPeer.sysFontMonospace = function()
{
  return fwt_DesktopPeer.$sysFontMonospace;
}

fwt_DesktopPeer.$sysFont = gfx_Font.fromStr("10pt Arial");
fwt_DesktopPeer.$sysFontMonospace = gfx_Font.fromStr("9pt Courier");

//////////////////////////////////////////////////////////////////////////
// System Colors
//////////////////////////////////////////////////////////////////////////

//fwt_DesktopPeer.sysDarkShadow()
//fwt_DesktopPeer.sysNormShadow()
//fwt_DesktopPeer.sysLightShadow()
//fwt_DesktopPeer.sysHighlightShadow()
//fwt_DesktopPeer.sysFg()
//fwt_DesktopPeer.sysBg()
//fwt_DesktopPeer.sysBorder()

//fwt_DesktopPeer.sysListFg()
//fwt_DesktopPeer.sysListBg()
//fwt_DesktopPeer.sysListSelFg()
//fwt_DesktopPeer.sysListSelBg()

