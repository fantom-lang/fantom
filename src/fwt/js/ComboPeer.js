//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jun 09  Andy Frank  Creation
//

/**
 * ComboPeer.
 */
fan.fwt.ComboPeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.ComboPeer.prototype.$ctor = function(self) {}

fan.fwt.ComboPeer.prototype.font   = function(self) { return this.m_font; }
fan.fwt.ComboPeer.prototype.font$  = function(self, val) { this.m_font = val; }
fan.fwt.ComboPeer.prototype.m_font = null;

fan.fwt.ComboPeer.prototype.items   = function(self) { return this.m_items; }
fan.fwt.ComboPeer.prototype.items$  = function(self, val)
{
  this.m_items = val;
  this.needsRebuild = true;
}
fan.fwt.ComboPeer.prototype.m_items = null;

fan.fwt.ComboPeer.prototype.selectedIndex   = function(self) { return this.m_selectedIndex; }
fan.fwt.ComboPeer.prototype.selectedIndex$  = function(self, val)
{
  this.m_selectedIndex = val;
  if (this.elem != null && this.elem.firstChild != null)
    this.elem.firstChild.selectedIndex = val;
}
fan.fwt.ComboPeer.prototype.m_selectedIndex = null;

fan.fwt.ComboPeer.prototype.text   = function(self) { return this.m_text; }
fan.fwt.ComboPeer.prototype.text$  = function(self, val) { this.m_text = val; }
fan.fwt.ComboPeer.prototype.m_text = "";

fan.fwt.ComboPeer.prototype.create = function(parentElem)
{
  // make sure we force rebuild
  this.needsRebuild = true;

  var select = document.createElement("select");
  var div = this.emptyDiv();
  div.appendChild(select);
  parentElem.appendChild(div);
  return div;
}

fan.fwt.ComboPeer.prototype.needsRebuild = true;
fan.fwt.ComboPeer.prototype.rebuild = function(self)
{
  // sync props
  var select = this.elem.firstChild;
  select.disabled = !this.m_enabled;

  // clear old items
  while (select.firstChild != null)
    select.removeChild(select.firstChild);

  // add new items
  for (var i=0; i<this.m_items.size(); i++)
  {
    var option = document.createElement("option");
    option.appendChild(document.createTextNode(this.m_items.get(i)));
    select.appendChild(option);
  }
}

fan.fwt.ComboPeer.prototype.sync = function(self)
{
  if (this.needsRebuild)
  {
    this.rebuild();
    this.needsRebuild = false;
  }

  // sync props
  var select = this.elem.firstChild;
  select.disabled = !this.m_enabled;

  // set selectedIndex to self to sync
  this.selectedIndex$(self, this.m_selectedIndex);

  select.onchange = function()
  {
    // sync changes back to widget
    self.selectedIndex$(select.selectedIndex);

    // fire onModify
    if (self.m_onModify.size() > 0)
    {
      var me = fan.fwt.Event.make();
      me.m_id = fan.fwt.EventId.m_modified;
      me.m_widget = self;
      var list = self.m_onModify.list();
      for (var i=0; i<list.size(); i++) list.get(i).call(me);
    }
  }

  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}