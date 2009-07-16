//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 09  Brian Frank  Creation
//

/**
 * CanvasPeer.
 */
fan.fwt.CanvasPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.CanvasPeer.prototype.$ctor = function(self) {}

fan.fwt.CanvasPeer.prototype.create = function(parentElem)
{
  // test for native canvas support
  this.hasCanvas = document.createElement("canvas").getContext != null;
  return fan.fwt.WidgetPeer.prototype.create.call(this, parentElem);
}

fan.fwt.CanvasPeer.prototype.sync = function(self)
{
  // short-circuit if not properly layed out
  if (this.size.w == 0 || this.size.h == 0) return;

  if (this.hasCanvas)
  {
    // remove existing elements
    var div = this.elem;
    while (div.firstChild != null) div.removeChild(div.firstChild);

    // create new canvas element in my div
    var c = document.createElement("canvas");
    var size = this.size
    c.width  = size.w;
    c.height = size.h;
    div.appendChild(c);

    // repaint canvas using Canvas.onPaint callback
    var g = new fan.fwt.Graphics()
    g.cx = c.getContext("2d");
    g.cx.lineWidth = 1;
    g.cx.lineCap = "square";
    g.cx.textBaseline = "top";
    g.cx.font = fan.fwt.DesktopPeer.$sysFont.toStr();
    self.onPaint(g);
  }
  else
  {
    if (this.fxLoaded == true)
    {
      // find applet tag
      var app = document.getElementById("app");
      if (app != null && this.size.w > 0 && this.size.h > 0)
      {
        app.width  = this.size.w;
        app.height = this.size.h;

        var g = new JfxGraphics(app.script);
        app.script.init();
        self.onPaint(g);
        app.script.commit();
      }
    }
    else
    {
      this.fxLoaded = true;
      var s = javafxString({
        codebase: fan.sys.UriPodBase + "fwt/res/javafx/",
        archive: "Canvas.jar",
        draggable: true,
        width:  200,
        height: 200,
        code: "fan.fwt.Canvas",
        name: "Canvas",
        id: "app"
      });
      this.elem.innerHTML = s;
    }
  }

  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

