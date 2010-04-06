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
fan.fwt.TablePeer.prototype.$ctor = function(self)
{
  this.m_selected = fan.sys.List.make(fan.sys.Int.$type, []);
  this.inPrefSize = false;
}

// TODO
//fan.fwt.TablePeer.prototype.colAt = function(self, pos) {}
//fan.fwt.TablePeer.prototype.rowAt = function(self, pos) {}

fan.fwt.TablePeer.prototype.m_headerVisible = true;
fan.fwt.TablePeer.prototype.headerVisible   = function(self) { return this.m_headerVisible; }
fan.fwt.TablePeer.prototype.headerVisible$  = function(self, val) { this.m_headerVisible = val; }

fan.fwt.TablePeer.prototype.m_selected = null;
fan.fwt.TablePeer.prototype.selected   = function(self) { return this.m_selected; }
fan.fwt.TablePeer.prototype.selected$  = function(self, val)
{
  this.m_selected = val;
  if (this.selection != null)
  {
    this.selection.select(val);
    if (val.size() > 0) this.selection.last = val.get(0);
  }
}

fan.fwt.TablePeer.prototype.prefSize = function(self, hints)
{
  this.inPrefSize = true;
  var pref = fan.fwt.WidgetPeer.prototype.prefSize.call(this, self, hints);
  this.inPrefSize = false;
  return pref;
}

fan.fwt.TablePeer.prototype.create = function(parentElem)
{
  // make sure we force rebuild
  this.needRebuild = true;

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
    border     = "1px solid #404040";
    overflow   = "auto";
    background = "#fff";
  }

  div.appendChild(table);
  parentElem.appendChild(div);
  return div;
}

fan.fwt.TablePeer.prototype.refreshAll = function(self)
{
  this.needRebuild = true;
  self.relayout();
}

fan.fwt.TablePeer.prototype.needRebuild = true;

fan.fwt.TablePeer.prototype.sync = function(self)
{
  // no border if content not visible
  if (this.m_size.m_w == 0 || this.m_size.m_h == 0 && !this.inPrefSize)
    this.elem.style.borderWidth = "0px";
  else
    this.elem.style.borderWidth = "1px";

  // account for border
  var w = this.m_size.m_w - 2;
  var h = this.m_size.m_h - 2;
  fan.fwt.WidgetPeer.prototype.sync.call(this, self, w, h);

  // check if table needs to be rebuilt
  if (this.needRebuild && w>0 && h>0)
  {
    this.rebuild(self);
    this.needRebuild = false;
  }
}

fan.fwt.TablePeer.prototype.rebuild = function(self)
{
  // init hook
  if (this.selection == null)
  {
    this.selection = new fan.fwt.TableSelection(self);
    this.support   = new fan.fwt.TableSupport(self);
  }

  // build new content
  var $this = this;
  var tbody = document.createElement("tbody");
  var model = self.m_model;
  var rows  = model.numRows();
  var cols  = model.numCols();
  var widgets = [];

  if (this.m_headerVisible)
  {
    var tr = document.createElement("tr");
    for (var c=-1; c<cols; c++)
    {
      // we have to embed a div inside our th to make
      // the borders overlap correctly
      var fix = document.createElement("div");
      with (fix.style)
      {
        position     = "relative";
        font         = "bold " + fan.fwt.WidgetPeer.fontSmall;
        padding      = "4px 6px";
        textAlign    = "left";
        whiteSpace   = "nowrap";
        borderBottom = "1px solid #404040";
        cursor = "default";
        if (c < cols-1) borderRight = "1px solid #a5a5a5";
        if (c < 0) height = "100%";
      }
      fan.fwt.WidgetPeer.setBg(fix, fan.gfx.Gradient.fromStr("0% 0%, 0% 100%, #dbdbdb, #bbb"));
      if (c < 0)
      {
        fix.innerHTML = "&nbsp;";
        var arrow  = this.makeArrowDown();
        arrow.style.top  = "10px";
        arrow.style.left = "14px";
        fix.appendChild(arrow);
        fix.onmousedown = function() { $this.support.popup(); }
      }
      else
      {
        var s = model.header(c);
        if (s.length == 0) fix.innerHTML = "&nbsp;"
        else fix.appendChild(document.createTextNode(s));
        var halign = model.halign(c);
        switch (halign)
        {
          case fan.gfx.Halign.m_left:   fix.style.textAlign = "left"; break;
          case fan.gfx.Halign.m_center: fix.style.textAlign = "center"; break;
          case fan.gfx.Halign.m_right:  fix.style.textAlign = "right"; break;
        }
      }
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
        padding    = "4px 6px";
        font       = fan.fwt.WidgetPeer.fontNormal;
        textAlign  = "left";
        whiteSpace = "nowrap";
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
        // always apply background override
        var bg = model.bg(c,r); if (bg != null) td.style.background = bg.toCss();

        var widget = null;
        if (model.widget) widget = model.widget(c,r);
        if (widget == null)
        {
          // normal text node
          td.appendChild(document.createTextNode(model.text(c,r)));

          // style overrides
          var fg = model.fg(c,r); if (fg != null) td.style.color = fg.toCss();
          var font = model.font(c,r); if (font != null) td.style.font = font.toStr();
          var halign = model.halign(c);
          switch (halign)
          {
            case fan.gfx.Halign.m_left:   td.style.textAlign = "left"; break;
            case fan.gfx.Halign.m_center: td.style.textAlign = "center"; break;
            case fan.gfx.Halign.m_right:  td.style.textAlign = "right"; break;
          }
        }
        else
        {
          // stash widget to add later
          widgets.push({ col:c, row:r, widget:widget });
        }
      }
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  }

  // replace tbody
  var table = this.elem.firstChild;
  var old = table.firstChild;
  if (old != null)
  {
    table.removeChild(old);
    old = null;
    delete old;
  }
  table.appendChild(tbody);

  // add widgets after tbody has been added so
  // prefSize will work correctly
  for (var i=0; i<widgets.length; i++)
  {
    var w = widgets[i];
    var tr = tbody.childNodes[w.row+1];
    var td = tr.childNodes[w.col+1];
    this.attachWidget(td, w.widget)
  }

  // sync selection
  this.selection.select(this.m_selected);
}

fan.fwt.TablePeer.prototype.attachWidget = function(td, widget)
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
    var elem = widget.peer.create(td, widget);
    widget.peer.attachTo(widget, elem);
    var pref = widget.prefSize();
    var w = pref.m_w;
    var h = pref.m_h;

    // TODO FIXIT: workaround for lazy-load of images and relayout
    if (widget instanceof fan.fwt.Label)
    {
      var img = widget.image();
      if (img != null)
      {
        var key = img.m_uri.toStr();
        var cached = fan.fwt.FwtEnvPeer.imgCache[key];
        if (cached && cached.width == 0)
        {
          w += 16;
          h = Math.max(h, 16);
        }
      }
    }

    // nuke abs positiong
    with (elem.style)
    {
      position = "static";
      left     = null;
      top      = null;
      width    = w + "px";
      height   = h + "px";
    }
  }
}

fan.fwt.TablePeer.prototype.makeArrowDown = function()
{
  var div = document.createElement("div");
  div.style.position = "absolute";
  div.width  = "5px";
  div.height = "3px";

  var dot = null;
  dot = this.makeDot(); dot.style.top="0px"; dot.style.left="0px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top="0px"; dot.style.left="1px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top="0px"; dot.style.left="2px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top="0px"; dot.style.left="3px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top="0px"; dot.style.left="4px"; div.appendChild(dot);

  dot = this.makeDot(); dot.style.top="1px"; dot.style.left="1px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top="1px"; dot.style.left="2px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top="1px"; dot.style.left="3px"; div.appendChild(dot);

  dot = this.makeDot(); dot.style.top="2px"; dot.style.left="2px"; div.appendChild(dot);
  return div;
}

fan.fwt.TablePeer.prototype.makeDot = function()
{
  var dot = document.createElement("div");
  dot.style.position   = "absolute";
  dot.style.width      = "1px";
  dot.style.height     = "1px";
  dot.style.background = "#404040";
  return dot;
}

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

fan.fwt.TableSelection = fan.sys.Obj.$extend(fan.fwt.WidgetPeer);
fan.fwt.TableSelection.prototype.$ctor = function(table)
{
  this.table = table;
  this.last = null;
}

fan.fwt.TableSelection.prototype.toggle = function(event)
{
  var target = event.target ? event.target : event.srcElement;
  var multi  = this.table.m_multi && (event.ctrlKey || event.metaKey || event.shiftKey);
  var on  = target.checked;
  var tr  = target.parentNode.parentNode;
  var row = tr.rowIndex;
  if (this.table.peer.m_headerVisible) row--; // account for th row
  var list = null;

  if (multi)
  {
    if (event.shiftKey && this.last != null)
    {
      list = [];
      var start = (this.last < row) ? this.last : row;
      var end   = (this.last < row) ? row : this.last;
      for (var i=start; i<=end; i++) list.push(i);
    }
    else
    {
      list = this.table.peer.m_selected.m_values;
      var found = false;
      for (var i=0; i<list.length; i++)
        if (list[i] == row)
          { list.splice(i,1); found=true; }
      if (!found) list.push(row);
      this.last = row;
    }
  }
  else
  {
    var hadMulti = this.table.m_multi && this.table.peer.m_selected.size() > 1;
    list = (on || hadMulti) ? [row] : [];
    this.last = row;
  }

  this.table.peer.m_selected = this.select(list);  // keep list sorted
  this.notify(row);
}

fan.fwt.TableSelection.prototype.select = function(rows)
{
  var selected = [];
  var tbody = this.table.peer.elem.firstChild.firstChild;
  var start = this.table.peer.m_headerVisible ? 1 : 0; // skip th row
  for (var i=start; i<tbody.childNodes.length; i++)
  {
    var row = i-start;
    var tr  = tbody.childNodes[i];
    var on  = false;

    var len = rows.length;
    if (len > 1 && !this.table.m_multi) len = 1;
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
  return fan.sys.List.make(fan.sys.Int.$type, selected);
}

fan.fwt.TableSelection.prototype.notify = function(primaryIndex)
{
  if (this.table.m_onSelect.size() > 0)
  {
    var se      = fan.fwt.Event.make();
    se.m_id     = fan.fwt.EventId.m_select;
    se.m_index  = primaryIndex;
    se.m_widget = this.table;
    var listeners = this.table.m_onSelect.list();
    for (var i=0; i<listeners.size(); i++) listeners.get(i).call(se);
  }
}

//////////////////////////////////////////////////////////////////////////
// TableSupport
//////////////////////////////////////////////////////////////////////////

fan.fwt.TableSupport = fan.sys.Obj.$extend(fan.sys.Obj);
fan.fwt.TableSupport.prototype.$ctor = function(table) { this.table = table; }

fan.fwt.TableSupport.prototype.popup = function()
{
  var $this = this;
  var table = this.table;

  var selectAll = fan.fwt.MenuItem.make();
  selectAll.text$("Select All");
  selectAll.onAction().add(fan.sys.Func.make(
    fan.sys.List.make(fan.sys.Param.$type, [new fan.sys.Param("it","fwt::Event",false)]),
    fan.sys.Void.$type,
    function(it)
    {
      var rows = [];
      var len  = table.model().numRows();
      for (var i=0; i<len; i++) rows.push(i);
      table.peer.m_selected = table.peer.selection.select(rows);
      table.peer.selection.notify(0);
    }));

  var selectNone = fan.fwt.MenuItem.make();
  selectNone.text$("Select None");
  selectNone.onAction().add(fan.sys.Func.make(
    fan.sys.List.make(fan.sys.Param.$type, [new fan.sys.Param("it","fwt::Event",false)]),
    fan.sys.Void.$type,
    function(it)
    {
      table.peer.m_selected = table.peer.selection.select([]);
      table.peer.selection.notify(0);
    }));

  var xport = fan.fwt.MenuItem.make();
  xport.text$("Export");
  xport.onAction().add(fan.sys.Func.make(
    fan.sys.List.make(fan.sys.Param.$type, [new fan.sys.Param("it","fwt::Event",false)]),
    fan.sys.Void.$type,
    function(it) { $this.exportTable(); }));

  if (!table.m_multi)
  {
    selectAll.enabled$(false);
    selectNone.enabled$(false);
  }

  if (table.model().numRows() == 0) xport.enabled$(false);

  var menu = fan.fwt.Menu.make();
  menu.add(selectAll);
  menu.add(selectNone);
  menu.add(xport);
  menu.open(table, fan.gfx.Point.make(0, 23));
}

fan.fwt.TableSupport.prototype.exportTable = function()
{
  // build csv str
  var str = "";
  var model = this.table.model();
  // headers
  for (var c=0; c<model.numCols(); c++)
  {
    if (c>0) str += ",";
    str += this.escape(model.header(c));
  }
  str += "\n";
  // rows
  for (var r=0; r<model.numRows(); r++)
  {
    for (var c=0; c<model.numCols(); c++)
    {
      if (c>0) str += ",";
      str += this.escape(model.text(c, r));
    }
    str += "\n";
  }

  // show in widget
  var text = fan.fwt.Text.make();
  text.m_multiLine = true;
  text.m_prefRows = 20;
  text.text$(str);

  var cons = fan.fwt.ConstraintPane.make();
  cons.m_minw = 650;
  cons.m_maxw = 650;
  cons.content$(text);

  var dlg = fan.fwt.Dialog.make(this.table.window());
  dlg.title$("Export");
  dlg.body$(cons);
  dlg.commands$(fan.sys.List.make(fan.sys.Obj.$type, [fan.fwt.Dialog.ok()]));
  dlg.open();
}

fan.fwt.TableSupport.prototype.escape = function(str)
{
  // convert " to ""
  str = str.replace(/\"/g, "\"\"");

  // check if need to wrap in quotes
  var wrap = str.search(/[,\n\" ]/) != -1;
  if (wrap) str = "\"" + str + "\"";

  return str;
}

