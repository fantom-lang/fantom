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
  var uri = fanImg.m_uri;
  var key = uri.toStr();
  var jsImg = fan.fwt.FwtEnvPeer.imgCache[key]
  if (!jsImg)
  {
    jsImg = document.createElement("img");
    if (widget != null)
    {
      var onload = function()
      {
        // mark that we need relayout
        var win = widget.window()
        if (win != null)
        {
          fan.fwt.FwtEnvPeer.$win = win;
          fan.fwt.FwtEnvPeer.$needRelayout = true;
        }
        else if (fan.frescoKit)
        {
          // TODO FIXIT: some base class for Window/Dialog/Popup???
          var p = widget;
          while (p != null)
          {
            if (p instanceof fan.frescoKit.Popup) break;
            p = p.parent();
          }
          if (p instanceof fan.frescoKit.Popup)
          {
            fan.fwt.FwtEnvPeer.$win = p;
            fan.fwt.FwtEnvPeer.$needRelayout = true;
          }
        }
      }
      if (jsImg.addEventListener)
        jsImg.onload = onload;
      // TODO - not seeing this needed yet in IE8...
      //else
      //  jsImg.attachEvent('onload', onload);
    }
    jsImg.src = fan.fwt.WidgetPeer.uriToImageSrc(uri);
    fan.fwt.FwtEnvPeer.imgCache[key] = jsImg;
  }
  return jsImg
}

// Relayout handling for async image loading
fan.fwt.FwtEnvPeer.$win = null;
fan.fwt.FwtEnvPeer.$needRelayout = false;
fan.fwt.FwtEnvPeer.$checkRelayout = function()
{
  if (!fan.fwt.FwtEnvPeer.$needRelayout) return;
  if (fan.fwt.FwtEnvPeer.$win == null) return;
  fan.fwt.FwtEnvPeer.$needRelayout = false;
  fan.fwt.FwtEnvPeer.$win.relayout();
}
setInterval(fan.fwt.FwtEnvPeer.$checkRelayout, 50);

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

  // get the original js image
  var jsOrig = fan.fwt.FwtEnvPeer.loadImage(fanImg)
  if (jsOrig.width == 0 || jsOrig.height == 0) return fanImg;
  if (jsOrig.width == size.m_w && jsOrig.height == size.m_h) return fanImg

  // create new js image which is resized version of the old by painting
  // to temp canvas, then converting into data URL used to create new image
  var canvas = document.createElement("canvas");
  canvas.width = size.m_w;
  canvas.height = size.m_h;
  var cx = canvas.getContext("2d");
  cx.drawImage(jsOrig, 0, 0, jsOrig.width, jsOrig.height, 0, 0, size.m_w, size.m_h);
  var dataUrl = canvas.toDataURL("image/png");
  var jsNew = document.createElement("img");
  jsNew.src = dataUrl;

  // put new image into the image with our auto-gen uri key
  fan.fwt.FwtEnvPeer.imgCache[uri] = jsNew;

  // create new Fan wrapper which references jsNew via uri
  return fan.gfx.Image.makeUri(uri);
}

// Image imagePaint(Size size, |Graphics| f)
fan.fwt.FwtEnvPeer.prototype.imagePaint = function(self, size, f)
{
  // generate a unique uri as the key for the new image
  var uri = fan.fwt.FwtEnvPeer.nextMemUriStr();

  // create temp canvas
  var canvas = document.createElement("canvas");
  canvas.width = size.m_w;
  canvas.height = size.m_h;

  // paint image content on the canvas
  var g = new fan.fwt.Graphics();
  g.paint(canvas, fan.gfx.Rect.make(0, 0, size.m_w, size.m_h), function() { f.call(g) })

  // create new image based on canvas content
  var dataUrl = canvas.toDataURL("image/png");
  var jsNew = document.createElement("img");
  jsNew.src = dataUrl;

  // put new image into the image with our auto-gen uri key
  fan.fwt.FwtEnvPeer.imgCache[uri] = jsNew;

  // create new Fan wrapper which references jsNew via uri
  return fan.gfx.Image.makeUri(uri);
}

//////////////////////////////////////////////////////////////////////////
// Font
//////////////////////////////////////////////////////////////////////////

// global variable to store a CanvasRenderingContext2D
fan.fwt.FwtEnvPeer.fontCx = null;

fan.fwt.FwtEnvPeer.prototype.fontHeight = function(self, font)
{
  // fudge this as 150% of size
  return Math.round((font.m_size-3) * 1.5);
}

fan.fwt.FwtEnvPeer.prototype.fontAscent = function(self, font)
{
  // fudge this as 100% of size
  return font.m_size-3
}

fan.fwt.FwtEnvPeer.prototype.fontDescent = function(self, font)
{
  // fudge this as 30% of size
  return Math.round((font.m_size-3) * 0.3);
}

fan.fwt.FwtEnvPeer.prototype.fontLeading = function(self, font)
{
  // fudge this as 16% of size
  return Math.round((font.m_size-3) * 0.16);
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
    fan.fwt.FwtEnvPeer.fontCx.font = fan.fwt.WidgetPeer.fontToCss(font);
    return fan.fwt.FwtEnvPeer.fontCx.measureText(str).width;
  }
  catch (err)
  {
    // fallback if canvas not supported
    return str.length * 7;
  }
}

