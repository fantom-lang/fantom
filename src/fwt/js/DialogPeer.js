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

// see init.js for CSS

fan.fwt.DialogPeer.prototype.setDefButton = function(self, button)
{
  button.peer.m_def = true;
  this.m_defButton = button;
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
        if (it.m_key == fan.fwt.Key.m_enter)
        {
          // workaround to not fire defCmd for Text { multiLine=true }
          if (it.m_$target != null && it.m_$target.tagName == "TEXTAREA") return;

          var def = self.peer.m_defButton;
          if (def != null && def.enabled()) { def.peer.fireAction(def); it.consume(); }
        }
      }));
  }

  // mount mask that functions as input blocker for modality
  var mask = document.createElement("div")
  mask.className = "_fwt_Dialog_mask_";

  // mount shell we use to attach widgets to
  var shell = document.createElement("div")
  shell.className = "_fwt_Dialog_shell_";

  // mount window
  var tbar = this.emptyDiv();
  tbar.className = "_fwt_Dialog_tbar_";

  var content = this.emptyDiv();
  content.style.background = "#eee";

  var dlg = this.emptyDiv();
  dlg.className = "_fwt_Dialog_ opening";
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
  dlg.className = "_fwt_Dialog_ open";

  setTimeout(function() {
    // try to focus first form element - give DOM a few ms
    // to layout content before we attempt to focus
    var elem = fan.fwt.DialogPeer.findFormControl(content);
    if (elem != null) elem.focus();
    else self.focus();

    // fire onOpen event
    var evt = fan.fwt.Event.make();
    evt.m_widget = self;
    evt.m_id     = fan.fwt.EventId.m_open;
    var list = self.onOpen().list();
    for (var i=0; i<list.size(); i++) list.get(i).call(evt);
  }, 50);

  // 16 May 2012: Chrome 19 appears to have resolved this issue
  //
  // // 26 Jan 2012: Chrome contains a bug where scrolling is broken
  // // for elements that have webkit-transform applied - so allow
  // // animation to comlete, then remove:
  // if (fan.fwt.DesktopPeer.$isChrome)
  // {
  //   setTimeout(function() {
  //     dlg.style.webkitTransform = "none";
  //     dlg.style.webkitTransition = anim;
  //   }, 300);
  // }
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
    dlg.className = "_fwt_Dialog_ opening";
    this.$mask.style.opacity = "0.0";
  }

  // allow animation to complete
  var $this = this;
  setTimeout(function() {
    if ($this.$shell) $this.$shell.parentNode.removeChild($this.$shell);
    if ($this.$mask) $this.$mask.parentNode.removeChild($this.$mask);
    fan.fwt.WindowPeer.prototype.close.call($this, self, result);
    // try to refocus last widget; don't make a fuss if we can't
    try { $this.$focus.focus(); } catch (err) {}
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
  dlg.style.left   = x + "px";
  dlg.style.top    = y + "px";
  dlg.style.width  = w + "px";
  dlg.style.height = h + "px";

  this.pos$(this, fan.gfx.Point.make(0, th));
  this.size$(this, fan.gfx.Size.make(pw, ph));
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.fwt.DialogPeer.prototype.title   = function(self) { return this.m_title; }
fan.fwt.DialogPeer.prototype.title$  = function(self, val) { this.m_title = val; }
fan.fwt.DialogPeer.prototype.m_title = "";


