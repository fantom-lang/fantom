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

// attach global event handlers
window.addEventListener("load", function() {
  window.addEventListener("mousemove", fan.fwt.WidgetPeer.onWinMouseMove, false);
  window.addEventListener("mouseup",   fan.fwt.WidgetPeer.onWinMouseUp,   false);
}, false);

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

fan.fwt.WidgetPeer.prototype.posOnWindow = function(self)
{
  var x = this.m_pos.m_x;
  var y = this.m_pos.m_y;
  var p = self.parent();
  while (p != null)
  {
    if (p instanceof fan.fwt.Tab) p = p.parent();
    if (p.peer.elem == undefined) { p = p.parent(); continue; }
    x += p.peer.m_pos.m_x - p.peer.elem.scrollLeft;
    y += p.peer.m_pos.m_y - p.peer.elem.scrollTop;
    if (p instanceof fan.fwt.Dialog)
    {
      var dlg = p.peer.elem.parentNode;
      x += dlg.offsetLeft;
      y += dlg.offsetTop;
      break; // dialogs are always relative to Window origin
    }
    p = p.parent();
  }
  return fan.gfx.Point.make(x, y);
}

fan.fwt.WidgetPeer.prototype.posOnDisplay = function(self)
{
  // find pos relative to window
  var pos = this.posOnWindow(self);
  var win = self.window();
  if (win != null && win.peer.root != null)
  {
    // find position of window relative to display
    var elem = win.peer.root;
    var x = 0, y = 0;
    do
    {
      x += elem.offsetLeft - elem.scrollLeft;
      y += elem.offsetTop - elem.scrollTop;
    }
    while(elem = elem.offsetParent);
    if (x != 0 || y != 0)
      return fan.gfx.Point.make(pos.m_x + x, pos.m_y + y);
  }
  return pos;
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

fan.fwt.WidgetPeer.prototype.m_enabled = true;
fan.fwt.WidgetPeer.prototype.enabled = function(self) { return this.m_enabled; }
fan.fwt.WidgetPeer.prototype.enabled$ = function(self, val)
{
  if (this.m_enabled == val) return;

  this.m_enabled = val;

  // propagate down widget tree
  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
    kids.get(i).enabled$(val);

  if (this.elem != null) this.sync(self);
}

fan.fwt.WidgetPeer.prototype.m_visible = true;
fan.fwt.WidgetPeer.prototype.visible = function(self) { return this.m_visible; }
fan.fwt.WidgetPeer.prototype.visible$ = function(self, val) { this.m_visible = val; }

fan.fwt.WidgetPeer.prototype.m_$defCursor = "auto";
fan.fwt.WidgetPeer.prototype.m_cursor = null;
fan.fwt.WidgetPeer.prototype.cursor = function(self) { return this.m_cursor; }
fan.fwt.WidgetPeer.prototype.cursor$ = function(self, val)
{
  this.m_cursor = val;
  if (this.elem != null)
  {
    this.elem.style.cursor = val != null
      ? fan.fwt.WidgetPeer.cursorToCss(val)
      : this.m_$defCursor;
  }
}

fan.fwt.WidgetPeer.prototype.m_pos = fan.gfx.Point.make(0,0);
fan.fwt.WidgetPeer.prototype.pos = function(self) { return this.m_pos; }
fan.fwt.WidgetPeer.prototype.pos$ = function(self, val) { this.m_pos = val; }

fan.fwt.WidgetPeer.prototype.m_size = fan.gfx.Size.make(0,0);
fan.fwt.WidgetPeer.prototype.size = function(self) { return this.m_size; }
fan.fwt.WidgetPeer.prototype.size$ = function(self, val) { this.m_size = val; }

//////////////////////////////////////////////////////////////////////////
// Focus
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.focus = function(self)
{
  if (this.elem != null) this.elem.focus();
}

fan.fwt.WidgetPeer.prototype.hasFocus = function(self)
{
  return this.elem != null && this.elem === document.activeElement;
}

fan.fwt.WidgetPeer.prototype.$fireFocus = function(self)
{
  var evt = fan.fwt.Event.make();
  evt.m_id = fan.fwt.EventId.m_focus;
  evt.m_widget = self;

  var list = self.onFocus().list();
  for (var i=0; i<list.m_size; i++)
  {
    list.get(i).call(evt);
    if (evt.m_consumed) break;
  }
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
  self.cursor$(this.m_cursor);
  elem.addEventListener("focus", function() { fan.fwt.Desktop.m_focus=self; }, false);

  // callback on parent
  //parent.peer.childAdded(self);
}

fan.fwt.WidgetPeer.prototype.attachTo = function(self, elem)
{
  // sync to elem
  this.elem = elem;
  this.sync(self);

  // recursively attach my children
  var kids = self.m_kids;
  for (var i=0; i<kids.size(); i++)
  {
    var kid = kids.get(i);
    kid.peer.attach(kid);
  }
}

fan.fwt.WidgetPeer.prototype.checkKeyListeners = function(self) {}
fan.fwt.WidgetPeer.prototype.checkFocusListeners = function(self) {}

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
  self.peer.eventMask = 0;
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
  // sync event handlers
  this.checkEventListener(self, 0x001, "mouseover",  fan.fwt.EventId.m_mouseEnter, self.onMouseEnter());
  this.checkEventListener(self, 0x002, "mouseout",   fan.fwt.EventId.m_mouseExit,  self.onMouseExit());
  this.checkEventListener(self, 0x004, "mousedown",  fan.fwt.EventId.m_mouseDown,  self.onMouseDown());
  this.checkEventListener(self, 0x008, "mousemove",  fan.fwt.EventId.m_mouseMove,  self.onMouseMove());
  this.checkEventListener(self, 0x010, "mouseup",    fan.fwt.EventId.m_mouseUp,    self.onMouseUp());
//this.checkEventListener(self, 0x020, "mousehover", fan.fwt.EventId.m_mouseHover, self.onMouseHover());
  this.checkEventListener(self, 0x040, "mousewheel", fan.fwt.EventId.m_mouseWheel, self.onMouseWheel());
  this.checkEventListener(self, 0x080, "keydown",    fan.fwt.EventId.m_keyDown,    self.onKeyDown());
  this.checkEventListener(self, 0x100, "keyup",      fan.fwt.EventId.m_keyUp,      self.onKeyUp());
  this.checkEventListener(self, 0x200, "blur",       fan.fwt.EventId.m_blur,       self.onBlur());
  this.checkEventListener(self, 0x400, "focus",      fan.fwt.EventId.m_focus,      self.onFocus());

  // sync bounds
  with (this.elem.style)
  {
    if (w === undefined) w = this.m_size.m_w
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

fan.fwt.WidgetPeer.prototype.checkEventListener = function(self, mask, type, evtId, listeners)
{
  if (this.eventMask == null) this.eventMask = 0;  // verify defined
  if ((this.eventMask & mask) > 0) return;         // already added
  if (listeners.isEmpty()) return;                 // nothing to add yet

  // attach and mark attached
  this.attachEventListener(self, type, evtId, listeners);
  this.eventMask |= mask;
}

//////////////////////////////////////////////////////////////////////////
// EventListeners
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.attachEventListener = function(self, type, evtId, listeners)
{
  var peer = this;
  var func = function(e)
  {
    // find pos relative to display
    var dis  = peer.posOnDisplay(self);
    var mx   = e.clientX - dis.m_x;
    var my   = e.clientY - dis.m_y;

    // cache event type
    var isClickEvent = evtId == fan.fwt.EventId.m_mouseDown ||
                       evtId == fan.fwt.EventId.m_mouseUp;
    var isWheelEvent = evtId == fan.fwt.EventId.m_mouseWheel;
    var isMouseEvent = type.indexOf("mouse") != -1;

    // create fwt::Event and invoke handler
    var evt = fan.fwt.Event.make();
    evt.m_$target = e.target;
    evt.m_id      = evtId;
    evt.m_pos     = fan.gfx.Point.make(mx, my);
    evt.m_widget  = self;
    evt.m_$peer   = peer;
    evt.m_key     = fan.fwt.WidgetPeer.toKey(e);
    if (isClickEvent)
    {
      evt.m_button = e.button + 1;
      evt.m_count  = fan.fwt.WidgetPeer.processMouseClicks(peer, evt);
    }
    if (isWheelEvent)
    {
      evt.m_button = 1;  // always set to middle button?
      evt.m_delta = fan.fwt.WidgetPeer.toWheelDelta(e);
    }

    // special handling for mouseup events outside of element
    if (type == "mousedown")    fan.fwt.WidgetPeer.$curMouseDown = evt;
    else if (type == "mouseup") fan.fwt.WidgetPeer.$curMouseDown = null;

    // invoke handlers
    var list = listeners.list();
    for (var i=0; i<list.m_size; i++)
    {
      list.get(i).call(evt);
      if (evt.m_consumed) break;
    }

    // prevent bubbling
    if (evt.m_consumed || isMouseEvent) e.stopPropagation();
    if (evt.m_consumed) e.preventDefault();
    return false;
  }

  // special handler for firefox
  if (type == "mousewheel" && fan.fwt.DesktopPeer.$isFirefox) type = "DOMMouseScroll";

  // add tabindex for key events
  if (type == "keydown" || type == "keyup") this.elem.tabIndex = 0;

  // attach event handler
  this.elem.addEventListener(type, func, false);
}

fan.fwt.WidgetPeer.onWinMouseMove = function(e)
{
  var evt = fan.fwt.WidgetPeer.$curMouseDown
  if (evt)
  {
    try
    {
      // update pos relative to display
      var dis   = evt.m_$peer.posOnDisplay(evt.m_widget);
      var mx    = e.clientX - dis.m_x;
      var my    = e.clientY - dis.m_y;
      evt.m_id  = fan.fwt.EventId.m_mouseMove;
      evt.m_pos = fan.gfx.Point.make(mx, my);
      var list = evt.m_widget.onMouseMove().list();
      for (var i=0; i<list.m_size; i++)
      {
        list.get(i).call(evt);
        if (evt.m_consumed) break;
      }
    }
    catch (err)
    {
      // assume didn't get cleaned up
      fan.fwt.WidgetPeer.$curMouseDown = null;
    }
  }
}

fan.fwt.WidgetPeer.onWinMouseUp = function(e)
{
  var evt = fan.fwt.WidgetPeer.$curMouseDown
  if (evt)
  {
    evt.m_id = fan.fwt.EventId.m_mouseUp;
    //evt.m_pos = fan.gfx.Point.make(mx, my);   // what do we send here?
    //evt.m_key = fan.fwt.WidgetPeer.toKey(e);
    var list = evt.m_widget.onMouseUp().list();
    for (var i=0; i<list.m_size; i++)
    {
      list.get(i).call(evt);
      if (evt.m_consumed) break;
    }
  }
}

fan.fwt.WidgetPeer.processMouseClicks = function(peer, e)
{
  // init mouse clicks if not defined
  if (peer.mouseClicks == null)
  {
    peer.mouseClicks = {
      last: new Date().getTime(),
      pos:  e.m_pos,
      cur:  1
    };
    return peer.mouseClicks.cur;
  }

  // only process on mousedown
  if (e.m_id != fan.fwt.EventId.m_mouseDown)
    return peer.mouseClicks.cur;

  // verify pos and frequency
  var now  = new Date().getTime();
  var diff = now - peer.mouseClicks.last;
  if (diff < 600 && peer.mouseClicks.pos.equals(e.m_pos))
  {
    // increment click count
    peer.mouseClicks.cur++;
  }
  else
  {
    // reset handler
    peer.mouseClicks.pos = e.m_pos;
    peer.mouseClicks.cur = 1;
  }

  // update ts and return result
  peer.mouseClicks.last = now;
  return peer.mouseClicks.cur;
}

fan.fwt.WidgetPeer.toWheelDelta = function(e)
{
  var wx = 0;
  var wy = 0;

  if (e.wheelDeltaX != null)
  {
    // WebKit
    wx = -e.wheelDeltaX;
    wy = -e.wheelDeltaY;

    // Safari
    if (fan.fwt.DesktopPeer.$isMac)
    {
      if (wx % 120 == 0) wx = wx / 40;
      if (wy % 120 == 0) wy = wy / 40;
    }
  }
  else if (e.wheelDelta != null)
  {
    // IE
    wy = -e.wheelDelta;
  }
  else if (e.detail != null)
  {
    // Firefox
    wx = e.axis == 1 ? (e.detail * 40) : 0;
    wy = e.axis == 2 ? (e.detail * 40) : 0;
  }

  // make sure we have ints and return
  wx = wx > 0 ? Math.ceil(wx) : Math.floor(wx);
  wy = wy > 0 ? Math.ceil(wy) : Math.floor(wy);
  return fan.gfx.Point.make(wx, wy);
}

fan.fwt.WidgetPeer.toKey = function(event)
{
  // find primary key
  var key = null;
  if (event.keyCode != null && event.keyCode > 0)
  {
    // force alpha keys to lowercase so we map correctly
    var code = event.keyCode;
    if (code >= 65 && code <= 90) code += 32;
    key = fan.fwt.WidgetPeer.keyCodeToKey(code);
  }

  if (event.shiftKey) key = key==null ? fan.fwt.Key.m_shift : key.plus(fan.fwt.Key.m_shift);
  if (event.altKey)   key = key==null ? fan.fwt.Key.m_alt   : key.plus(fan.fwt.Key.m_alt);
  if (event.ctrlKey)  key = key==null ? fan.fwt.Key.m_ctrl  : key.plus(fan.fwt.Key.m_ctrl);
  if (event.metaKey)  key = key==null ? fan.fwt.Key.m_command : key.plus(fan.fwt.Key.m_command);

  // TODO FIXIT: never let key be null - so if key not
  // mapped use dummy fallback (that hopefully no one uses...)
  if (key == null) key = fan.fwt.Key.m_numLock;

  return key;
}

fan.fwt.WidgetPeer.keyCodeToKey = function(keyCode)
{
  // TODO FIXIT: map rest of non-alpha keys
  switch (keyCode)
  {
    case 8:   return fan.fwt.Key.m_backspace;
    case 13:  return fan.fwt.Key.m_enter;
    case 32:  return fan.fwt.Key.m_space;
    case 37:  return fan.fwt.Key.m_left;
    case 38:  return fan.fwt.Key.m_up;
    case 39:  return fan.fwt.Key.m_right;
    case 40:  return fan.fwt.Key.m_down;
    case 46:  return fan.fwt.Key.m_$delete;
    case 91:  return fan.fwt.Key.m_command;  // left cmd
    case 93:  return fan.fwt.Key.m_command;  // right cmd
    case 186: return fan.fwt.Key.m_semicolon;
    case 188: return fan.fwt.Key.m_comma;
    case 190: return fan.fwt.Key.m_period;
    case 191: return fan.fwt.Key.m_slash;
    case 192: return fan.fwt.Key.m_backtick;
    case 219: return fan.fwt.Key.m_openBracket;
    case 220: return fan.fwt.Key.m_backSlash;
    case 221: return fan.fwt.Key.m_closeBracket;
    case 222: return fan.fwt.Key.m_quote;
    default: return fan.fwt.Key.fromMask(keyCode);
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
  s += font.m_$name;
  return s;
}

fan.fwt.WidgetPeer.cursorToCss = function(cursor)
{
  // predefined cursor
  var img = cursor.m_image;
  if (img == null) return cursor.toStr();

  // image cursor
  var s = "url(" + fan.fwt.WidgetPeer.uriToImageSrc(img.m_uri) + ")";
  s += " " + cursor.m_x;
  s += " " + cursor.m_y;
  s += ", auto";
  return s
}

fan.fwt.WidgetPeer.insetsToCss = function(insets)
{
  var s = "";
  s += insets.m_top + "px ";
  s += insets.m_right + "px ";
  s += insets.m_bottom + "px ";
  s += insets.m_left + "px";
  return s;
}

fan.fwt.WidgetPeer.uriToImageSrc = function(uri)
{
  if (uri.scheme() == "fan")
    return fan.sys.UriPodBase + uri.host() + uri.pathStr()
  else if (uri.pathStr().indexOf("mem-") == 0)
    return fan.fwt.FwtEnvPeer.imgCache[uri.toStr()].src
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

// disable focus outlines on div.tabIndex elements
fan.fwt.WidgetPeer.addCss("div:focus { outline:0; }");

fan.fwt.WidgetPeer.hasClassName = function(elem, className)
{
  var arr = elem.className.split(" ");
  for (var i=0; i<arr.length; i++)
    if (arr[i] == className)
      return true;
  return false;
}

fan.fwt.WidgetPeer.addClassName = function(elem, className)
{
  if (!fan.fwt.WidgetPeer.hasClassName(elem, className))
    elem.className += elem.className == "" ? className : " " + className;
  return elem;
}

fan.fwt.WidgetPeer.removeClassName = function(elem, className)
{
  var arr = elem.className.split(" ");
  for (var i=0; i<arr.length; i++)
    if (arr[i] == className)
    {
      arr.splice(i, 1);
      break;
    }
  elem.className = arr.join(" ");
  return elem;
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
      if (i == 0) style.background = color;

      std    += "," + color + " " + (stop.m_pos * 100) + "%";
      webkit += ",color-stop(" + stop.m_pos + ", " + color + ")";
    }

    // apply styles
    style.background = "-ms-linear-gradient(" + std + ")";
    style.background = "-moz-linear-gradient(" + std + ")";
    style.background = "-webkit-gradient(linear, " + webkit + ")";
    style.background = "linear-gradient(" + std + ")";

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

fan.fwt.WidgetPeer.setBorder = function(elem, border)
{
  var s = elem.style;
  var b = border;
  if (b == null) { s.border = "none"; return; }
  s.borderStyle = "solid";

  s.borderTopWidth    = b.m_widthTop    + "px";
  s.borderRightWidth  = b.m_widthRight  + "px";
  s.borderBottomWidth = b.m_widthBottom + "px";
  s.borderLeftWidth   = b.m_widthLeft   + "px";

  s.borderTopColor    = b.m_colorTop.toCss();
  s.borderRightColor  = b.m_colorRight.toCss();
  s.borderBottomColor = b.m_colorBottom.toCss();
  s.borderLeftColor   = b.m_colorLeft.toCss();

  if (s.borderRadius != undefined)
  {
    s.borderTopLeftRadius     = b.m_radiusTopLeft + "px";
    s.borderTopRightRadius    = b.m_radiusTopRight + "px";
    s.borderBottomRightRadius = b.m_radiusBottomRight + "px";
    s.borderBottomLeftRadius  = b.m_radiusBottomLeft + "px";
  }
  else if (s.MozBorderRadius != undefined)
  {
    s.MozBorderRadiusTopleft     = b.m_radiusTopLeft + "px";
    s.MozBorderRadiusTopright    = b.m_radiusTopRight + "px";
    s.MozBorderRadiusBottomright = b.m_radiusBottomRight + "px";
    s.MozBorderRadiusBottomleft  = b.m_radiusBottomLeft + "px";
  }
  else if (s.webkitBorderRadius != undefined)
  {
    s.webkitBorderTopLeftRadius     = b.m_radiusTopLeft + "px";
    s.webkitBorderTopRightRadius    = b.m_radiusTopRight + "px";
    s.webkitBorderBottomRightRadius = b.m_radiusBottomRight + "px";
    s.webkitBorderBottomLeftRadius  = b.m_radiusBottomLeft + "px";
  }
}

fan.fwt.WidgetPeer.applyStyle = function(elem, map)
{
  if (map == null) return;
  map.$each(function(b) { elem.style.setProperty(b.key, b.val, ""); });
}

// set the transition CSS for elem
fan.fwt.WidgetPeer.setTransition = function(elem, css)
{
  elem.style.webkitTransition = css;
  elem.style.MozTransition    = css;
  elem.style.msTransition     = css;
  elem.style.transition       = css;
}

// set the transform CSS for elem
fan.fwt.WidgetPeer.setTransform = function(elem, css)
{
  elem.style.webkitTransform = css;
  elem.style.MozTransform    = css;
  elem.style.msTransform     = css;
  elem.style.transform       = css;
}
