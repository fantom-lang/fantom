//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jun 2011  Andy Frank  Creation
//

/**
 * WebListPeer.
 */
fan.webfwt.WebListPeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.WebListPeer.prototype.$ctor = function(self)
{
}

fan.webfwt.WebListPeer.prototype.m_items = fan.sys.Obj.$type.emptyList();
fan.webfwt.WebListPeer.prototype.items = function(self) { return this.m_items; }
fan.webfwt.WebListPeer.prototype.items$ = function(self, val)
{
  this.needsLayout = true;
  this.m_items = val;
  self.selectedIndexes$(fan.sys.List.make(fan.sys.Int.$type));
}

fan.webfwt.WebListPeer.prototype.m_scrolly = null;
fan.webfwt.WebListPeer.prototype.scrolly = function(self)
{
  var container = this.container();
  return container ? container.scrollTop : 0;
}
fan.webfwt.WebListPeer.prototype.scrolly$ = function(self, val)
{
  // max value is auto-clipped to viewport
  if (val < 0) val = 0;

  var container = this.container()
  if (container == null) this.m_scrolly = val; // handle in sync()
  else
  {
    container.scrollTop = val;
    this.m_scrolly = null;   // make sure we clear out sync hook
  }
}

fan.webfwt.WebListPeer.prototype.create = function(parentElem, self)
{
  this.sel = [];
  this.pivot = null;
  this.needsLayout = true;
  var div = this.emptyDiv();
  div.tabIndex = 0;
  parentElem.appendChild(div);
  return div;
}

fan.webfwt.WebListPeer.prototype.rebuild = function(self)
{
  // setup container
  var container = document.createElement("div");
  container.className = "_webfwt_WebScrollPane_ _webfwt_WebList_";
  container.style.overflowX = "hidden";
  container.style.overflowY = "auto";
  container.style.cursor    = "default";
  this.setupContainer(self, container);

  if (self.selectionEnabled())
  {
    var $this = this;
    container.onmousedown = function(event) { return $this.handleMouseDown(self, event) }
    container.onmouseup   = function(event) { $this.handleMouseUp(self, event); }
    container.ondblclick  = function(event) { self.fireAction(); }
    this.elem.onkeydown   = function(event) { $this.handleKeyEvent(self, event); }
  }

  // add items to container
  var size = this.m_items.size();
  for (var i=0; i<size; i++)
  {
    var node = this.makeRow(self, this.m_items.get(i));
    container.appendChild(node);
  }

  // finish layout
  var elem = this.elem;
  while (elem.firstChild) elem.removeChild(elem.firstChild);
  elem.appendChild(container);
  this.finishContainer(self, container);
  this.updateSelection(self);
}

fan.webfwt.WebListPeer.prototype.setupContainer = function(self, elem) {}
fan.webfwt.WebListPeer.prototype.finishContainer = function(self, elem) {}
fan.webfwt.WebListPeer.prototype.repaintSelection = function(self, ix, selected) {}

fan.webfwt.WebListPeer.prototype.makeRow = function(self, item)
{
  var div = document.createElement("div");
  var str = fan.sys.ObjUtil.toStr(item);
  div.appendChild(document.createTextNode(str));
  return div;
}

fan.webfwt.WebListPeer.prototype.updateSelection = function(self)
{
  if (this.elem == null) return;
  if (!self.selectionEnabled()) return;

  // remove current selections
  if (this.sel.length > 0)
  {
    this.repaintSelection(self, this.sel, false);
    this.sel = [];
  }

  // if no new selection, bail here
  var index = self.m_selectedIndexes;
  if (index.isEmpty()) return;

  // set pivot if preselecting
  if (this.pivot == null && index.size() == 1)
    this.pivot = index.first();

  // make sure index is in bounds
  var container = this.elem.firstChild;
  if (container == null) return;
  if (container.childNodes.length == 0) return;

  // update new selection
  this.sel = [];
  for (var i=0; i<index.size(); i++) this.sel.push(index.get(i));
  this.repaintSelection(self, this.sel, true);

  // ensure first item in selection is visible
  this.scrollSelectionInView();
}

fan.webfwt.WebListPeer.prototype.scrollSelectionInView = function(self)
{
  if (this.sel.length == 0 || this.container == null) return;
  var container = this.elem.firstChild;
  var elem = this.indexToElem(this.sel[0]);
  if (!elem) return;
  var et = elem.offsetTop;
  var eh = elem.offsetHeight;
  var cs = container.scrollTop;
  var ch = container.offsetHeight;
  if (et < cs) elem.scrollIntoView(true);
  else if ((et+eh) > (cs+ch)) elem.scrollIntoView(false);
}

/////////////////////////////////////////////////////////////////////////
// Widget
/////////////////////////////////////////////////////////////////////////

fan.webfwt.WebListPeer.prototype.prefSize = function(self, hints)
{
  var pref = fan.fwt.WidgetPeer.prototype.prefSize.call(this, self, hints);

  var pw = self.m_prefw; if (pw == null) pw = pref.m_w;
  var ph = self.m_prefh; if (ph == null) ph = pref.m_h;
  return fan.gfx.Size.make(pw, ph)
}

fan.webfwt.WebListPeer.prototype.onLayout = function(self) {}

fan.webfwt.WebListPeer.prototype.sync = function(self)
{
  if (this.needsLayout) // && this.m_size.m_w > 0)
  {
    this.needsLayout = false;
    this.rebuild(self);
  }

  var container = this.container();
  if (container != null)
  {
    container.style.width  = (this.m_size.m_w-2) + "px";
    container.style.height = (this.m_size.m_h-2) + "px";
  }

  fan.fwt.WidgetPeer.prototype.sync.call(this, self);

  // check if scrolly is armed
  if (this.m_scrolly && container != null && this.m_size.m_h > 0)
  {
    container.scrollTop = this.m_scrolly;
    this.m_scrolly = null;
  }

  // ensure first item in selection is visible
  this.scrollSelectionInView();
}

/////////////////////////////////////////////////////////////////////////
// Mouse Events
/////////////////////////////////////////////////////////////////////////

fan.webfwt.WebListPeer.prototype.handleMouseDown = function(self, event)
{
  self.focus();

  var container = this.elem.firstChild;
  var ix = this.elemToIndex(event.target);
  if (ix == null) return;

  // bail if onBefore cancels
  var beforeList = this.toIntList([ix]);
  if (!self.fireBeforeSelect(beforeList)) return;

  // deselect current selection
  this.repaintSelection(self, this.sel, false);

  // update selection
  if (!self.m_multi) this.sel = [ix];
  else
  {
    if (event.ctrlKey || event.metaKey)
    {
      this.pivot = ix;
      this.sel = this.cmdSel(this.sel, ix);
    }
    else if (event.shiftKey)
    {
      this.sel = this.shiftSel(this.sel, ix);
    }
    else
    {
      this.pivot = ix;
      this.sel = [ix];
    }
  }

  // repaint new selection
  this.repaintSelection(self, this.sel, true);

  // disable selection
  event.stopPropagation();
  return false;
}

fan.webfwt.WebListPeer.prototype.handleMouseUp = function(self, event)
{
  // check if selection has changed
  var index = self.m_selectedIndexes;
  var same  = this.sel.length == index.size();
  for (var i=0; i<this.sel.length; i++)
    if (this.sel[i] != index.getSafe(i))
      same = false;

  // only fire onSelect selection modified
  if (same) return;
  self.fireSelect(this.toIntList(this.sel));
}

/////////////////////////////////////////////////////////////////////////
// Keyboard Events
/////////////////////////////////////////////////////////////////////////

fan.webfwt.WebListPeer.prototype.handleKeyEvent = function(self, event)
{
  // only handle up/down
  var key = event.keyCode;
  if (key != 38 && key != 40) return;

  // consume event
  event.stopPropagation();

  // find direction
  var diff = 0
  if (event.keyCode == 38) diff = -1
  if (event.keyCode == 40) diff = 1
  if (diff == 0) return;

  // find selection and notify
  var cur = self.m_selectedIndexes.first();
  var items = this.m_items;
  var check = function(i) {
    return i>=0 && i<items.size() && (self.isHeading && self.isHeading(items.get(i)));
  }

  var ix = [];
  if (cur == null)
  {
    // if no selection - select first item
    var i = 0;
    while (check(i)) i++
    if (i < items.size())
    {
      this.pivot = i;
      ix.push(i);
    }
  }
  else if (diff < 0 && cur > 0)
  {
    // select previous item
    var i = cur-1;
    while (check(i)) i--;
    if (i >= 0) { this.pivot=i; ix.push(i); }
    // TODO: rubber-band keyboard support
    // {
    //   if (!event.shiftKey) { this.pivot=i; ix.push(i); }
    //   else if (this.pivot == null) { this.pivot=i; ix.push(i); }
    //   else
    //   {
    //     var i = this.pivot;
    //     var di = cur < this.pivot ? -1 : 1;
    //     while (i != cur) { info.push(toInfo(index)); ix += di }
    //   }
    // }
  }
  else if (diff > 0 && cur < this.m_items.size()-1)
  {
    // select next item
    var i = cur+1;
    while (check(i)) i++;
    if (i < items.size()) { this.pivot=i; ix.push(i); }
  }

  // bail if no selection
  if (ix.length == 0) return;

  // updates selection
  this.repaintSelection(self, this.sel, false);
  this.sel = ix;
  self.fireSelect(this.toIntList(this.sel));
}

/////////////////////////////////////////////////////////////////////////
// Support
/////////////////////////////////////////////////////////////////////////

fan.webfwt.WebListPeer.prototype.container = function()
{
  if (this.elem == null) return null;
  return this.elem.firstChild;
}

fan.webfwt.WebListPeer.prototype.indexToElem = function(index)
{
  var container = this.container();
  return container.childNodes[index];
}

fan.webfwt.WebListPeer.prototype.elemToIndex = function(target)
{
  // short-circuit if background pressed
  var container = this.container();
  if (target.className.indexOf("_webfwt_WebList_") != -1) return null;

  // walk up to actual row element
  while (target.parentNode.className.indexOf("_webfwt_WebList_") == -1)
    target = target.parentNode;

  // match up row to item
  for (var i=0; i<container.childNodes.length; i++)
  {
    var node = container.childNodes[i]
    if (target == node && node.className.indexOf("group") == -1)
      return i;
  }

  // no match found
  return null;
}

fan.webfwt.WebListPeer.prototype.toIntList = function(array)
{
  var list = fan.sys.List.make(fan.sys.Int.$type);
  for (var i=0; i<array.length; i++) list.add(array[i]);
  return list;
}

fan.webfwt.WebListPeer.prototype.cmdSel = function(cur, ix)
{
  // remove if exists
  var merge = cur.slice(0);
  for (var i=0; i<merge.length; i++)
    if (merge[i] == ix)
    {
      if (merge == 1) return merge; // never allow no selection
      merge.splice(i, 1);
      return merge;
    }

  // keep sorted by index
  merge.push(ix);
  merge.sort(function(a,b) {
    if (a < b) return -1;
    if (a > b) return 1;
    return 0;
  });

  return merge;
}

fan.webfwt.WebListPeer.prototype.shiftSel = function(cur, index)
{
  if (this.pivot == null)
  {
    this.pivot = index;
    return [index];
  }

  var container = this.container();
  var list = [];
  var ix = this.pivot;
  var di = index < this.pivot ? -1 : 1;

  while (ix != (index+di))
  {
    var node = container.childNodes[ix];
    if (node.className.indexOf("group") == -1) list.push(ix);
    ix += di;
  }

  return list;
}