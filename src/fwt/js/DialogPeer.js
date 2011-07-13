//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * DialogPeer.
 */
fan.fwt.DialogPeer = fan.sys.Obj.$extend(fan.fwt.WindowPeer);
fan.fwt.DialogPeer.prototype.$ctor = function(self)
{
  this.hasKeyBinding = false;
}

fan.fwt.DialogPeer.prototype.open = function(self)
{
  // attach event handlers
  if (!this.hasKeyBinding)
  {
    this.hasKeyBinding = true;
    self.onKeyDown().add(fan.sys.Func.make(
      fan.sys.List.make(fan.sys.Param.$type, [new fan.sys.Param("it","fwt::Event",false)]),
      fan.sys.Void.$type,
      function(it)
      {
        if (it.m_key == fan.fwt.Key.m_esc) { self.close(null); it.consume(); }
      }));
  }

  // mount mask that functions as input blocker for modality
  var mask = document.createElement("div")
  with (mask.style)
  {
    position   = "fixed";
    top        = "0";
    left       = "0";
    width      = "100%";
    height     = "100%";
    background = "#000";
    opacity    = "0.0";
    filter     = "progid:DXImageTransform.Microsoft.Alpha(opacity=25);"
    MozTransition    = "100ms";
    webkitTransition = "100ms";
  }

  // mount shell we use to attach widgets to
  var shell = document.createElement("div")
  with (shell.style)
  {
    position   = "fixed";
    top        = "0";
    left       = "0";
    width      = "100%";
    height     = "100%";
  }

  // mount window
  var tbar = this.emptyDiv();
  with (tbar.style)
  {
    height     = "18px";
    padding    = "4px 6px";
    color      = "#fff";
    font       = "bold " + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFont);
    //textShadow = "0 -1px 1px #1c1c1c";
    textAlign  = "center";
    borderTop    = "1px solid #7c7c7c";
    borderBottom = "1px solid #282828";
    MozBorderRadiusTopleft     = "4px";
    MozBorderRadiusTopright    = "4px";
    webkitBorderTopLeftRadius  = "4px";
    webkitBorderTopRightRadius = "4px";
    borderRadius = "4px 4px 0 0";
  }
  fan.fwt.WidgetPeer.setBg(tbar, fan.gfx.Gradient.fromStr("0% 0%, 0% 100%, #707070, #5a5a5a 0.5, #525252 0.5, #484848"));
  var content = this.emptyDiv();
  with (content.style)
  {
    background = "#eee";
  }
  var dlg = this.emptyDiv();
  with (dlg.style)
  {
    border     = "1px solid #404040";
    MozBorderRadiusTopleft     = "5px";
    MozBorderRadiusTopright    = "5px";
    webkitBorderTopLeftRadius  = "5px";
    webkitBorderTopRightRadius = "5px";
    borderRadius    = "5px 5px 0 0";
    MozBoxShadow    = "0 5px 12px #404040";
    webkitBoxShadow = "0 5px 12px #404040";
    boxShadow       = "0 5px 12px #404040";
    MozTransform    = "scale(0.75)";
    webkitTransform = "scale(0.75)";
    opacity = "0.0";
  }
  tbar.appendChild(document.createTextNode(this.m_title));
  dlg.appendChild(tbar);
  dlg.appendChild(content);
  shell.appendChild(dlg);
  this.attachTo(self, content);
  document.body.appendChild(mask);
  document.body.appendChild(shell);
  self.relayout();

  // cache elements so we can remove when we close
  this.$mask = mask;
  this.$shell = shell;
  this.$focus = document.activeElement;

  // animate open and dialog resizes
  mask.style.opacity = "0.25";
  var tx = "-transform 100ms, opacity 100ms, top 250ms, left 250ms, width 250ms, height 250ms";
  dlg.style.MozTransition    = "-moz" + tx;
  dlg.style.MozTransform     = "scale(1.0)";
  dlg.style.webkitTransition = "-webkit" + tx;
  dlg.style.webkitTransform  = "scale(1.0)";
  dlg.style.opacity = "1.0";

  // try to focus first form element
  self.focus();
  var elem = fan.fwt.DialogPeer.findFormControl(content);
  if (elem != null)
  {
    // NOTE: needed to use a delay here for this to
    // work reliably, assumingly to give the renderer
    // time to layout DOM changes.
    var func = function() { elem.focus(); }
    setTimeout(func, 50);
  }
}

fan.fwt.DialogPeer.findFormControl = function(node)
{
  var tag = node.tagName;
  if (tag != null)
  {
    tag = tag.toLowerCase();
    if (tag == "input" || tag == "select" || tag == "textarea") return node;
  }
  for (var i=0; i<node.childNodes.length; i++)
  {
    var n = fan.fwt.DialogPeer.findFormControl(node.childNodes[i])
    if (n != null) return n;
  }
  return null;
}

fan.fwt.DialogPeer.prototype.close = function(self, result)
{
  // backdoor to trap validation errs
  if (self.m_onValidate != null && fan.fwt.DialogPeer.$isCommit(result))
  {
    var event      = fan.fwt.Event.make();
    event.m_widget = self;
    event.m_id     = fan.fwt.EventId.m_verify;
    event.m_data   = result;

    var list = self.m_onValidate.list();
    for (var i=0; i<list.size(); i++) list.get(i).call(event);
    if (self.m_invalid == true)
    {
      self.m_invalid = false;
      self.relayout();
      return;
    }
  }

  // animate close
  if (this.$shell)
  {
    var dlg = this.$shell.firstChild;
    dlg.style.MozTransition = "-moz-transform 100ms, opacity 100ms";
    dlg.style.webkitTransition = "-webkit-transform 100ms, opacity 100ms";
    dlg.style.opacity = "0.0";
    dlg.style.MozTransform = "scale(0.75)";
    dlg.style.webkitTransform = "scale(0.75)";
    this.$mask.style.opacity = "0.0";
  }

  // allow animation to complete
  var $this = this;
  setTimeout(function() {
    if ($this.$shell) $this.$shell.parentNode.removeChild($this.$shell);
    if ($this.$mask) $this.$mask.parentNode.removeChild($this.$mask);
    fan.fwt.WindowPeer.prototype.close.call($this, self, result);
    if ($this.$focus != null) $this.$focus.focus();
  }, 100);
}

fan.fwt.DialogPeer.$isCommit = function(result)
{
  if (result == null) return false;
  var id = result.m_id;
  if (id == fan.fwt.DialogCommandId.m_ok)  return true;
  if (id == fan.fwt.DialogCommandId.m_yes) return true;
  return false;
}

fan.fwt.DialogPeer.prototype.sync = function(self)
{
  var content = self.content();
  if (content == null || content.peer.elem == null) return;

  var shell = this.elem.parentNode.parentNode;
  var dlg   = this.elem.parentNode;
  var tbar  = dlg.firstChild;
  var pref  = content.prefSize();

  var th = 28;
  var pw = Math.min(pref.m_w, shell.offsetWidth-24);
  var ph = Math.min(pref.m_h, shell.offsetHeight-24-th);

  var w  = pw;
  var h  = ph + th;
  var x  = Math.floor((shell.offsetWidth - w) / 2);
  var y  = Math.floor((shell.offsetHeight - h) / 2);

  tbar.style.width = (w-12) + "px";  // -padding/border
  with (dlg.style)
  {
    left   = x + "px";
    top    = y + "px";
    width  = w + "px";
    height = h + "px";
  }

  this.pos$(this, fan.gfx.Point.make(0, th));
  this.size$(this, fan.gfx.Size.make(pw, ph));
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.fwt.DialogPeer.prototype.title   = function(self) { return this.m_title; }
fan.fwt.DialogPeer.prototype.title$  = function(self, val) { this.m_title = val; }
fan.fwt.DialogPeer.prototype.m_title = "";


