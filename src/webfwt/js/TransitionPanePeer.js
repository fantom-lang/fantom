//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Oct 2011  Andy Frank  Creation
//

/**
 * TransitionPanePeer.
 */
fan.webfwt.TransitionPanePeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.TransitionPanePeer.prototype.$ctor = function(self) {}

/**
 * Inject CSS.
 */
fan.fwt.WidgetPeer.addCss(
  "div._webfwt_TransitionPane_ {" +
  " -webkit-perspective: 1000px;" +
  "    -moz-perspective: 1000px;" +
  "     -ms-perspective: 1000px;" +
  "         perspective: 1000px;" +
  "} " +
  "div._webfwt_TransitionPane_transition {" +
  " position:absolute;" +
  " -webkit-transform-style: preserve-3d;" +
  "    -moz-transform-style: preserve-3d;" +
  "     -ms-transform-style: preserve-3d;" +
  "         transform-style: preserve-3d;" +
  "} " +
  "div._webfwt_TransitionPane_flipFront {" +
  " -webkit-backface-visibility: hidden;" +
  "    -moz-backface-visibility: hidden;" +
  "     -ms-backface-visibility: hidden;" +
  "         backface-visibility: hidden;" +
  " -webkit-transform: translateZ(1px);" +
  "    -moz-transform: translateZ(1px);" +
  "     -ms-transform: translateZ(1px);" +
  "         transform: translateZ(1px);" +
  "} " +
  "div._webfwt_TransitionPane_flipBack {" +
  " -webkit-backface-visibility: hidden;" +
  "    -moz-backface-visibility: hidden;" +
  "     -ms-backface-visibility: hidden;" +
  "         backface-visibility: hidden;" +
  " -webkit-transform: rotateY(180deg) translateZ(1px);" +
  "    -moz-transform: rotateY(180deg) translateZ(1px);" +
  "     -ms-transform: rotateY(180deg) translateZ(1px);" +
  "         transform: rotateY(180deg) translateZ(1px);" +
  "} ");


fan.webfwt.TransitionPanePeer.prototype.create = function(parentElem, self)
{
  this.m_dur = self.m_dur.toMillis();  // cache duration
  this.m_angle = -180;

  var trans = document.createElement("div");
  trans.className = "_webfwt_TransitionPane_transition";

  var div = this.emptyDiv();
  div.className = "_webfwt_TransitionPane_";
  div.appendChild(trans);
  parentElem.appendChild(div);
  return trans;
}

fan.webfwt.TransitionPanePeer.prototype.sync = function(self)
{
  if (this.elem)
  {
    var div = this.elem.parentNode;
    div.style.width  = this.m_size.m_w + "px";
    div.style.height = this.m_size.m_h + "px";
  }
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.webfwt.TransitionPanePeer.prototype.transitionTo = function(self, w)
{
  if (self.content() == null)
    throw fan.sys.ArgErr.make("TransitionPane: must have content before transitionTo")

       if (self.m_style == "slideUp") this.doSlideUp(self, w);
  else if (self.m_style == "flip")    this.doFlip(self, w);
  else throw fan.sys.ArgErr.make("Invalid style " + self.m_style);
}

fan.webfwt.TransitionPanePeer.prototype.doSlideUp = function(self, to)
{
  var cur = self.content();
  var dur = this.m_dur;
  var w = self.size().m_w;
  var h = self.size().m_h;

  self.add(to);
  to.bounds$(fan.gfx.Rect.make(0, h, w, h));
  self.relayout();

  setTimeout(function()
  {
    var curPeer = cur.peer.elem;
    if (curPeer == null) return;  // bail if we got unmoutned
    fan.fwt.WidgetPeer.setTransition(curPeer, "all " + dur + "ms");

    var toPeer = to.peer.elem;
    fan.fwt.WidgetPeer.setTransition(toPeer, "all " + dur + "ms");

    curPeer.style.top = (-h) + "px";
    toPeer.style.top  = "0px";

    setTimeout(function()
    {
      self.content$(null);
      fan.fwt.WidgetPeer.setTransition(curPeer, "none");
      curPeer.style.top = "0px";
      fan.fwt.WidgetPeer.setTransition(toPeer, "none");
      self.m_content = to;
      self.relayout();
    }, dur);
  }, 10);
}

fan.webfwt.TransitionPanePeer.prototype.doFlip = function(self, w)
{
  // check meta
  var a = self.m_meta.get("flip.angle");
  if (a != null) this.m_angle = a;

  var front = self.content().peer.elem;
  fan.fwt.WidgetPeer.addClassName(front, "_webfwt_TransitionPane_flipFront");

  self.add(w);
  var back = w.peer.elem;
  fan.fwt.WidgetPeer.addClassName(back, "_webfwt_TransitionPane_flipBack");
  w.bounds$(self.content().bounds());
  self.relayout();

  var trans = this.elem;
  fan.fwt.WidgetPeer.setTransition(trans, "all " + this.m_dur + "ms");
  fan.fwt.WidgetPeer.setTransform(trans, "rotateY(" + this.m_angle + "deg)");
  this.m_angle = -this.m_angle;

  setTimeout(function()
  {
    fan.fwt.WidgetPeer.setTransition(trans, "none");
    fan.fwt.WidgetPeer.setTransform(trans, "none");
    fan.fwt.WidgetPeer.removeClassName(front, "_webfwt_TransitionPane_flipFront");
    fan.fwt.WidgetPeer.removeClassName(back,  "_webfwt_TransitionPane_flipBack");
    self.content$(null);
    self.m_content = w;
  }, this.m_dur);
}
