//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * WidgetPeer.
 */
fan.fwt.WidgetPeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.fwt.WidgetPeer.prototype.$ctor = function(self) {}

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.repaint = function(self)
{
  this.sync(self);
}

fan.fwt.WidgetPeer.prototype.relayout = function(self)
{
  // short-circuit if not mounted
  if (this.elem == null) return;

  this.sync(self);
  if (self.onLayout) self.onLayout();

  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
  {
    var kid = kids.get(i);
    kid.peer.relayout(kid);
  }

  return self;
}

fan.fwt.WidgetPeer.prototype.posOnDisplay = function(self)
{
  var x = this.m_pos.m_x;
  var y = this.m_pos.m_y;
  var p = self.parent();
  while (p != null)
  {
    if (p instanceof fan.fwt.Tab) p = p.parent();
    x += p.peer.m_pos.m_x - p.peer.elem.scrollLeft;
    y += p.peer.m_pos.m_y - p.peer.elem.scrollTop;
    if (p instanceof fan.fwt.Dialog)
    {
      var dlg = p.peer.elem.parentNode;
      x += dlg.offsetLeft;
      y += dlg.offsetTop;
    }
    p = p.parent();
  }
  return fan.gfx.Point.make(x, y);
}

fan.fwt.WidgetPeer.prototype.prefSize = function(self, hints)
{
  // cache size
  var oldw = this.elem.style.width;
  var oldh = this.elem.style.height;

  // sync and measure pref
  this.sync(self);
  this.elem.style.width  = "auto";
  this.elem.style.height = "auto";
  var pw = this.elem.offsetWidth;
  var ph = this.elem.offsetHeight;

  // restore old size
  this.elem.style.width  = oldw;
  this.elem.style.height = oldh;
  return fan.gfx.Size.make(pw, ph);
}

fan.fwt.WidgetPeer.prototype.pack = function(self)
{
  var pref = self.prefSize();
  self.size$(fan.gfx.Size.make(pref.m_w, pref.m_h));
  self.relayout();
  return self;
}

fan.fwt.WidgetPeer.prototype.enabled = function(self) { return this.m_enabled; }
fan.fwt.WidgetPeer.prototype.enabled$ = function(self, val)
{
  this.m_enabled = val;
  if (this.elem != null) this.sync(self);
}
fan.fwt.WidgetPeer.prototype.m_enabled = true;

fan.fwt.WidgetPeer.prototype.visible = function(self) { return this.m_visible; }
fan.fwt.WidgetPeer.prototype.visible$ = function(self, val) { this.m_visible = val; }
fan.fwt.WidgetPeer.prototype.m_visible = true;

fan.fwt.WidgetPeer.prototype.pos = function(self) { return this.m_pos; }
fan.fwt.WidgetPeer.prototype.pos$ = function(self, val) { this.m_pos = val; }
fan.fwt.WidgetPeer.prototype.m_pos = fan.gfx.Point.make(0,0);

fan.fwt.WidgetPeer.prototype.size = function(self) { return this.m_size; }
fan.fwt.WidgetPeer.prototype.size$ = function(self, val) { this.m_size = val; }
fan.fwt.WidgetPeer.prototype.m_size = fan.gfx.Size.make(0,0);

//////////////////////////////////////////////////////////////////////////
// Focus
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.focus = function(self)
{
}

//////////////////////////////////////////////////////////////////////////
// Attach
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.attached = function(self)
{
}

fan.fwt.WidgetPeer.prototype.attach = function(self)
{
  // short circuit if I'm already attached
  if (this.elem != null) return;

  // short circuit if my parent isn't attached
  var parent = self.m_parent;
  if (parent == null || parent.peer.elem == null) return;

  // create control and initialize
  var elem = this.create(parent.peer.elem, self);
  this.attachTo(self, elem);

  // callback on parent
  //parent.peer.childAdded(self);
}

fan.fwt.WidgetPeer.prototype.attachTo = function(self, elem)
{
  // sync to elem
  this.elem = elem;
  this.sync(self);
  this.attachEvents(self, fan.fwt.EventId.m_mouseEnter, elem, "mouseover",  self.m_onMouseEnter.list());
  this.attachEvents(self, fan.fwt.EventId.m_mouseExit,  elem, "mouseout",   self.m_onMouseExit.list());
  this.attachEvents(self, fan.fwt.EventId.m_mouseDown,  elem, "mousedown",  self.m_onMouseDown.list());
  this.attachEvents(self, fan.fwt.EventId.m_mouseMove,  elem, "mousemove",  self.m_onMouseMove.list());
  this.attachEvents(self, fan.fwt.EventId.m_mouseUp,    elem, "mouseup",    self.m_onMouseUp.list());
  //this.attachEvents(self, fan.fwt.EventId.m_mouseHover, elem, "mousehover", self.m_onMouseHover.list());
  //this.attachEvents(self, fan.fwt.EventId.m_mouseWheel, elem, "mousewheel", self.m_onMouseWheel.list());

  // recursively attach my children
  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
  {
    var kid = kids.get(i);
    kid.peer.attach(kid);
  }
}

fan.fwt.WidgetPeer.prototype.attachEvents = function(self, evtId, elem, event, list)
{
  var peer = this;
  for (var i=0; i<list.size(); i++)
  {
    var meth = list.get(i);
    var func = function(e)
    {
      // find pos relative to widget
      var dis = peer.posOnDisplay(self);
      var rel = fan.gfx.Point.make(e.clientX-dis.m_x, e.clientY-dis.m_y);

      // TODO - need to fix for IE
      // TODO - only valid for mouseDown - so need to clean up this code
      var evt = fan.fwt.Event.make();
      evt.m_id = evtId;
      evt.m_pos = rel;
      evt.m_widget = self;
      //evt.count =
      evt.m_key = fan.fwt.WidgetPeer.toKey(e);
      meth.call(evt);
      return false;
    }

    if (elem.addEventListener)
      elem.addEventListener(event, func, false);
    else
      elem.attachEvent("on"+event, func);
  }
}

fan.fwt.WidgetPeer.toKey = function(event)
{
  // find primary key
  var key = null;
  if (event.keyCode != null && event.keyCode > 0)
    key = fan.fwt.WidgetPeer.keyCodeToKey(event.keyCode);

  if (event.shiftKey)   key = key==null ? fan.fwt.Key.m_shift : key.plus(fan.fwt.Key.m_shift);
  if (event.altKey)     key = key==null ? fan.fwt.Key.m_alt   : key.plus(fan.fwt.Key.m_alt);
  if (event.ctrlKey)    key = key==null ? fan.fwt.Key.m_ctrl  : key.plus(fan.fwt.Key.m_ctrl);
  // TODO FIXIT
  //if (event.commandKey) key = key.plus(Key.command);
  return key;
}

fan.fwt.WidgetPeer.keyCodeToKey = function(keyCode)
{
  // TODO FIXIT: map rest of non-alpha keys
  switch (keyCode)
  {
    case 38: return fan.fwt.Key.m_up;
    case 40: return fan.fwt.Key.m_down;
    case 37: return fan.fwt.Key.m_left;
    case 39: return fan.fwt.Key.m_right;
    default: return fan.fwt.Key.fromMask(keyCode);
  }
}

fan.fwt.WidgetPeer.prototype.checkKeyListeners = function(self) {}

fan.fwt.WidgetPeer.prototype.create = function(parentElem, self)
{
  var div = this.emptyDiv();
  parentElem.appendChild(div);
  return div;
}

fan.fwt.WidgetPeer.prototype.emptyDiv = function()
{
  var div = document.createElement("div");
  with (div.style)
  {
    position = "absolute";
    overflow = "hidden";
    top  = "0";
    left = "0";
  }
  return div;
}

fan.fwt.WidgetPeer.prototype.detach = function(self)
{
  // recursively detach my children
  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
  {
    var kid = kids.get(i);
    kid.peer.detach(kid);
  }

  // detach myself
  var elem = self.peer.elem;
  if (elem != null)
    elem.parentNode.removeChild(elem);
  delete self.peer.elem;
}

//////////////////////////////////////////////////////////////////////////
// Widget/Element synchronization
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.sync = function(self, w, h)  // w,h override
{
  with (this.elem.style)
  {
    if (w === undefined) w = this.m_size.m_w;
    if (h === undefined) h = this.m_size.m_h;

    // TEMP fix for IE
    if (w < 0) w = 0;
    if (h < 0) h = 0;

    display = this.m_visible ? "block" : "none";
    left    = this.m_pos.m_x  + "px";
    top     = this.m_pos.m_y  + "px";
    width   = w + "px";
    height  = h + "px";
  }
}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.fontToCss = function(font)
{
  var s = "";
  if (font.m_bold)   s += "bold ";
  if (font.m_italic) s += "italic ";
  s += font.m_size + "px ";
  s += font.m_name;
  return s;
}

fan.fwt.WidgetPeer.uriToImageSrc = function(uri)
{
  if (uri.scheme() == "fan")
    return fan.sys.UriPodBase + uri.host() + uri.pathStr()
  else
    return uri.toStr();
}

fan.fwt.WidgetPeer.addCss = function(css)
{
  var style = document.createElement("style");
  style.type = "text/css";
  if (style.styleSheet) style.styleSheet.cssText = css;
  else style.appendChild(document.createTextNode(css));
  document.getElementsByTagName("head")[0].appendChild(style);
}

fan.fwt.WidgetPeer.setBg = function(elem, brush)
{
  var style = elem.style;
  if (brush == null) { style.background = "none"; return; }
  if (brush instanceof fan.gfx.Color) { style.background = brush.toCss(); return; }
  if (brush instanceof fan.gfx.Gradient)
  {
    var std    = "";  // CSS3 format
    var webkit = "";  // -webkit format

    // TODO FIXIT:
    var angle = "-90deg";

    // build pos
    std += brush.m_x1 + brush.m_x1Unit.symbol() + " " +
           brush.m_y1 + brush.m_y1Unit.symbol() + " " +
           angle;

    // try to find end-point
    webkit = brush.m_x1 + brush.m_x1Unit.symbol() + " " +
             brush.m_y1 + brush.m_y1Unit.symbol() + "," +
             brush.m_x2 + brush.m_x2Unit.symbol() + " " +
             brush.m_y2 + brush.m_y2Unit.symbol();

    // build stops
    var stops = brush.m_stops;
    for (var i=0; i<stops.size(); i++)
    {
      var stop = stops.get(i);
      var color = stop.m_color.toCss();

      // set background to first stop for fallback if gradeints not supported
      if (i == 0) background = color;

      std    += "," + color + " " + (stop.m_pos * 100) + "%";
      webkit += ",color-stop(" + stop.m_pos + ", " + color + ")";
    }

    // apply styles
    // IE throws here, so trap and use filter in catch
    try
    {
      style.background = "linear-gradient(" + std + ")";
      style.background = "-moz-linear-gradient(" + std + ")";
      style.background = "-webkit-gradient(linear, " + webkit + ")";
    }
    catch (err)
    {
      //filter = "progid:DXImageTransform.Microsoft.Gradient(" +
      //  "StartColorStr=" + c1 + ", EndColorStr=" + c2 + ")";
    }

    return;
  }
  if (brush instanceof fan.gfx.Pattern)
  {
    var str = "";
    var bg  = brush.m_bg;
    var uri = fan.fwt.WidgetPeer.uriToImageSrc(brush.m_image.m_uri);

    // bg-color
    if (bg != null) str += bg.toCss() + ' ';

    // image
    str += 'url(' + uri + ')';

    // repeat
    if (brush.m_halign == fan.gfx.Halign.m_repeat && brush.m_valign == fan.gfx.Valign.m_repeat) str += ' repeat';
    else if (brush.m_halign == fan.gfx.Halign.m_repeat) str += ' repeat-x';
    else if (brush.m_valign == fan.gfx.Valign.m_repeat) str += ' repeat-y';
    else str += ' no-repeat';

    // set style
    style.background = str;
    return;
  }
}

