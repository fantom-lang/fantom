//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Sep 10  Andy Frank  Creation
//

fan.webfwt.SlidePanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.SlidePanePeer.prototype.$ctor = function(self)
{
  fan.fwt.PanePeer.prototype.$ctor.call(this, self);
}

fan.webfwt.SlidePanePeer.prototype.create = function(parentElem, self)
{
  var div = this.emptyDiv();
  var sub = this.emptyDiv();
  sub.style.webkitTransition = "left 200ms ease-in";
  sub.style.MozTransition    = "left 200ms ease-in";
  div.appendChild(sub);
  parentElem.appendChild(div);
  return sub;
}

fan.webfwt.SlidePanePeer.prototype.sync = function(self)
{
  var slide  = this.elem;
  var parent = slide.parentNode;

  var w = this.m_size.m_w;
  var h = this.m_size.m_h;

  with (parent.style)
  {
    display = this.m_visible ? "block" : "none";
    left    = this.m_pos.m_x  + "px";
    top     = this.m_pos.m_y  + "px";
    width   = w + "px";
    height  = h + "px";
  }

  with (slide.style)
  {
    left    = -(self.m_cur * w) + "px";
    top     = "0px"
    width   = (self.children().size() * w) + "px";
    height  = h + "px";
  }
}


