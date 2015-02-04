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
// disable open/close animation
fan.webfwt.ActivityPanePeer.m_useAnim = true;

// dislabe for Chrome/Win
if (fan.fwt.DesktopPeer.$isChrome && fan.fwt.DesktopPeer.isWindows())
  fan.webfwt.ActivityPanePeer.m_useAnim = false;

// CSS
fan.fwt.WidgetPeer.addCss(
  "div._webfwt_ActivityPane_mask_ {" +
  " position: absolute;" +
  " top:0; left:0; width:100%; height:100%;" +
  " background: #000;" +
  " opacity: 0.25;" +
  " z-index: 1000;" +
  "}" +
  "div._webfwt_ActivityPane_shell_ {" +
  " position: absolute;" +
  " top:0; left:0; width:100%; height:100%;" +
  " z-index: 1001;" +
  "}" +
  "div._webfwt_ActivityPane_content_ {" +
  " position: absolute;" +
  " background: #3b3b3b;" +
  " color: #fff;" +
  " font: bold " + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFont) + ";" +
  " padding: 12px;" +
  " border-radius: 5px;" +
  "}" +
  "div._webfwt_ActivityPane_content_.opening {" +
  " opacity: 0.0;" +
  " -webkit-transform: scale(0.75);" +
  "    -moz-transform: scale(0.75);" +
  "}" +
  "div._webfwt_ActivityPane_content_.open {" +
  " opacity: 1.0;" +
  " -webkit-transition: -webkit-transform 100ms, opacity 100ms;" +
  "    -moz-transition:    -moz-transform 100ms, opacity 100ms;" +
  " -webkit-transform: scale(1.0);" +
  "    -moz-transform: scale(1.0);" +
  "}");

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
  mask.className = "_webfwt_ActivityPane_mask_";

  // shell we use to attach widgets to
  var shell = document.createElement("div");
  shell.className = "_webfwt_ActivityPane_shell_";

  // mount content
  var content = document.createElement("div");
  content.className = fan.webfwt.ActivityPanePeer.m_useAnim
    ? "_webfwt_ActivityPane_content_ opening"
    : "_webfwt_ActivityPane_content_";
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
  if (fan.webfwt.ActivityPanePeer.m_useAnim)
    content.className = "_webfwt_ActivityPane_content_ open";

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
  if (this.$shell && fan.webfwt.ActivityPanePeer.m_useAnim)
  {
    var content = this.$shell.firstChild;
    content.className = "_webfwt_ActivityPane_content_ opening";
  }

  // allow animation to complete
  var $this = this;
  setTimeout(function() {
    $this.$working = false;
    if ($this.$shell && $this.$shell.parentNode) $this.$shell.parentNode.removeChild($this.$shell);
    if ($this.$mask  && $this.$mask.parentNode)  $this.$mask.parentNode.removeChild($this.$mask);
    $this.$open = false;
  }, 100);
}

