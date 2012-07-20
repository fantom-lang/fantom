//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Oct 2010  Andy Frank  Creation
//

//////////////////////////////////////////////////////////////////////////
// TextPanePeer
//////////////////////////////////////////////////////////////////////////

fan.webfwt.TextPanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.TextPanePeer.prototype.$ctor = function(self)
{
  fan.fwt.PanePeer.prototype.$ctor.call(this, self);
  this.needsRebuild = true;
}

fan.webfwt.TextPanePeer.prototype.m_text = "";
fan.webfwt.TextPanePeer.prototype.text = function(self) { return this.m_text; }
fan.webfwt.TextPanePeer.prototype.text$ = function(self,val)
{
  this.needsRebuild = true;
  this.m_text = val;
}

fan.webfwt.TextPanePeer.prototype.create = function(parentElem, self)
{
  var div = this.emptyDiv();
  with (div.style)
  {
    background = "white";
    border = "1px solid #9f9f9f";
    overflow = "auto";
  }
  var pre = document.createElement("pre");
  with (pre.style)
  {
    font = fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFontMonospace);
    margin = "0px";
    padding = "6px";
  }
  div.appendChild(pre);
  parentElem.appendChild(div);
  return div;
}

fan.webfwt.TextPanePeer.prototype.prefSize = function(self, hints)
{
  return fan.fwt.WidgetPeer.prototype.prefSize.call(this, self, hints);
}

fan.webfwt.TextPanePeer.prototype.sync = function(self)
{
  // sync text
  if (this.needsRebuild)
  {
    var pre = this.elem.firstChild;
    while (pre.firstChild) pre.removeChild(pre.firstChild);
    pre.appendChild(document.createTextNode(this.m_text));
    this.needsRebuild = false;
    this.elem.scrollTop = 0;
    this.elem.scrollLeft = 0;
  }

  // account for border
  var w = this.m_size.m_w - 2;
  var h = this.m_size.m_h - 2;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}

fan.webfwt.TextPanePeer.prototype.scrollToTop = function(self, dur)
{
  if (this.elem == null) return;

  var div  = this.elem;
  var ms   = dur.toMillis();

  if (div.offsetHeight > div.scrollHeight) return self;
  if (ms < 10) { div.scrollTop=0; return self }

  var diff = div.scrollTop;
  var dt   = ms / 10;
  var dy   = Math.floor(diff / dt);

  var f = function()
  {
    if (div.scrollTop <= dy) div.scrollTop = 0;
    else { div.scrollTop -= dy; setTimeout(f, 10); }
  }
  f();

  return self;
}

fan.webfwt.TextPanePeer.prototype.scrollToBottom = function(self, dur)
{
  if (this.elem == null) return;

  var div  = this.elem;
  var ms   = dur.toMillis();

  if (div.offsetHeight > div.scrollHeight) return self;
  if (ms < 10) { div.scrollTop=div.scrollHeight; return self; }

  var diff = div.scrollHeight - div.scrollTop;
  var dt   = ms / 10;
  var dy   = Math.floor(diff / dt);
  var last = -1;

  var f = function()
  {
    if ((last == div.scrollTop) || (div.scrollHeight - div.scrollTop <= dy))
    {
      div.scrollTop = div.scrollHeight;
    }
    else
    {
      div.scrollTop += dy;
      last = div.scrollTop;
      setTimeout(f, 10);
    }
  }
  f();

  return self;
}

