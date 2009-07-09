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

fwt_DesktopPeer.$sysDarkShadow   = gfx_Color.fromStr("#909090");
fwt_DesktopPeer.$sysNormShadow   = gfx_Color.fromStr("#a0a0a0");
fwt_DesktopPeer.$sysLightShadow  = gfx_Color.fromStr("#c0c0c0");
fwt_DesktopPeer.$sysHighlightShadow = gfx_Color.fromStr("#e0e0e0");
fwt_DesktopPeer.$sysFg           = gfx_Color.fromStr("#000000");
fwt_DesktopPeer.$sysBg           = gfx_Color.fromStr("#ffffff");
fwt_DesktopPeer.$sysBorder       = gfx_Color.fromStr("#333333");
fwt_DesktopPeer.$sysListFg       = gfx_Color.fromStr("#000000");
fwt_DesktopPeer.$sysListBg       = gfx_Color.fromStr("#ffffff");
fwt_DesktopPeer.$sysListSelFg    = gfx_Color.fromStr("#ffffff");
fwt_DesktopPeer.$sysListSelBg    = gfx_Color.fromStr("#316ac5");

fwt_DesktopPeer.sysDarkShadow  = function() { return fwt_DesktopPeer.$sysDarkShadow; }
fwt_DesktopPeer.sysNormShadow  = function() { return fwt_DesktopPeer.$sysNormShadow; }
fwt_DesktopPeer.sysLightShadow = function() { return fwt_DesktopPeer.$sysLightShadow; }
fwt_DesktopPeer.sysHighlightShadow = function() { return fwt_DesktopPeer.$sysHighlightShadow; }
fwt_DesktopPeer.sysFg          = function() { return fwt_DesktopPeer.$sysFg; }
fwt_DesktopPeer.sysBg          = function() { return fwt_DesktopPeer.$sysBg; }
fwt_DesktopPeer.sysBorder      = function() { return fwt_DesktopPeer.$sysBorder; }
fwt_DesktopPeer.sysListFg      = function() { return fwt_DesktopPeer.$sysListFg; }
fwt_DesktopPeer.sysListBg      = function() { return fwt_DesktopPeer.$sysListBg; }
fwt_DesktopPeer.sysListSelFg   = function() { return fwt_DesktopPeer.$sysListSelFg; }
fwt_DesktopPeer.sysListSelBg   = function() { return fwt_DesktopPeer.$sysListSelBg; }

