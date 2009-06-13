//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Jun 09  Andy Frank  Creation
//

/**
 * FwtEnvPeer.
 */
var fwt_FwtEnvPeer = sys_Obj.$extend(sys_Obj);
fwt_FwtEnvPeer.prototype.$ctor = function(self) {}

//FwtEnvPeer.prototype.imageSize(Image i)
//FwtEnvPeer.prototype.imageResize(Image i, Size s)

// global variable to store a CanvasRenderingContext2D
fwt_FwtEnvPeer.fontCx = null;

fwt_FwtEnvPeer.prototype.fontHeight = function(self, font)
{
  // fudge this as 150% of size
  return font.size * 1.5
}

fwt_FwtEnvPeer.prototype.fontAscent = function(self, font)
{
  // fudge this as 100% of size
  return font.size
}

fwt_FwtEnvPeer.prototype.fontDescent = function(self, font)
{
  // fudge this as 30% of size
  return font.size * 0.3
}

fwt_FwtEnvPeer.prototype.fontLeading = function(self, font)
{
  // fudge this as 16% of size
  return font.size * 0.16
}

fwt_FwtEnvPeer.prototype.fontWidth = function(self, font, str)
{
  try
  {
    // use global var to store a context for computing string width
    if (fwt_FwtEnvPeer.fontCx == null)
    {
      fwt_FwtEnvPeer.fontCx = document.createElement("canvas").getContext("2d");
    }
    fwt_FwtEnvPeer.fontCx.font = font.toStr()
    return fwt_FwtEnvPeer.fontCx.measureText(str).width;
  }
  catch (err)
  {
    // fallback if canvas not supported
    return str.length * 7;
  }
}

