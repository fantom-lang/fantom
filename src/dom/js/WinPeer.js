//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

fan.dom.WinPeer = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.$ctor = function(self) {}

fan.dom.WinPeer.cur = function()
{
  if (fan.dom.WinPeer.$cur == null) fan.dom.WinPeer.$cur = fan.dom.Win.make();
  return fan.dom.WinPeer.$cur;
}

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.doc = function(self)
{
  if (this.$doc == null) this.$doc = fan.dom.Doc.make();
  return this.$doc;
}

fan.dom.WinPeer.prototype.alert = function(self, obj)
{
  alert(obj);
}

fan.dom.WinPeer.prototype.viewport = function(self)
{
  return fan.gfx.Size.make(window.innerWidth, window.innerHeight);
}

//////////////////////////////////////////////////////////////////////////
// Uri
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.uri = function(self)
{
  return fan.sys.Uri.decode(window.location.toString());
}

fan.dom.WinPeer.prototype.hyperlink = function(self, uri)
{
  window.location = uri.encode();
}

fan.dom.WinPeer.prototype.reload  = function(self, force)
{
  window.location.reload(force);
}

//////////////////////////////////////////////////////////////////////////
// EventTarget
//////////////////////////////////////////////////////////////////////////

fan.dom.WinPeer.prototype.onEvent = function(self, type, useCapture, handler)
{
  if (this.elem.addEventListener)
  {
    this.elem.addEventListener(type, function(e) {
      handler(fan.dom.Event.make(e));
    }, useCapture);
  }
  else
  {
    this.elem.attachEvent('on'+type, function(e) {
      handler(fan.dom.Event.make(e));
    });
  }
}

