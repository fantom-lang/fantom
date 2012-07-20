//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 May 10  Andy Frank  Creation
//

/**
 * ActivityPanePeer.
 */
fan.webfwt.ActivityPanePeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.webfwt.ActivityPanePeer.prototype.$ctor = function(self)
{
  this.$working = false;
}

fan.webfwt.ActivityPanePeer.$find = null;
fan.webfwt.ActivityPanePeer.find = function()
{
  return fan.webfwt.ActivityPanePeer.$find;
}

fan.webfwt.ActivityPanePeer.prototype.working = function(self)
{
  return this.$working;
}

fan.webfwt.ActivityPanePeer.prototype.open = function(self, parent)
{
  this.$parent = parent;
  this.$working = true;

  // mount mask that functions as input blocker for modality
  var mask = document.createElement("div");
  with (mask.style)
  {
    position   = "absolute";
    left       = "0";
    top        = "0";
    width      = "100%";
    height     = "100%";
    background = "#000";
    opacity    = "0.25";
    filter     = "progid:DXImageTransform.Microsoft.Alpha(opacity=25);"
    zIndex     = 1000;
  }

  // shell we use to attach widgets to
  var shell = document.createElement("div");
  with (shell.style)
  {
    position = "absolute";
    left     = "0";
    top      = "0";
    width    = "100%";
    height   = "100%";
    zIndex   = 1001;
  }

  // mount content
  var content = document.createElement("div");
  with (content.style)
  {
    position = "absolute";
    background = "#3b3b3b";
    color   = "#fff";
    font    = "bold " + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFont);
    padding = "12px";
    MozBorderRadius    = "5px";
    webkitBorderRadius = "5px";
    borderRadius       = "5px";
    MozTransform    = "scale(0.75)";
    webkitTransform = "scale(0.75)";
    opacity = "0.0";
  }
  if (self.m_image != null)
  {
    var img = document.createElement("img");
    img.src = fan.fwt.WidgetPeer.uriToImageSrc(self.m_image.m_uri);
    img.style.verticalAlign = "middle";
    img.style.paddingRight  = "6px";
    content.appendChild(img);
  }
  content.appendChild(document.createTextNode(self.msg()));

  // add to DOM
  shell.appendChild(content);
  parent.peer.elem.appendChild(mask);
  parent.peer.elem.appendChild(shell);

  // cache elements so we can remove when we close
  this.$mask = mask;
  this.$shell = shell;
  this.$open = true;

  // center content
  var sw = shell.offsetWidth;
  var sh = shell.offsetHeight;
  var cw = content.offsetWidth;
  var ch = content.offsetHeight;
  content.style.left = ((sw-cw)/2) + "px";
  content.style.top  = ((sh-ch)/2) + "px";

  // animate open
  content.style.MozTransition = "-moz-transform 100ms, opacity 100ms";
  content.style.MozTransform  = "scale(1.0)";
  content.style.webkitTransition = "-webkit-transform 100ms, opacity 100ms";
  content.style.webkitTransform  = "scale(1.0)";
  content.style.opacity = "1.0";

  // set find instance
  fan.webfwt.ActivityPanePeer.$find = self;
  return self;
}

fan.webfwt.ActivityPanePeer.prototype.close = function(self)
{
  if (!this.$open) return;

  // remove find instance
  fan.webfwt.ActivityPanePeer.$find = null;

  // animate close
  if (this.$shell)
  {
    var content = this.$shell.firstChild;
    content.style.opacity = "0.0";
    content.style.MozTransform    = "scale(0.75)";
    content.style.webkitTransform = "scale(0.75)";
  }

  // allow animation to complete
  var $this = this;
  setTimeout(function() {
    this.$working = false;
    if ($this.$shell && $this.$shell.parentNode) $this.$shell.parentNode.removeChild($this.$shell);
    if ($this.$mask  && $this.$mask.parentNode)  $this.$mask.parentNode.removeChild($this.$mask);
    $this.$open = false;
  }, 100);
}

