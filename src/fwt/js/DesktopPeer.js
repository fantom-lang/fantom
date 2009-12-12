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
fan.fwt.DesktopPeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.fwt.DesktopPeer.prototype.$ctor = function(self) {}

fan.fwt.DesktopPeer.platform  = function() { return "browser"; }
fan.fwt.DesktopPeer.isWindows = function() { return false; }
fan.fwt.DesktopPeer.isMac     = function() { return false; }

// TODO
//fan.fwt.DesktopPeer.bounds()
//fan.fwt.DesktopPeer.focus()
//fan.fwt.DesktopPeer.callAsync(|->| f)

//////////////////////////////////////////////////////////////////////////
// Dispose
//////////////////////////////////////////////////////////////////////////

//fan.fwt.DesktopPeer.disposeColor(Color c)
//fan.fwt.DesktopPeer.disposeFont(Font f)
//fan.fwt.DesktopPeer.disposeImage(Image i)

//////////////////////////////////////////////////////////////////////////
// System Fonts
//////////////////////////////////////////////////////////////////////////

fan.fwt.DesktopPeer.sysFont = function()
{
  // TODO - grab CSS from body elem?
  return fan.fwt.DesktopPeer.$sysFont;
}

fan.fwt.DesktopPeer.sysFontMonospace = function()
{
  return fan.fwt.DesktopPeer.$sysFontMonospace;
}

fan.fwt.DesktopPeer.$sysFont = fan.gfx.Font.fromStr("10pt Arial");
fan.fwt.DesktopPeer.$sysFontMonospace = fan.gfx.Font.fromStr("9pt Courier");

//////////////////////////////////////////////////////////////////////////
// System Colors
//////////////////////////////////////////////////////////////////////////

fan.fwt.DesktopPeer.$sysDarkShadow   = fan.gfx.Color.fromStr("#909090");
fan.fwt.DesktopPeer.$sysNormShadow   = fan.gfx.Color.fromStr("#a0a0a0");
fan.fwt.DesktopPeer.$sysLightShadow  = fan.gfx.Color.fromStr("#c0c0c0");
fan.fwt.DesktopPeer.$sysHighlightShadow = fan.gfx.Color.fromStr("#e0e0e0");
fan.fwt.DesktopPeer.$sysFg           = fan.gfx.Color.fromStr("#000000");
fan.fwt.DesktopPeer.$sysBg           = fan.gfx.Color.fromStr("#ffffff");
fan.fwt.DesktopPeer.$sysBorder       = fan.gfx.Color.fromStr("#333333");
fan.fwt.DesktopPeer.$sysListFg       = fan.gfx.Color.fromStr("#000000");
fan.fwt.DesktopPeer.$sysListBg       = fan.gfx.Color.fromStr("#ffffff");
fan.fwt.DesktopPeer.$sysListSelFg    = fan.gfx.Color.fromStr("#ffffff");
fan.fwt.DesktopPeer.$sysListSelBg    = fan.gfx.Color.fromStr("#316ac5");

fan.fwt.DesktopPeer.sysDarkShadow  = function() { return fan.fwt.DesktopPeer.$sysDarkShadow; }
fan.fwt.DesktopPeer.sysNormShadow  = function() { return fan.fwt.DesktopPeer.$sysNormShadow; }
fan.fwt.DesktopPeer.sysLightShadow = function() { return fan.fwt.DesktopPeer.$sysLightShadow; }
fan.fwt.DesktopPeer.sysHighlightShadow = function() { return fan.fwt.DesktopPeer.$sysHighlightShadow; }
fan.fwt.DesktopPeer.sysFg          = function() { return fan.fwt.DesktopPeer.$sysFg; }
fan.fwt.DesktopPeer.sysBg          = function() { return fan.fwt.DesktopPeer.$sysBg; }
fan.fwt.DesktopPeer.sysBorder      = function() { return fan.fwt.DesktopPeer.$sysBorder; }
fan.fwt.DesktopPeer.sysListFg      = function() { return fan.fwt.DesktopPeer.$sysListFg; }
fan.fwt.DesktopPeer.sysListBg      = function() { return fan.fwt.DesktopPeer.$sysListBg; }
fan.fwt.DesktopPeer.sysListSelFg   = function() { return fan.fwt.DesktopPeer.$sysListSelFg; }
fan.fwt.DesktopPeer.sysListSelBg   = function() { return fan.fwt.DesktopPeer.$sysListSelBg; }

