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
fan.webfwt.WebListPeer.prototype.$ctor = function(self) {}

fan.webfwt.WebListPeer.prototype.m_items = fan.sys.Obj.$type.emptyList();
fan.webfwt.WebListPeer.prototype.items = function(self) { return this.m_items; }
fan.webfwt.WebListPeer.prototype.items$ = function(self, val)
{
  this.needsLayout = true;
  this.m_items = val;
  self.selectedIndex$(null);
}

fan.webfwt.WebListPeer.prototype.create = function(parentElem, self)
{
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
    // mousedown selectes items
    var $this = this;
    container.onmousedown = function(event)
    {
      self.focus();

      var info = $this.toSelInfo(event.target, container);
      if (info == null) return;

      if (!self.fireBeforeSelect(info.index)) return;

      if ($this.sel) $this.repaintSelection(self, $this.sel, false);
      $this.repaintSelection(self, info, true);
      $this.sel = info;
    }

    // mouse up fires event
    container.onmouseup = function(event)
    {
      if ($this.sel == null) return;
      if ($this.sel.index == self.m_selectedIndex) return;
      self.fireSelect($this.sel.index);
    }

    // key events move selection
    this.elem.onkeydown = function(event)
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
      var index = self.m_selectedIndex;
      var items = $this.m_items;
      var check = function(i) {
        return i>=0 && i<items.size() && (self.isHeading && self.isHeading(items.get(i)));
      }

      if (index == null)
      {
        index = 0;
        while (check(index)) index++
        if (index < items.size()) self.fireSelect(index);
      }
      else if (diff < 0 && index > 0)
      {
        index = index-1;
        while (check(index)) index--;
        if (index >= 0) self.fireSelect(index);
      }
      else if (diff > 0 && index < $this.m_items.size()-1)
      {
        index = index+1;
        while (check(index)) index++;
        if (index < items.size()) self.fireSelect(index);
      }
    }
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
fan.webfwt.WebListPeer.prototype.repaintSelection = function(self, info, selected) {}

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
  if (this.sel)
  {
    this.repaintSelection(self, this.sel, false);
    this.sel = null;
  }

  // if no new selection, bail here
  var index = self.m_selectedIndex;
  if (index == null) return;

  // make sure index is in bounds
  var container = this.elem.firstChild;
  if (container == null) return;
  if (index >= container.childNodes.length) return;

  // update new selection
  var elem = container.childNodes[index];
  var info  = { elem:elem, index:index, item:this.m_items.get(index) }
  this.repaintSelection(self, info, true);
  this.sel = info;
}

fan.webfwt.WebListPeer.prototype.toSelInfo = function(target, container)
{
  // short-circuit if background pressed
  if (target.className.indexOf("_webfwt_WebList_") != -1) return null;

  // walk up to actual row element
  while (target.parentNode.className.indexOf("_webfwt_WebList_") == -1)
    target = target.parentNode;

  // match up row to item
  for (var i=0; i<container.childNodes.length; i++)
  {
    var node = container.childNodes[i]
    if (target == node && node.className.indexOf("group") == -1)
      return { elem:target, index:i, item:this.m_items.get(i) };
  }

  return null;
}

fan.webfwt.WebListPeer.prototype.prefSize = function(self, hints)
{
  return fan.fwt.WidgetPeer.prototype.prefSize.call(this, self, hints);
}

fan.webfwt.WebListPeer.prototype.onLayout = function(self) {}

fan.webfwt.WebListPeer.prototype.sync = function(self)
{
  if (this.needsLayout) // && this.m_size.m_w > 0)
  {
    this.needsLayout = false;
    this.rebuild(self);
  }

  var container = this.elem.firstChild;
  if (container != null)
  {
    container.style.width  = (this.m_size.m_w-2) + "px";
    container.style.height = (this.m_size.m_h-2) + "px";
  }

  fan.fwt.WidgetPeer.prototype.sync.call(this, self);

  // scroll selection into view if necessary
  if (this.sel != null && container != null)
  {
    var elem = this.sel.elem;
    var et = elem.offsetTop;
    var eh = elem.offsetHeight;
    var cs = container.scrollTop;
    var ch = container.offsetHeight;
    if (et < cs) elem.scrollIntoView(true);
    else if ((et+eh) > (cs+ch)) elem.scrollIntoView(false);
  }
}


