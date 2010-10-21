//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 09  Andy Frank  Creation
//

//
// TableModel extensions
//
//  fan.fwt.TableModel.prototype.$uri = function(col,row) { return null; }
//  fan.fwt.TableModel.prototype.$onMouseDown = function(col,row) {}
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

/**
 * Inject table CSS.
 */
fan.fwt.TablePeer.injectCss = function()
{
  if (fan.fwt.TablePeer.hasCss == true) return;
  else fan.fwt.TablePeer.hasCss = true;

  fan.fwt.WidgetPeer.addCss(
    // th
    "table.__fwt_table th {" +
    " margin: 0px;" +
    " padding: 0px;" +
    " border: none;" +
    "}" +
    "table.__fwt_table th:last-child { width:100% }" +
    "table.__fwt_table th > div {" +
    " position:relative;" +
    " font: bold " + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFontSmall) + ";" +
    " padding: 3px 6px;" +
    " text-align: left;" +
    " white-space: nowrap;" +
    " border-right: 1px solid #bdbdbd;" +
    " border-bottom: 1px solid #5e5e5e;" +
    " cursor: default;" +
    " background: -moz-linear-gradient(top, #f9f9f9, #eee 50%, #e1e1e1 50%, #f5f5f5);" +
    " background: -webkit-gradient(linear, 0 0, 0 100%, color-stop(0,#f9f9f9), " +
    "   color-stop(0.5,#eee), color-stop(0.5,#e1e1e1), color-stop(1,#f5f5f5));" +
    "}" +
    "table.__fwt_table th:last-child > div { border-right:none; }" +
    "table.__fwt_table th:first-child > div { height: 100%; }" +
    // td
    "table.__fwt_table td {" +
    " padding: 3px 6px;" +
    " font: " + fan.fwt.WidgetPeer.fontToCss(fan.fwt.DesktopPeer.$sysFontView) + ";" +
    " text-align: left;" +
    " white-space: nowrap;" +
    " border-right: 1px solid #d9d9d9;" +
    "}" +
    "table.__fwt_table td:last-child {" +
    " width: 100%;" +
    " border-right: none;" +
    "}" +
    "table.__fwt_table td img { float:left; border:0; }" +
    "table.__fwt_table td span { margin-left: 3px; }" +
    "table.__fwt_table tr:nth-child(even) { background:#f1f5fa; }" +
    // selected
    "table.__fwt_table tr.selected { background:#3d80df; }" +
    "table.__fwt_table tr.selected td { color:#fff !important; border-color:#346dbe; }" +
    "table.__fwt_table tr.selected a { color:#fff; }");
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

fan.fwt.TablePeer.prototype.create = function(parentElem, self)
{
  // inject css if needed
  fan.fwt.TablePeer.injectCss();

  // make sure we force rebuild
  this.needRebuild = true;

  var table = document.createElement("table");
  table.className = "__fwt_table";
  var style = table.style;
  style.overflow = "auto";
  style.width  = "100%";
  style.borderSpacing = "0";

  var div = this.emptyDiv();
  style = div.style;
  style.border     = "1px solid #404040";
  style.overflow   = "auto";
  style.background = "#fff";

  var $this = this;
  table.addEventListener("mousedown", function(event) {
    $this.$onMouseDown(self, event);
  }, false);

  div.appendChild(table);
  parentElem.appendChild(div);
  return div;
}

fan.fwt.TablePeer.prototype.sort = function(self, col, mode)
{
  self.view().sort(col, mode);
  this.refreshAll(self);
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
  var view  = self.view();
  var rows  = view.numRows();
  var cols  = view.numCols();
  var sortCol = self.sortCol();

  if (this.m_headerVisible)
  {
    var tr = document.createElement("tr");
    for (var c=-1; c<cols; c++)
    {
      // we have to embed a div inside our th to make
      // the borders overlap correctly
      var fix = document.createElement("div");
      if (c < 0)
      {
        fix.innerHTML = "&nbsp;";
        var arrow  = this.makeArrowDown();
        arrow.style.top  = "9px";
        arrow.style.left = "14px";
        fix.appendChild(arrow);
        fix.onmousedown = function() { $this.support.popup(); }
      }
      else
      {
        var s = view.header(c);
        if (s.length == 0) fix.innerHTML = "&nbsp;"
        else fix.appendChild(document.createTextNode(s));
        var halign = view.halign(c);
        switch (halign)
        {
          case fan.gfx.Halign.m_left:   fix.style.textAlign = "left"; break;
          case fan.gfx.Halign.m_center: fix.style.textAlign = "center"; break;
          case fan.gfx.Halign.m_right:  fix.style.textAlign = "right"; break;
        }
        if (c === sortCol)
        {
          var down = self.sortMode() == fan.fwt.SortMode.m_down;
          var arrow  = this.makeArrowDown(down);
          arrow.style.top  = "9px";
          arrow.style.right = "9px";
          fix.style.paddingRight = "12px";
          fix.appendChild(arrow);
        }
      }
      var th = document.createElement("th");
      th.appendChild(fix);
      tr.appendChild(th);
    }
    tbody.appendChild(tr);
  }

  for (var r=0; r<rows; r++)
  {
    var tr = document.createElement("tr");
    for (var c=-1; c<cols; c++)
    {
      var td = document.createElement("td");
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
        var node = td;

        // cell hyperlink
        var uri = null;
        if (model.$uri) uri = model.$uri(view.m_cols.get(c), view.m_rows.get(r));
        if (uri != null)
        {
          var a = document.createElement("a");
          a.href = uri.encode();
          node.appendChild(a);
          node = a;
        }

        // cell image
        var img = view.image(c,r);
        if (img != null)
        {
          var imgElem = document.createElement("img");
          imgElem.src = fan.fwt.WidgetPeer.uriToImageSrc(img.m_uri);
          node.appendChild(imgElem);
        }

        // cell text
        var text = view.text(c,r);
        if (img != null && text.length > 0)
        {
          var span = document.createElement("span");
          span.appendChild(document.createTextNode(text));
          node.appendChild(span);
        }
        else node.appendChild(document.createTextNode(text));

        // style overrides
        var fg = view.fg(c,r); if (fg != null) td.style.color = fg.toCss();
        var bg = view.bg(c,r); if (bg != null) td.style.background = bg.toCss();
        var font = view.font(c,r); if (font != null) td.style.font = fan.fwt.WidgetPeer.fontToCss(font);
        var halign = view.halign(c);
        switch (halign)
        {
          case fan.gfx.Halign.m_left:   td.style.textAlign = "left"; break;
          case fan.gfx.Halign.m_center: td.style.textAlign = "center"; break;
          case fan.gfx.Halign.m_right:  td.style.textAlign = "right"; break;
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

  // sync selection
  this.selection.select(this.m_selected);
}

fan.fwt.TablePeer.prototype.$onMouseDown = function(self, event)
{
  var target = event.target;

  // header events
  if (target.tagName == "DIV") target = target.parentNode;
  if (target.tagName == "TH")
  {
    var col = target.cellIndex - 1;
    if (col < 0) return;

    var old = self.sortCol();
    var mode = old === col ? self.sortMode().toggle() : fan.fwt.SortMode.m_up;
    self.sort(col, mode);
  }

  // cell events
  if (target.tagName == "IMG") target = target.parentNode;
  if (target.tagName == "TD")
  {
    // find cell address
    var col = target.cellIndex - 1;
    var row = target.parentNode.rowIndex - 1;
    if (col < 0 || row < 0) return;

    // check for valid callback
    var model = self.m_model;
    var view  = self.view();
    if (!model.$onMouseDown) return;

    // find pos relative to widget
    var dis = this.posOnDisplay(self);
    var rel = fan.gfx.Point.make(event.clientX-dis.m_x, event.clientY-dis.m_y);

    // fire event
    var evt = fan.fwt.Event.make();
    evt.m_id = fan.fwt.EventId.m_mouseDown;
    evt.m_pos = rel;
    evt.m_widget = self;
    model.$onMouseDown(evt, view.m_cols.get(col), view.m_rows.get(row));
  }
}

fan.fwt.TablePeer.prototype.makeArrowDown = function(down)
{
  if (down === undefined) down = true;
  var s = down ? 0 : 2;
  var d = down ? 1 : -1;

  var div = document.createElement("div");
  div.style.position = "absolute";
  div.width  = "5px";
  div.height = "3px";

  var dot = null;
  dot = this.makeDot(); dot.style.top=""+s+"px"; dot.style.left="0px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top=""+s+"px"; dot.style.left="1px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top=""+s+"px"; dot.style.left="2px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top=""+s+"px"; dot.style.left="3px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top=""+s+"px"; dot.style.left="4px"; div.appendChild(dot);
  s += d;

  dot = this.makeDot(); dot.style.top=""+s+"px"; dot.style.left="1px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top=""+s+"px"; dot.style.left="2px"; div.appendChild(dot);
  dot = this.makeDot(); dot.style.top=""+s+"px"; dot.style.left="3px"; div.appendChild(dot);
  s += d;

  dot = this.makeDot(); dot.style.top=""+s+"px"; dot.style.left="2px"; div.appendChild(dot);
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
      // find cur selected rows
      list = [];
      var view = this.table.view();
      var orig = this.table.peer.m_selected.m_values;
      for (var i=0; i<orig.length; i++)
        for (var j=0; j<view.m_rows.size(); j++)
          if (orig[i] == view.m_rows.get(j))
            list.push(j);

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
  if (rows instanceof fan.sys.List) rows = rows.m_values;
  var selected = [];
  var view  = this.table.view();
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
        selected.push(view.m_rows.get(row));
        break;
      }

    tr.className = on ? "selected" : "";
    tr.firstChild.firstChild.checked = on;
  }
  selected.sort();
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
      var len  = table.view().numRows();
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

  if (table.view().numRows() == 0) xport.enabled$(false);

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

