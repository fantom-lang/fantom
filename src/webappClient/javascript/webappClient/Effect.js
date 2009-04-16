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

  $ctor: function() {},
  type: function() { return sys_Type.find("webappClient::Effect"); },

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  elem: function() { return this.fan; },

//////////////////////////////////////////////////////////////////////////
// Show/Hide
//////////////////////////////////////////////////////////////////////////

  show: function(dur, callback)
  {
    var ms = arguments.length == 0 ? 0 : dur.toMillis();
    if (ms == 0) this.dom.style.display = "block";
    else
    {
      // TODO
      this.dom.style.display = "block";
    }
  },

  hide: function(dur)
  {
    var ms = arguments.length == 0 ? 0 : dur.toMillis();
    if (ms == 0) this.dom.style.display = "none";
    else
    {
      // TODO
      this.dom.style.display = "none";
    }
  },

  animate: function(map, dur, callback)
  {
    var ms = arguments.length == 0 ? 0 : dur.toMillis();
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
      if (diff > (ms-10))
      {
        // clear timer
        clearInterval(intervalId);

        // make sure we go to the stop exactly
        for (var i=0; i<tweens.length; i++)
          tweens[i].applyVal(tweens[i].stop);

        // callback if specified
        if (callback) callback(tweens[0].fx);

        // don't run next frame
        return
      }

      for (var i=0; i<tweens.length; i++)
      {
        var tween = tweens[i];
        var ratio = diff / ms;
        var val = ((tween.stop-tween.start) * ratio) + tween.start;
        tween.applyVal(val);
      }
    }
    intervalId = setInterval(f, 10);
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  fan: null,   // Fan Elem wrappaer
  dom: null    // actual DOM element

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
  var val = this.elem.style[this.prop];
  if (val) return parseFloat(val);
  return webappClient_Tween.defVals[this.prop] || 0
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
      break;

    default:
      this.elem.style[this.prop] = val + (this.unit || "");
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
  return { val:val, unit:unit };
}

webappClient_Tween.prototype.toString = function()
{
  return "[elem:" + this.elem.tagName + "," +
          "prop:" + this.prop + "," +
          "start:" + this.start + "," +
          "stop:" + this.stop + "," +
          "unit:" + this.unit + "]";
}

webappClient_Tween.defVals =
{
  opacity: 1,
  width:   100,
  height:  100,
}