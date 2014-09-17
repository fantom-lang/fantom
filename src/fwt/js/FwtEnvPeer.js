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
        else
        {
          var p = widget;
          while (p != null)
          {
            if (p.peer.notifyImgLoad) break;
            p = p.parent();
          }
          if (p != null && p.peer.notifyImgLoad)
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
  return fan.gfx.Image.makeFields(uri, null);
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
  var g = new fan.fwt.FwtGraphics();
  g.paint(canvas, fan.gfx.Rect.make(0, 0, size.m_w, size.m_h), function() { f.call(g) })

  // create new image based on canvas content
  var dataUrl = canvas.toDataURL("image/png");
  var jsNew = document.createElement("img");
  jsNew.src = dataUrl;

  // put new image into the image with our auto-gen uri key
  fan.fwt.FwtEnvPeer.imgCache[uri] = jsNew;

  // create new Fan wrapper which references jsNew via uri
  return fan.gfx.Image.makeFields(uri, null);
}

// Void imageDispose(Image i)
fan.fwt.FwtEnvPeer.prototype.imageDispose = function(self, img)
{
  // remove image from cache to allow GC free it
  fan.fwt.FwtEnvPeer.imgCache[img.m_uri.toStr()] = null
}

//////////////////////////////////////////////////////////////////////////
// Font
//////////////////////////////////////////////////////////////////////////

// global variable to store a CanvasRenderingContext2D
fan.fwt.FwtEnvPeer.fontCx = null;

// adjust font size roughly from pt to px
fan.fwt.FwtEnvPeer.$ptToPx = function(ptSize)
{
  switch (ptSize)
  {
    case 6: return 8;
    case 7: return 9;
    case 8: return 11;
    case 9: return 12;
    case 10: return 13;
    case 11: return 15;
    case 12: return 16;
    case 13: return 17;
    case 14: return 19;
    case 15: return 21;
    case 16: return 22;
    case 17: return 23;
    case 18:
    case 19:
      // fall-through
      return 24;
    case 20:
    case 21:
      // fall-through
      return 26;
    case 22:
    case 23:
      // fall-through
      return 29;
    case 24:
    case 25:
      // fall-through
      return 32;
    case 26: return 35;
    case 27: return 36;
    case 28: return 37;
    case 29: return 38;
    case 30:
    case 31:
      // fall-through
      return 40;
    case 32:
    case 33:
      // fall-through
      return 42;
    case 34:
    case 35:
      // fall-through
      return 45;
    case 36: return 48;
    default: return ptSize + 8
  }
}

fan.fwt.FwtEnvPeer.prototype.fontHeight = function(self, font)
{
  return fan.fwt.FwtEnvPeer.$ptToPx(font.m_size);
}

fan.fwt.FwtEnvPeer.prototype.fontAscent = function(self, font)
{
  // fudge
  var px = fan.fwt.FwtEnvPeer.$ptToPx(font.m_size);
  return Math.ceil(px * 0.68);
}

fan.fwt.FwtEnvPeer.prototype.fontDescent = function(self, font)
{
  // fudge
  var px = fan.fwt.FwtEnvPeer.$ptToPx(font.m_size);
  return Math.ceil(px * 0.08);
}

fan.fwt.FwtEnvPeer.prototype.fontLeading = function(self, font)
{
  // fudge
  var px = fan.fwt.FwtEnvPeer.$ptToPx(font.m_size);
  return Math.ceil(px * 0.01);
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
    return Math.ceil(fan.fwt.FwtEnvPeer.fontCx.measureText(str).width);
  }
  catch (err)
  {
    // fallback if canvas not supported
    return str.length * 7;
  }
}

fan.fwt.FwtEnvPeer.prototype.fontDispose = function(self, font) {}

//////////////////////////////////////////////////////////////////////////
// Color
//////////////////////////////////////////////////////////////////////////

fan.fwt.FwtEnvPeer.prototype.colorDispose = function(self, font) {}
