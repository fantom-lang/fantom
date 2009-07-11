//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 09  Andy Frank  Creation
//

/**
 * TablePeer.
 */
fan.fwt.TablePeer = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.TablePeer.prototype.$ctor = function(self) {}

// TODO
//fan.fwt.TablePeer.prototype.colAt = function(self, pos) {}
//fan.fwt.TablePeer.prototype.rowAt = function(self, pos) {}
//fan.fwt.TablePeer.prototype.refreshAll = function(self) {}

fan.fwt.TablePeer.prototype.headerVisible = true;
fan.fwt.TablePeer.prototype.headerVisible$get = function(self) { return this.headerVisible; }
fan.fwt.TablePeer.prototype.headerVisible$set = function(self, val) { this.headerVisible = val; }

fan.fwt.TablePeer.prototype.selected = null;
fan.fwt.TablePeer.prototype.selected$get = function(self) { return this.selected; }
fan.fwt.TablePeer.prototype.selected$set = function(self, val)
{
  this.selected = val;
  if (this.selection != null) this.selection.select(val);
}

fan.fwt.TablePeer.prototype.create = function(parentElem)
{
  var table = document.createElement("table");
  with (table.style)
  {
    overflow = "auto";
    width  = "100%";
    borderSpacing = "0";
  }

  var div = this.emptyDiv();
  with (div.style)
  {
    border     = "1px solid #555";
    overflow   = "auto";
    background = "#fff";
  }

  div.appendChild(table);
  parentElem.appendChild(div);
  return div;
}

fan.fwt.TablePeer.prototype.refreshAll = function(self)
{
  this.sync(self);
}

fan.fwt.TablePeer.prototype.sync = function(self)
{
  // init hook
  if (this.selection == null)
  {
    if (this.selected == null)
      this.selected = fan.sys.List.make(fan.sys.Type.find("sys::Int"), []);
    this.selection = new fan.fwt.TableSelection(self);
  }

  // build new content
  var tbody = document.createElement("tbody");
  var model = self.model;
  var rows  = model.numRows();
  var cols  = model.numCols();

  if (this.headerVisible)
  {
    var tr = document.createElement("tr");
    for (var c=-1; c<cols; c++)
    {
      // we have to embed a div inside our th to make
      // the borders overlap correctly
      var fix = document.createElement("div");
      with (fix.style)
      {
        padding      = "4px 6px";
        textAlign    = "left";
        whiteSpace   = "nowrap";
        borderBottom = "1px solid #555";
        backgroundColor = "#dbdbdb";
        // IE workaround
        try { backgroundImage = "-webkit-gradient(linear, 0% 0%, 0% 100%, from(#dbdbdb), to(#bbb))"; } catch (err) {} // ignore
        cursor = "default";
        if (c < cols-1) borderRight = "1px solid #a5a5a5";
        if (c < 0) height = "100%";
      }
      fix.appendChild(document.createTextNode(c<0? "/" : model.header(c)));
      var th = document.createElement("th");
      with (th.style)
      {
        margin  = "0px";
        padding = "0px";
        border  = "none";
        if (c == cols-1) width = "100%";
      }
      th.appendChild(fix);
      tr.appendChild(th);
    }
    tbody.appendChild(tr);
  }

  for (var r=0; r<rows; r++)
  {
    var tr = document.createElement("tr");
    if (r % 2 == 0) tr.style.background  = "#f1f5fa";

    for (var c=-1; c<cols; c++)
    {
      var td = document.createElement("td");
      with (td.style)
      {
        padding     = "4px 6px";
        textAlign   = "left";
        whiteSpace  = "nowrap";
        if (c < cols-1) borderRight = "1px solid #d9d9d9";
        else width = "100%";
      }
      if (c < 0)
      {
        // selection checkbox
        var cb = document.createElement("input");
        cb.type = "checkbox";
        var $this = this;
        cb.onclick = function(event) { $this.selection.toggle(event ? event : window.event) };
        td.appendChild(cb);
      }
      else
      {
        var widget = null;
        if (model.widget) widget = model.widget(c,r);
        if (widget == null)
        {
          // normal text node
          td.appendChild(document.createTextNode(model.text(c,r)));
        }
        else
        {
          // custom widget
          if (widget.peer.elem != null)
          {
            // detach and reattach in case it moved
            widget.peer.elem.parentNode.removeChild(widget.peer.elem);
            td.appendChild(widget.peer.elem);
          }
          else
          {
            // attach new widget
            var elem = widget.peer.create(td);
            widget.peer.attachTo(widget, elem);
            // nuke abs positiong
            with (elem.style)
            {
              position = "static";
              left     = null;
              top      = null;
              width    = null;
              height   = null;
            }
          }
        }
      }
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  }

  // replace tbody
  var table = this.elem.firstChild;
  if (table.firstChild != null)
    table.removeChild(table.firstChild);
  table.appendChild(tbody);

  // no border if content not visible
  if (this.size.w == 0 || this.size.h == 0)
    this.elem.style.borderWidth = "0px";
  else
    this.elem.style.borderWidth = "1px";

  // sync selection
  this.selection.select(this.selected);

  // account for border
  var w = this.size.w - 2;
  var h = this.size.h - 2;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);
}

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

fan.fwt.TableSelection = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.TableSelection.prototype.$ctor = function(table) { this.table = table; }

fan.fwt.TableSelection.prototype.toggle = function(event)
{
  // TODO - support multiple selection
  //if (this.table.multi)
  //{
  //}
  //else
  //{
    var target = event.target ? event.target : event.srcElement;
    var on  = target.checked;
    var tr  = target.parentNode.parentNode;
    var row = tr.rowIndex;
    if (this.table.peer.headerVisible) row--; // account for th row
    this.table.peer.selected = this.select(on ? [row] : []);
    this.notify(row);
  //}
}

fan.fwt.TableSelection.prototype.select = function(rows)
{
  var selected = [];
  var tbody = this.table.peer.elem.firstChild.firstChild;
  var start = this.table.peer.headerVisible ? 1 : 0; // skip th row
  for (var i=start; i<tbody.childNodes.length; i++)
  {
    var row = i-start;
    var tr  = tbody.childNodes[i];
    var on  = false;

    var len = rows.length;
    if (len > 1 && !this.table.multi) len = 1;
    for (var s=0; s<len; s++)
      if (row == rows[s])
      {
        on = true;
        selected.push(row);
        break;
      }

    var bg = on ? "#3d80df" : (row%2==0 ? "#f1f5fa" : "")
    var fg = on ? "#fff"    : "";
    var br = on ? "#346dbe" : "#d9d9d9";

    tr.firstChild.firstChild.checked = on;
    tr.style.background = bg;
    tr.style.color = fg;
    for (var c=0; c<tr.childNodes.length-1; c++)
      tr.childNodes[c].style.borderColor = br;
  }
  return selected;
}

fan.fwt.TableSelection.prototype.notify = function(primaryIndex)
{
  if (this.table.onSelect.size() > 0)
  {
    var se   = fan.fwt.Event.make();
    se.id    = fan.fwt.EventId.select;
    se.index = primaryIndex;
    var listeners = this.table.onSelect.list();
    for (var i=0; i<listeners.length; i++) fan.sys.Func.call(listeners[i], se);
  }
}

