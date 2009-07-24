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
fan.fwt.FwtEnvPeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.fwt.FwtEnvPeer.prototype.$ctor = function(self) {}

//////////////////////////////////////////////////////////////////////////
// Images
//////////////////////////////////////////////////////////////////////////

fan.fwt.FwtEnvPeer.imgCache = [];
fan.fwt.FwtEnvPeer.imgCacheNextMemId = 1;

fan.fwt.FwtEnvPeer.nextMemUriStr = function()
{
  return fan.sys.Uri.fromStr("mem-" + (++fan.fwt.FwtEnvPeer.imgCacheNextMemId));
}

fan.fwt.FwtEnvPeer.loadImage = function(fanImg, widget)
{
  var uri = fanImg.uri.toStr();
  var jsImg = fan.fwt.FwtEnvPeer.imgCache[uri]
  if (!jsImg)
  {
    jsImg = document.createElement("img");
    if (widget != null)
    {
      var onload = function()
      {
        // TODO - easiest and most reliable is to relayout
        // whole window - but might be better to queue relayouts
        // depending on how native browser optimizes reflows
        widget.window().relayout();
      }
      if (jsImg.addEventListener)
        jsImg.onload = onload;
      // TODO - not seeing this needed yet in IE8...
      //else
      //  jsImg.attachEvent('onload', onload);
    }
    jsImg.src = uri;
    fan.fwt.FwtEnvPeer.imgCache[uri] = jsImg;
  }
  return jsImg
}

// Size imageSize(Image img)
fan.fwt.FwtEnvPeer.prototype.imageSize = function(self, fanImg)
{
  var jsImg = fan.fwt.FwtEnvPeer.loadImage(fanImg)
  return fan.gfx.Size.make(jsImg.width, jsImg.height)
}

// Image imageResize(Image img, Size size)
fan.fwt.FwtEnvPeer.prototype.imageResize = function(self, fanImg, size)
{
  // generate a unique uri as the key for the new image
  var uri = fan.fwt.FwtEnvPeer.nextMemUriStr();
  uri = fan.fwt.FwtEnvPeer.nextMemUriStr();

  // get the original js image
  var jsOrig = fan.fwt.FwtEnvPeer.loadImage(fanImg)
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
  fan.fwt.FwtEnvPeer.imgCache[uri] = jsNew;

  // create new Fan wrapper which references jsNew via uri
  return fan.gfx.Image.makeUri(fan.sys.Uri.fromStr(uri));
}

//////////////////////////////////////////////////////////////////////////
// Font
//////////////////////////////////////////////////////////////////////////

// global variable to store a CanvasRenderingContext2D
fan.fwt.FwtEnvPeer.fontCx = null;

fan.fwt.FwtEnvPeer.prototype.fontHeight = function(self, font)
{
  // fudge this as 150% of size
  return font.size * 1.5
}

fan.fwt.FwtEnvPeer.prototype.fontAscent = function(self, font)
{
  // fudge this as 100% of size
  return font.size
}

fan.fwt.FwtEnvPeer.prototype.fontDescent = function(self, font)
{
  // fudge this as 30% of size
  return font.size * 0.3
}

fan.fwt.FwtEnvPeer.prototype.fontLeading = function(self, font)
{
  // fudge this as 16% of size
  return font.size * 0.16
}

fan.fwt.FwtEnvPeer.prototype.fontWidth = function(self, font, str)
{
  try
  {
    // use global var to store a context for computing string width
    if (fan.fwt.FwtEnvPeer.fontCx == null)
    {
      fan.fwt.FwtEnvPeer.fontCx = document.createElement("canvas").getContext("2d");
    }
    fan.fwt.FwtEnvPeer.fontCx.font = font.toStr()
    return fan.fwt.FwtEnvPeer.fontCx.measureText(str).width;
  }
  catch (err)
  {
    // fallback if canvas not supported
    return str.length * 7;
  }
}

