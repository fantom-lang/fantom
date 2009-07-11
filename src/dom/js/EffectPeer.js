//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Apr 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//

fan.dom.EffectPeer = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

fan.dom.EffectPeer.prototype.$ctor = function(self)
{
  this.dom   = null;  // actual DOM element
  this.fan   = null;  // Fan Elem wrappaer
  this.queue = [];    // animation queue
  this.old   = {};    // stash to store old values
}

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

fan.dom.EffectPeer.prototype.elem = function(self) { return this.fan; }

//////////////////////////////////////////////////////////////////////////
// Animate
//////////////////////////////////////////////////////////////////////////

fan.dom.EffectPeer.prototype.animate = function(self, map, dur, callback, init)
{
  dur = (dur   == undefined) ? 0 : dur.toMillis();
  if (callback == undefined) callback = null;
  if (init     == undefined) init = null;
  this.queue.push({self:self, map:map, dur:dur, callback:callback, init:init})
  if (this.queue.length == 1) this.dequeue();
  return self;
}

fan.dom.EffectPeer.prototype.dequeue = function()
{
  if (this.queue.length == 0) return;
  var a = this.queue[0];
  this.doAnimate(a.self, a.map, a.dur, a.callback, a.init);
}

fan.dom.EffectPeer.prototype.doAnimate = function(self, map, dur, callback, init)
{
  if (init != null) callback = init(map, callback);
  var tweens = [];

  // collect tweens
  var keys = map.keys();
  for (var i=0; i<keys.length; i++)
  {
    var key = keys[i];
    var val = map.get(key);
    var tween = new fan.dom.Tween(self.peer, key, val);
    tweens.push(tween);
  }

  // bail if no tweens
  if (tweens.length == 0) return;

  // animate
  var start = new Date().getTime();
  var intervalId = null;
  var f = function()
  {
    var diff = new Date().getTime() - start;
    if (diff > (dur-10))
    {
      // clear timer
      clearInterval(intervalId);

      // make sure we go to the stop exactly
      for (var i=0; i<tweens.length; i++)
        tweens[i].applyVal(tweens[i].stop);

      // callback if specified
      if (callback) callback(tweens[0].fx);

      // remove from queue
      var fx = tweens[0].fx;
      fx.queue.splice(0, 1);
      if (fx.queue.length > 0) fx.dequeue();

      // don't run next frame
      return
    }

    for (var i=0; i<tweens.length; i++)
    {
      var tween = tweens[i];
      var ratio = diff / dur;
      var val = ((tween.stop-tween.start) * ratio) + tween.start;
      tween.applyVal(val);
    }
  }
  intervalId = setInterval(f, 10);
}

//////////////////////////////////////////////////////////////////////////
// Show/Hide
//////////////////////////////////////////////////////////////////////////

fan.dom.EffectPeer.prototype.show = function(self, dur, callback, doWidth)
{
  // animate width prop?
  if (doWidth == undefined) doWidth = true

  var fx = self;
  var init = function(map, callback)
  {
    var oldOpacity = fx.peer.dom.style.opacity || 1;
    var oldOverflow = fx.peer.dom.style.overflow;

    // figure out target size
    fx.peer.dom.style.opacity = "0";
    fx.peer.dom.style.display = "block";
    var w = new fan.dom.Tween(fx.peer, "width", 0).currentVal()+"px";
    var h = new fan.dom.Tween(fx.peer, "height", 0).currentVal()+"px";
    var cs = fx.peer.fan.computedStyle();

    if (doWidth)
    {
      map.set("width", w+"px");
      map.set("paddingLeft", cs.paddingLeft);
      map.set("paddingRight", cs.paddingRight);
    }
    map.set("height", h+"px");
    map.set("paddingTop", cs.paddingTop);
    map.set("paddingBottom", cs.paddingBottom);

    // set to initial pos
    with (fx.peer.dom.style)
    {
      opacity = oldOpacity;
      overflow = "hidden";
      if (doWidth)
      {
        width = "0px";
        paddingLeft  = "0px";
        paddingRight = "0px";
      }
      height = "0px";
      paddingTop = "0px";
      paddingBottom = "0px";
    }

    return function()
    {
      // reset overlow
      fx.peer.dom.style.overflow = oldOverflow;
      if (callback) callback(fx);
    }
  };
  return this.animate(self, new fan.sys.Map(), dur, callback, init);
}

fan.dom.EffectPeer.prototype.hide = function(self, dur, callback, doWidth)
{
  // animate width prop?
  if (doWidth == undefined) doWidth = true

  var fx = self;
  var init = function(map, callback)
  {
    // make sure style is set
    var cs = fx.peer.fan.computedStyle();
    var old =
    {
      overflow: fx.peer.dom.style.overflow,
      width:  new fan.dom.Tween(fx.peer, "width", 0).currentVal()+"px",
      height: new fan.dom.Tween(fx.peer, "height", 0).currentVal()+"px",
      paddingTop:    cs.paddingTop,
      paddingBottom: cs.paddingBottom,
      paddingLeft:   cs.paddingLeft,
      paddingRight:  cs.paddingRight
    };

    with (fx.peer.dom.style)
    {
      if (doWidth)
      {
        width = old.width;
        paddingLeft  = old.paddingLeft;
        paddingRight = old.paddingRight;
      }
      height        = old.height;
      paddingTop    = old.paddingTop;
      paddingBottom = old.paddingBottom;
      overflow      = "hidden";
    }

    if (doWidth)
    {
      map.set("width", "0px");
      map.set("paddingLeft", "0px");
      map.set("paddingRight", "0px");
    }
    map.set("height", "0px");
    map.set("paddingTop", "0px");
    map.set("paddingBottom", "0px");

    return function()
    {
      // reset style
      with (fx.peer.dom.style)
      {
        display  = "none";
        overflow = old.overflow;
        width    = old.width;
        height   = old.height;
        paddingTop    = old.paddingTop;
        paddingBottom = old.paddingBottom;
        paddingLeft   = old.paddingLeft;
        paddingRight  = old.paddingRight;
      }
      if (callback) callback(fx);
    }
  };
  return this.animate(self, new fan.sys.Map(), dur, callback, init);
}

//////////////////////////////////////////////////////////////////////////
// Slide
//////////////////////////////////////////////////////////////////////////

fan.dom.EffectPeer.prototype.slideDown = function(self, dur, callback)
{
  return this.show(self, dur, callback, false);
}

fan.dom.EffectPeer.prototype.slideUp = function(self, dur, callback)
{
  return this.hide(self, dur, callback, false);
}

//////////////////////////////////////////////////////////////////////////
// Fading
//////////////////////////////////////////////////////////////////////////

fan.dom.EffectPeer.prototype.fadeIn  = function(self, dur, callback) { return this.fadeTo(self, "1.0", dur, callback); }
fan.dom.EffectPeer.prototype.fadeOut = function(self, dur, callback) { return this.fadeTo(self, "0.0", dur, callback); }
fan.dom.EffectPeer.prototype.fadeTo  = function(self, opacity, dur, callback)
{
  var map = new fan.sys.Map();
  map.set("opacity", opacity);
  return this.animate(self, map, dur, callback);
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

fan.dom.EffectPeer.prototype.sync = function(elem)
{
  this.fan = elem;
  this.dom = elem.peer.elem;
}

//////////////////////////////////////////////////////////////////////////
// Tween
//////////////////////////////////////////////////////////////////////////

fan.dom.Tween = function(fx, prop, stop)
{
  this.fx   = fx;      // the Effect instance
  this.elem = fx.dom;  // the DOM element to tween
  this.prop = prop;    // CSS prop name

  var css = this.fromCss(stop);
  this.start = this.currentVal();  // start value
  this.stop  = css.val;            // stop value
  this.unit  = css.unit;           // the CSS for the value
}

fan.dom.Tween.prototype.currentVal = function()
{
  switch (this.prop)
  {
    case "width":
      var val = this.elem.offsetWidth;
      val -= this.pixelVal("paddingLeft") + this.pixelVal("paddingRight");
      val -= this.pixelVal("borderLeftWidth") + this.pixelVal("borderRightWidth");
      return val;

    case "height":
      val = this.elem.offsetHeight;
      val -= this.pixelVal("paddingTop") + this.pixelVal("paddingBottom");
      val -= this.pixelVal("borderTopWidth") + this.pixelVal("borderBottomWidth");
      return val;

    case "paddingTop":    return this.pixelVal("paddingTop");
    case "paddingBottom": return this.pixelVal("paddingBottom");
    case "paddingLeft":   return this.pixelVal("paddingLeft");
    case "paddingRight":  return this.pixelVal("paddingRight");

    default:
      val = this.fx.old[this.prop];
      if (val != undefined) return val;

      val = this.elem.style[this.prop];
      if (val != undefined && val != "") return this.fromCss(val);

      if (this.prop == "opacity") return 1;
      return 0;
  }
}

fan.dom.Tween.prototype.pixelVal = function(prop)
{
  var cs = this.fx.fan.computedStyle();
  var val = cs[prop];

  // IE does not return pixel values all the time for
  // computed style, so we need to convert to pixels
  //
  // From Dean Edward:
  // http://erik.eae.net/archives/2007/07/27/18.54.15/#comment-102291

  // if already a pixel just return
  if (/^\d+(.\d+)?(px)?$/i.test(val)) return parseFloat(val);

  // stash style
  var olds  = this.elem.style.left;
  var oldrs = this.elem.runtimeStyle.left;

  // convert to pix
// TODO - this doesn't work with borderWidth (val=medium)
try {
  this.elem.runtimeStyle.left = this.elem.currentStyle.left;
  this.elem.style.left = val || 0;
  val = this.elem.style.pixelLeft;
}
catch (err) { val = 0; /*alert(err);*/ }

  // restore style
  this.elem.style.left = olds;
  this.elem.runtimeStyle.left = oldrs;
  return val;
}

fan.dom.Tween.prototype.applyVal = function(val)
{
  // make sure we never go past stop
  if (this.start<this.stop) { if (val>this.stop) val=this.stop; }
  else { if (val<this.stop) val=this.stop; }

  // apply
  switch (this.prop)
  {
    case "opacity":
      this.elem.style.opacity = val;
      this.elem.style.filter = "alpha(opacity=" + parseInt(val*100) + ")";
      this.fx.old.opacity = val;
      break;

    default:
      if (!isNaN(val)) this.elem.style[this.prop] = val + (this.unit || "");
      break;
  }
}

fan.dom.Tween.prototype.fromCss = function(css)
{
  if (css == "") return { val:0, unit:null };
  var val  = parseFloat(css);
  var unit = null;
  if      (fan.sys.Str.endsWith(css, "%"))  unit = "%";
  else if (fan.sys.Str.endsWith(css, "px")) unit = "px";
  else if (fan.sys.Str.endsWith(css, "em")) unit = "em";
  return { val:val, unit:unit, toString:function(){return val+unit} };
}

fan.dom.Tween.prototype.toString = function()
{
  return "[elem:" + this.elem.tagName + "," +
          "prop:" + this.prop + "," +
          "start:" + this.start + "," +
          "stop:" + this.stop + "," +
          "unit:" + this.unit + "]";
}