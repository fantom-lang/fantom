//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jun 09  Andy Frank  Creation
//

/**
 * TextPeer.
 */
fan.fwt.TextPeer = fan.sys.Obj.$extend(fan.fwt.TextWidgetPeer);
fan.fwt.TextPeer.prototype.$ctor = function(self)
{
  this.control = null;
}

fan.fwt.WidgetPeer.addCss(
  "._fwt_Text_ {" +
  " background: #fff;" +
  " color: black;" +
  " padding: 3px 2px 2px 2px;" +
  " margin: 0;" +
  " outline: none;" +
  " border-bottom: 1px solid #d0d0d0;" +
  " border-left:   1px solid #9d9d9d;" +
  " border-right:  1px solid #afafaf;" +
  " border-top:    1px solid #707070;" +
  " -webkit-box-shadow: inset 0px 1px 2px #b7b7b7;" +
  " -moz-box-shadow:    inset 0px 1px 2px #b7b7b7;" +
  " box-shadow:         inset 0px 1px 2px #b7b7b7;" +
  "}" +
  "._fwt_Text_readonly_ {" +
  " background: #e4e4e4;" +
  " -webkit-box-shadow: inset 0px 1px 2px #a2a2a2;" +
  " -moz-box-shadow:    inset 0px 1px 2px #a2a2a2;" +
  " box-shadow:         inset 0px 1px 2px #a2a2a2;" +
  "}" +
  "._fwt_Text_[disabled] {" +
  " opacity: 0.5;" +
  "}");

fan.fwt.TextPeer.prototype.text = function(self) { return this.m_text; }
fan.fwt.TextPeer.prototype.text$ = function(self, val, sync)
{
  this.m_text = val;
  if (sync === undefined) sync = true;
  if (sync && this.control != null) this.control.value = this.m_text;
}
fan.fwt.TextPeer.prototype.m_text = "";

fan.fwt.TextPeer.prototype.m_bg = null;
fan.fwt.TextPeer.prototype.bg = function(self) { return this.m_bg; }
fan.fwt.TextPeer.prototype.bg$ = function(self, val) { this.m_bg = val; }

fan.fwt.TextPeer.prototype.m_fg = null;
fan.fwt.TextPeer.prototype.fg = function(self) { return this.m_fg; }
fan.fwt.TextPeer.prototype.fg$ = function(self, val) { this.m_fg = val; }

fan.fwt.TextPeer.prototype.prefSize = function(self, hints)
{
  var pref = fan.fwt.WidgetPeer.prototype.prefSize.call(this, self, hints);
  if (fan.fwt.DesktopPeer.isMac && fan.fwt.DesktopPeer.$isWebkit)
  {
    // Webkit on OS X 10.7 has some bug reporting proper pref
    // size when size=X is specified on field
    pref = fan.gfx.Size.make(Math.floor(pref.m_w * 1.25), pref.m_h);
  }
  return pref;
}

fan.fwt.TextPeer.prototype.create = function(parentElem, self)
{
  // create actual input element
  if (self.m_multiLine)
  {
    var text = document.createElement("textarea");
    text.cols = self.m_prefCols;
    text.rows = self.m_prefRows;
    text.style.resize = "none";
    this.control = text;
  }
  else
  {
    var text = document.createElement("input");
    text.type = self.m_password ? "password" : "text";
    text.size = self.m_prefCols;
    this.control = text;
  }

  // sub-class create hook
  if (this.subCreate) this.subCreate(self, this.control);

  // wire up event handlers to keep text prop synchronized
  var $this = this;
  this.control.onfocus = function(e) { $this.$fireFocus(self); }
  this.control.onkeyup = function(e)
  {
    // fire onModify
    $this.fireModify(self);

    // fire onAction
    if (e.keyCode == 13 && self.onAction().size() > 0)
    {
      var ae = fan.fwt.Event.make();
      ae.m_id = fan.fwt.EventId.m_action;
      ae.m_widget = self;
      var list = self.onAction().list();
      for (var i=0; i<list.size(); i++) list.get(i).call(ae);
    }
  }
  // cut/paste events fire before input.value is set, so use a small delay
  // to allow value to be set so it can be synced to m_text
  text.onpaste = function(event) { setTimeout(function() { $this.fireModify(self); }, 10); }
  text.oncut   = function(event) { setTimeout(function() { $this.fireModify(self); }, 10); }

  // fg/bg
  if (this.m_bg) this.control.style.background = this.m_bg.toCss();
  if (this.m_fg) this.control.style.color = this.m_fg.toCss();

  // font
  this.control.style.font = fan.fwt.WidgetPeer.fontToCss(
    this.m_font != null ? this.m_font : fan.fwt.Desktop.sysFont());

  // assemble
  var div = this.emptyDiv();
  div.appendChild(this.control);
  parentElem.appendChild(div);
  return div;
}

fan.fwt.TextPeer.prototype.fireModify = function(self)
{
  // short-circuit if not modified
  if (this.m_text == this.control.value) return;

  // sync control value to widget
  this.text$(self, this.control.value, false);

  // fire onModify
  if (self.onModify().size() > 0)
  {
    var me = fan.fwt.Event.make();
    me.m_id = fan.fwt.EventId.m_modified;
    me.m_widget = self;
    var list = self.onModify().list();
    for (var i=0; i<list.size(); i++) list.get(i).call(me);
  }
}

fan.fwt.TextPeer.prototype.focus = function(self)
{
  if (this.control != null) this.control.focus();
}

fan.fwt.TextPeer.prototype.hasFocus = function(self)
{
  return this.control != null && this.control === document.activeElement;
}

fan.fwt.TextPeer.prototype.sync = function(self)
{
  var text = this.control;
  var oldText = text.value

  // setting value will force cursor to end of text, so only
  // set if different to avoid relayout "bugs" where cursor
  // jumps unexpectedly
  if (text.value != this.m_text)
  {
    text.value = this.m_text;

    // Prevent Chrome scrolling to end of textarea on initial load.
    if (fan.fwt.DesktopPeer.$isChrome && oldText == "" && self.m_multiLine)
    {
      text.focus();
      text.selectionStart = 0;
      text.selectionEnd = 0;
    }
  }

  // sync control
  text.readOnly = !self.m_editable;
  text.disabled = !this.m_enabled;

  // sync style
  if (this.m_bg) this.control.style.background = this.m_bg.toCss();
  if (this.m_fg) this.control.style.color = this.m_fg.toCss();
  var readonly = !self.m_editable || !this.m_enabled;
  text.className = this.$cssClass(readonly);
  fan.fwt.WidgetPeer.applyStyle(text,
    readonly ? this.$disabledStyle(self) : this.$style(self));

  //if (self.m_multiLine)
  //{
    // cache size
    var oldw = this.elem.style.width;
    var oldh = this.elem.style.height;

    // sync and measure pref
    this.elem.style.width  = "auto";
    this.elem.style.height = "auto";
    var pw = this.elem.offsetWidth;
    var ph = this.elem.offsetHeight;

    // restore old size
    this.elem.style.width  = oldw;
    this.elem.style.height = oldh;

    // check if explicit size
    var w = this.m_size.m_w;
    var h = this.m_size.m_h;
    if ((w > 0 && w != pw) || (h > 0 && h != ph))
    {
      text.style = "absolute";
      text.style.MozBoxSizing = "border-box";
      text.style.boxSizing = "border-box";
      text.style.width  = "100%";
      text.style.height = "100%";
    }
  //}

  if (this.subSync) this.subSync(self, text);

  // sync widget size
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

// Backdoor hook to override style [returns [Str:Str]?]
fan.fwt.TextPeer.prototype.$style = function(self) { return null; }
fan.fwt.TextPeer.prototype.$disabledStyle = function(self) { return null; }
fan.fwt.TextPeer.prototype.$cssClass = function(readonly)
{
  return readonly ? "_fwt_Text_ _fwt_Text_readonly_" : "_fwt_Text_";
}
