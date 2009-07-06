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

//////////////////////////////////////////////////////////////////////////
// Images
//////////////////////////////////////////////////////////////////////////

fwt_FwtEnvPeer.imgCache = [];
fwt_FwtEnvPeer.imgCacheNextMemId = 1;

fwt_FwtEnvPeer.nextMemUriStr = function()
{
  return sys_Uri.fromStr("mem-" + (++fwt_FwtEnvPeer.imgCacheNextMemId));
}

fwt_FwtEnvPeer.loadImage = function(fanImg, widget)
{
  var uri = fanImg.uri.toStr();
  var jsImg = fwt_FwtEnvPeer.imgCache[uri]
  if (!jsImg)
  {
    jsImg = document.createElement("img");
    if (widget != null)
    {
      var onload = function()
      {
        // TODO - super inefficient - but only way I could reliabily
        // force things to relayout correctly so far
        var w = widget;
        while (w != null)
        {
          w.relayout();
          w = w.parent;
        }
      }
      if (jsImg.addEventListener)
        jsImg.onload = onload;
      // TODO - not seeing this needed yet in IE8...
      //else
      //  jsImg.attachEvent('onload', onload);
    }
    jsImg.src = uri;
    fwt_FwtEnvPeer.imgCache[uri] = jsImg;
  }
  return jsImg
}

// Size imageSize(Image img)
fwt_FwtEnvPeer.prototype.imageSize = function(self, fanImg)
{
  var jsImg = fwt_FwtEnvPeer.loadImage(fanImg)
  return gfx_Size.make(jsImg.width, jsImg.height)
}

// Image imageResize(Image img, Size size)
fwt_FwtEnvPeer.prototype.imageResize = function(self, fanImg, size)
{
  // generate a unique uri as the key for the new image
  var uri = fwt_FwtEnvPeer.nextMemUriStr();
  uri = fwt_FwtEnvPeer.nextMemUriStr();

  // get the original js image
  var jsOrig = fwt_FwtEnvPeer.loadImage(fanImg)
  if (jsOrig.width == size.w && jsOrig.height == size.h) return fanImg

  // create new js image which is resized version of the old by painting
  // to temp canvas, then converting into data URL used to create new image
  var canvas = document.createElement("canvas");
  canvas.width = size.w;
  canvas.height = size.h;
  var cx = canvas.getContext("2d");
  cx.drawImage(jsOrig, 0, 0, jsOrig.width, jsOrig.height, 0, 0, size.w, size.h);
  var dataUrl = canvas.toDataURL("image/png");
  var jsNew = document.createElement("img");
  jsNew.src = dataUrl;

  // put new image into the image with our auto-gen uri key
  fwt_FwtEnvPeer.imgCache[uri] = jsNew;

  // create new Fan wrapper which references jsNew via uri
  return gfx_Image.makeUri(sys_Uri.fromStr(uri));
}

//////////////////////////////////////////////////////////////////////////
// Font
//////////////////////////////////////////////////////////////////////////

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

