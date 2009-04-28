//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Apr 09  Andy Frank  Creation
//

sys_Type.addType("webappClient::Effect");
var webappClient_Effect = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  $ctor: function()
  {
    this.queue = new Array();
    this.old = new Object();
  },
  type: function() { return sys_Type.find("webappClient::Effect"); },
  toStr: function() { return "effect[" + this.fan + "]"; },

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  elem: function() { return this.fan; },

//////////////////////////////////////////////////////////////////////////
// Animate
//////////////////////////////////////////////////////////////////////////

  animate: function(map, dur, callback, init)
  {
    dur = (dur   == undefined) ? 0 : dur.toMillis();
    if (callback == undefined) callback = null;
    if (init     == undefined) init = null;
    this.queue.push({map:map, dur:dur, callback:callback, init:init})
    if (this.queue.length == 1) this.dequeue();
  },

  dequeue: function()
  {
    if (this.queue.length == 0) return;
    var a = this.queue[0];
    this.doAnimate(a.map, a.dur, a.callback, a.init);
  },

  doAnimate: function(map, dur, callback, init)
  {
    if (init != null) callback = init(map, callback);
    var tweens = [];

    // collect tweens
    var keys = map.keys();
    for (var i=0; i<keys.length; i++)
    {
      var key = keys[i];
      var val = map.get(key);
      var tween = new webappClient_Tween(this, key, val);
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
  },

//////////////////////////////////////////////////////////////////////////
// Show/Hide
//////////////////////////////////////////////////////////////////////////

  show: function(dur, callback, doWidth)
  {
    // animate width prop?
    if (doWidth == undefined) doWidth = true

    var fx = this;
    var init = function(map, callback)
    {
      var oldOpacity = fx.dom.style.opacity || 1;
      var oldOverflow = fx.dom.style.overflow;

      // figure out target size
      fx.dom.style.opacity = "0";
      fx.dom.style.display = "block";
      var w = new webappClient_Tween(fx, "width", 0).currentVal()+"px";
      var h = new webappClient_Tween(fx, "height", 0).currentVal()+"px";
      var cs = fx.fan.computedStyle();

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
      with (fx.dom.style)
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
        fx.dom.style.overflow = oldOverflow;
        if (callback) callback(fx);
      }
    };
    this.animate(new sys_Map(), dur, callback, init);
  },

  hide: function(dur, callback, doWidth)
  {
    // animate width prop?
    if (doWidth == undefined) doWidth = true

    var fx = this;
    var init = function(map, callback)
    {
      // make sure style is set
      var cs = fx.fan.computedStyle();
      var old =
      {
        overflow: fx.dom.style.overflow,
        width:  new webappClient_Tween(fx, "width", 0).currentVal()+"px",
        height: new webappClient_Tween(fx, "height", 0).currentVal()+"px",
        paddingTop:    cs.paddingTop,
        paddingBottom: cs.paddingBottom,
        paddingLeft:   cs.paddingLeft,
        paddingRight:  cs.paddingRight
      };

      with (fx.dom.style)
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
        with (fx.dom.style)
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
    this.animate(new sys_Map(), dur, callback, init);
  },

//////////////////////////////////////////////////////////////////////////
// Slide
//////////////////////////////////////////////////////////////////////////

  slideDown: function(dur, callback) { this.show(dur, callback, false); },
  slideUp:   function(dur, callback) { this.hide(dur, callback, false); },

//////////////////////////////////////////////////////////////////////////
// Fading
//////////////////////////////////////////////////////////////////////////

  fadeIn:  function(dur, callback) { this.fadeTo("1.0", dur, callback); },
  fadeOut: function(dur, callback) { this.fadeTo("0.0", dur, callback); },
  fadeTo:  function(opacity, dur, callback)
  {
    var map = new sys_Map();
    map.set("opacity", opacity);
    this.animate(map, dur, callback);
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  fan: null,    // Fan Elem wrappaer
  dom: null,    // actual DOM element
  queue: null,  // animation queue
  old: null     // stash to store old values

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

webappClient_Effect.make = function(elem)
{
  var effect = new webappClient_Effect();
  effect.fan = elem;
  effect.dom = elem.elem;
  return effect;
}

//////////////////////////////////////////////////////////////////////////
// Tween
//////////////////////////////////////////////////////////////////////////

function webappClient_Tween(fx, prop, stop)
{
  this.fx   = fx;      // the Effect instance
  this.elem = fx.dom;  // the DOM element to tween
  this.prop = prop;    // CSS prop name

  var css = this.fromCss(stop);
  this.start = this.currentVal();  // start value
  this.stop  = css.val;            // stop value
  this.unit  = css.unit;           // the CSS for the value
}

webappClient_Tween.prototype.currentVal = function()
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

webappClient_Tween.prototype.pixelVal = function(prop)
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

webappClient_Tween.prototype.applyVal = function(val)
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

webappClient_Tween.prototype.fromCss = function(css)
{
  if (css == "") return { val:0, unit:null };
  var val  = parseFloat(css);
  var unit = null;
  if      (sys_Str.endsWith(css, "%"))  unit = "%";
  else if (sys_Str.endsWith(css, "px")) unit = "px";
  else if (sys_Str.endsWith(css, "em")) unit = "em";
  return { val:val, unit:unit, toString:function(){return val+unit} };
}

webappClient_Tween.prototype.toString = function()
{
  return "[elem:" + this.elem.tagName + "," +
          "prop:" + this.prop + "," +
          "start:" + this.start + "," +
          "stop:" + this.stop + "," +
          "unit:" + this.unit + "]";
}