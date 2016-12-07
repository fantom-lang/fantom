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
//  fan.fwt.TableModel.prototype.$uriTarget = function(col,row) { return null; }
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
    " border-bottom: 1px solid #a9a9a9;" +
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
    " cursor: default;" +
    "}" +
    "table.__fwt_table td:last-child {" +
    " width: 100%;" +
    " border-right: none;" +
    "}" +
    "table.__fwt_table td img { float:left; border:0; width:16px; height:16px; }" +
    "table.__fwt_table td img.right { float:right }" +
    "table.__fwt_table td img + span { margin-left:3px; }" +
    "table.__fwt_table td img.right + span { margin-left:0; margin-right:6px; }" +
    "table.__fwt_table tr:nth-child(even) { background:#f1f5fa; }" +
    // selected
    "div.__fwt_table:focus { outline:0; }" +
    "div.__fwt_table:focus tr.selected { background:#3d80df; }" +
    "div.__fwt_table:focus tr.selected td { color:#fff !important; background:#3d80df !important; border-color:#346dbe; }" +
    "div.__fwt_table:focus tr.selected a { color:#fff; }" +
    "div.__fwt_table tr.selected { background:#cbcbcb; }" +
    "div.__fwt_table tr.selected td { color:#000 !important; background:#cbcbcb !important; border-color:#aaa; }" +
    "div.__fwt_table tr.selected a { color:#000; }");

  if (fan.fwt.DesktopPeer.$isIE || fan.fwt.DesktopPeer.$isFirefox)
    fan.fwt.WidgetPeer.addCss("table.__fwt_table td img + span { margin-right:16px; }");

  if (fan.fwt.DesktopPeer.$isIE)
    fan.fwt.WidgetPeer.addCss("table.__fwt_table td img.right + span { margin-right:25px; }");
}

fan.fwt.TablePeer.$blank     = fan.sys.Uri.fromStr("fan://fwt/res/img/blank16.png");
fan.fwt.TablePeer.$arrowUp   = fan.sys.Uri.fromStr("fan://fwt/res/img/arrowUp.png");
fan.fwt.TablePeer.$arrowDown = fan.sys.Uri.fromStr("fan://fwt/res/img/arrowDown.png");
fan.fwt.TablePeer.$imgClass  = [];

// TODO
//fan.fwt.TablePeer.prototype.colAt = function(self, pos) {}
//fan.fwt.TablePeer.prototype.rowAt = function(self, pos) {}

fan.fwt.TablePeer.prototype.$cellPos = function(self, col, row)
{
  // check args
  var model = self.m_model;
  if (col >= model.numCols()) throw fan.sys.ArgErr.make("col out of bounds");
  if (row >= model.numRows()) throw fan.sys.ArgErr.make("row out of bounds");

  // find cell
  if (this.m_headerVisible) row++;
  var div   = this.elem;
  var table = this.elem.firstChild;
  var tr    = table.rows[row]
  var td    = tr.cells[col]

  // find pos
  var x = td.offsetLeft - div.scrollLeft;
  var y = tr.offsetTop  - div.scrollTop;
  return fan.gfx.Point.make(x,y);
}

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
  div.className = "__fwt_table";
  div.tabIndex = 0;
  style = div.style;
  style.border     = "1px solid #9f9f9f";
  style.overflow   = "auto";
  style.background = "#fff";

  var $this = this;
  div.addEventListener("mousedown", function(event) {
    if (event.target !== div) return;
// TODO FIXIT: ignore scrollbar presses
if (div.offsetWidth  - event.clientX < 20) return;
if (div.offsetHeight - event.clientY < 20) return;

    $this.m_selected = $this.selection.select([]);
    $this.selection.notify(null);
  });

  table.addEventListener("mousedown", function(event)
  {
    var clicks = $this.m_mouseClicks;
    var xcur = event.clientX;
    var ycur = event.clientY;

    // init mouse clicks if not defined
    if (clicks == null)
    {
      clicks = {
        last: new Date().getTime(),
        x: xcur,
        y: ycur,
        cur:  0
      };
    }

    // verify pos and frequency
    var now  = new Date().getTime();
    var diff = now - clicks.last;
    if (diff < 600 && clicks.x == xcur && clicks.y == ycur)
    {
      // increment click count
      clicks.cur++;
    }
    else
    {
      // reset handler
      clicks.x = xcur;
      clicks.y = ycur;
      clicks.cur = 1;
    }

    clicks.last = now;
    $this.m_mouseClicks = clicks;
    $this.$onMouseDown(self, event, clicks.cur);
  }, false);

  div.addEventListener("keydown", function(event) {
    $this.$onKeyDown(self, event);
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

fan.fwt.TablePeer.prototype.refreshRows = function(self, indices)
{
  this.refreshAll(self);
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

  // used for firefox workaround
  var isWebkit  = fan.fwt.DesktopPeer.$isWebkit;
  var isChrome  = fan.fwt.DesktopPeer.$isChrome;
  var isFirefox = fan.fwt.DesktopPeer.$isFirefox;

  // build new content
  var $this = this;
  var tbody = document.createElement("tbody");
  var model = self.m_model;
  var view  = self.view();
  var rows  = view.numRows();
  var cols  = view.numCols();
  var sortCol = self.sortCol();
  var blank = fan.fwt.WidgetPeer.uriToImageSrc(fan.fwt.TablePeer.$blank);

  if (this.m_headerVisible)
  {
    var tr = document.createElement("tr");
    tr.oncontextmenu = function(e) { $this.support.popup(e); return false; }
    for (var c=0; c<cols; c++)
    {
      // we have to embed a div inside our th to make
      // the borders overlap correctly
      var fix = document.createElement("div");
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
        var arrow  = this.makeArrow(down);
        arrow.style.top  = "7px";
        arrow.style.right = "4px";
        fix.style.paddingRight = "16px";
        fix.appendChild(arrow);
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
    for (var c=0; c<cols; c++)
    {
      var td = document.createElement("td");
      var node = td;

      // cell hyperlink
      var uri = null;
      if (model.$uri) uri = model.$uri(view.m_cols.get(c), view.m_rows.get(r));
      if (uri != null)
      {
        var a = document.createElement("a");
        a.href = uri.encode();

        var target = null;
        if (model.$uriTarget) target = model.$uriTarget(view.m_cols.get(c), view.m_rows.get(r));
        if (target != null) a.target = target;

        node.appendChild(a);
        node = a;
      }

      // cell image
      var imgElem = null;
      var img = view.image(c,r);
      if (img != null)
      {
        imgElem = document.createElement("img");
        imgElem.src = blank;
        imgElem.style.backgroundImage = "url(" + fan.fwt.WidgetPeer.uriToImageSrc(img.m_uri) + ")";
        imgElem.style.backgroundSize = "16px 16px";
        imgElem.width  = 16;
        imgElem.height = 16;

        // check for imageSel
        if (model.$imageSel)
        {
          var sel = model.$imageSel(view.m_cols.get(c), view.m_rows.get(r));
          if (sel != null)
          {
            var name = "sel_" + sel.m_uri.basename();
            if (fan.fwt.TablePeer.$imgClass[name] == null)
            {
              var cls = "div.__fwt_table:focus tr.selected td img." + name + " {" +
               " background-image: url(" + fan.fwt.WidgetPeer.uriToImageSrc(sel.m_uri) + ")" +
               " !important; }";
              fan.fwt.WidgetPeer.addCss(cls);
              fan.fwt.TablePeer.$imgClass[name] = true;
            }
            fan.fwt.WidgetPeer.addClassName(imgElem, name);
          }
        }

        // image align
        var halignImg = fan.gfx.Halign.m_left;
        if (model.$halignImage) halignImg = model.$halignImage(view.m_cols.get(c));
        if (halignImg === fan.gfx.Halign.m_right) fan.fwt.WidgetPeer.addClassName(imgElem, "right");
      }

      // cell text
      var text = view.text(c,r);
      var addTextNode = function(n,t)
      {
        if (t == "") n.innerHTML = "&nbsp;"
        else n.appendChild(document.createTextNode(t));
      }
      if (imgElem == null) addTextNode(node, text);
      else
      {
        node.appendChild(imgElem);
        if (text.length > 0)
        {
          var span = document.createElement("span");

          // workaround for Webkit float "bug"
          if (isWebkit)
            span.style.paddingRight = "16px";

          // workaround for Firefox float "bug"
          else if (isFirefox && imgElem.className == "right")
            span.style.marginRight = "22px";

          addTextNode(span, text);
          node.appendChild(span);
        }
      }

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

  // sync selection - must map row model back to view in case sorted
  var sel = [];
  var selLen=this.m_selected.size();
  for (var i=0; i<selLen; i++) {
    sel[i] = view.rowModelToView(this.m_selected.get(i));
  }
  this.selection.select(sel);
}

fan.fwt.TablePeer.prototype.$onMouseDown = function(self, event, count)
{
  var target = event.target;

  // header events
  if (target.tagName == "DIV") target = target.parentNode;
  if (target.tagName == "TH")
  {
    if (event.button != 0 || event.ctrlKey) return;
    var col = target.cellIndex
    var old = self.sortCol();
    var mode = old === col ? self.sortMode().toggle() : fan.fwt.SortMode.m_up;
    self.sort(col, mode);
    return;
  }

  // cell events
  if (target.tagName == "IMG")  target = target.parentNode;
  if (target.tagName == "SPAN") target = target.parentNode;
  if (target.tagName == "TD")
  {
    var model = self.m_model;
    var view  = self.view();

    // find cell address
    var col = target.cellIndex;
    var row = target.parentNode.rowIndex;
    if (this.m_headerVisible) row--;
    if (row < 0) return;

    // select row
    this.selection.addSelection(event, row);

    // handle onAction event
    if (count == 2)
    {
      var ae = fan.fwt.Event.make();
      ae.m_id = fan.fwt.EventId.m_action;
      ae.m_widget = self;
      ae.m_index = view.m_rows.get(row);
      self.onAction().fire(ae);
      return;
    }

    // check for valid callback
    if (!model.$onMouseDown && !self.onCellMouseDown) return;

    // find pos on display
    var dis = this.posOnDisplay(self);
    var posOnDis = fan.gfx.Point.make(event.clientX-dis.m_x, event.clientY-dis.m_y);

    // find pos relative to cell
    var div   = this.elem;
    var table = div.firstChild;
    var tr  = table.rows[row + (this.m_headerVisible ? 1 : 0)];
    var td  = tr.cells[col];
    var rx  = posOnDis.m_x - td.offsetLeft + div.scrollLeft;
    var ry  = posOnDis.m_y - tr.offsetTop  + div.scrollTop;
    var rel = fan.gfx.Point.make(rx, ry);

    // data map
    var data = fan.sys.Map.make(fan.sys.Str.$type, fan.sys.Obj.$type);
    data.set("posOnDisplay", posOnDis);
    data.set("cellSize",     fan.gfx.Size.make(td.offsetWidth, td.offsetHeight));
    data.set("col", view.m_cols.get(col));
    data.set("row", view.m_rows.get(row));

    // fire event
    var evt = fan.fwt.Event.make();
    evt.m_id = fan.fwt.EventId.m_mouseDown;
    evt.m_pos = rel;
    evt.m_widget = self;
    evt.m_index = row;
    evt.m_data = data;
    if (model.$onMouseDown) model.$onMouseDown(evt, view.m_cols.get(col), view.m_rows.get(row));
    if (self.onCellMouseDown) self.onCellMouseDown().fire(evt);
  }
}

fan.fwt.TablePeer.prototype.$onKeyDown = function(self, event)
{
  // only handle up/down/space
  var key = event.keyCode;
  if (key != 38 && key != 40 && key != 32) return;

  // consume event
  event.stopPropagation();
  event.preventDefault();

  // if table is empty, short-circuit here
  var rows = self.model().numRows();
  if (self.model().numRows() == 0) return;

  // update new selection
  var sel   = self.selected();
  var list  = sel.m_values;
  var first = sel.first();
  var last  = sel.last();
  var shift = event.shiftKey;

  if (sel.size() == 0)
  {
    list = [0];
    this.keySelPivot = 0;
  }
  else if (!shift)
  {
         if (key == 38) list = [Math.max(0, first-1)];
    else if (key == 40) list = [Math.min(first+1, rows-1)];
    else if (key == 32)
    {
      var ae = fan.fwt.Event.make();
      ae.m_id = fan.fwt.EventId.m_action;
      ae.m_widget = self;
      ae.m_index = first;
      self.onAction().fire(ae);
    }
    this.keySelPivot = list[0];
  }
  else
  {
    if (sel.size() == 1) this.keySelPivot = first;
    if (key == 38)
    {
      if (last > this.keySelPivot) list = list.slice(0, -1);
      else { if (first-1 >= 0) list.push(first-1); }
    }
    else if (key == 40)
    {
      if (first < this.keySelPivot) list = list.slice(1, list.length);
      else  { if (last+1 < rows) list.push(last+1); }
    }

  }

  this.m_selected = fan.sys.List.make(fan.sys.Int.$type, list).sort();
  this.selection.select(this.m_selected);
  this.selection.notify(this.m_selected.first());
}

fan.fwt.TablePeer.prototype.makeArrow = function(down)
{
  if (down === undefined) down = true;

  var uri = down ? fan.fwt.TablePeer.$arrowDown : fan.fwt.TablePeer.$arrowUp
  var img = document.createElement("img");
  img.src = fan.fwt.WidgetPeer.uriToImageSrc(uri);
  img.style.position = "absolute";
  img.style.width = "8px";
  img.style.height = "7px";
  return img;
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

fan.fwt.TableSelection.prototype.addSelection = function(event, row)
{
  var multi = this.table.m_multi && (event.ctrlKey || event.metaKey || event.shiftKey);
  var list = null

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

    // clear selection
    window.getSelection().removeAllRanges();
  }
  else
  {
    if (this.table.peer.m_selected.first == row) return;
    list = [row];
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
  if (tbody == null || tbody.childNodes == null) {
    return fan.sys.List.make(fan.sys.Int.$type, selected);
  }
  var start = this.table.peer.m_headerVisible ? 1 : 0; // skip th row
  var first = null;
  var last  = null;
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
        if (first == null) first = tr;
        last = tr;
        on = true;
        selected.push(view.m_rows.get(row));
        break;
      }

    tr.className = on ? "selected" : "";
    tr.firstChild.firstChild.checked = on;
  }

  if (first != null && first == last)
  {
    var div = tbody.parentNode.parentNode;
    var et = first.offsetTop;
    var eh = first.offsetHeight;
    var cs = div.scrollTop;
    var ch = div.offsetHeight;
    if (et < cs) first.scrollIntoView(true);
    else if ((et+eh) > (cs+ch)) first.scrollIntoView(false);
  }

  selected.sort();
  return fan.sys.List.make(fan.sys.Int.$type, selected);
}

fan.fwt.TableSelection.prototype.notify = function(primaryIndex)
{
  if (this.table.onSelect().size() > 0)
  {
    var se      = fan.fwt.Event.make();
    se.m_id     = fan.fwt.EventId.m_select;
    se.m_index  = primaryIndex;
    se.m_widget = this.table;
    var listeners = this.table.onSelect().list();
    for (var i=0; i<listeners.size(); i++) listeners.get(i).call(se);
  }
}

//////////////////////////////////////////////////////////////////////////
// TableSupport
//////////////////////////////////////////////////////////////////////////

fan.fwt.TableSupport = fan.sys.Obj.$extend(fan.sys.Obj);
fan.fwt.TableSupport.prototype.$ctor = function(table) { this.table = table; }

fan.fwt.TableSupport.prototype.popup = function(e)
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
  xport.text$("Show CSV");
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

  // clear selection
  window.getSelection().removeAllRanges();

  var dis  = table.peer.posOnDisplay(table);
  var mx   = e.clientX - dis.m_x;
  var my   = e.clientY - dis.m_y;

  // open menu
  var menu = fan.fwt.Menu.make();
  menu.add(selectAll);
  menu.add(selectNone);
  menu.add(xport);
  menu.open(table, fan.gfx.Point.make(mx, my));
}

fan.fwt.TableSupport.prototype.exportTable = function()
{
  var buf = fan.sys.StrBuf.make();
  var csv = fan.util.CsvOutStream.make(buf.out());

  // headers
  var model = this.table.model();
  var row   = fan.sys.List.make(fan.sys.Str.$type);
  for (var c=0; c<model.numCols(); c++) row.add(model.header(c));
  csv.writeRow(row);

  // rows
  for (var r=0; r<model.numRows(); r++)
  {
    row.clear();
    for (var c=0; c<model.numCols(); c++) row.add(model.text(c, r));
    csv.writeRow(row);
  }

  // show in widget
  var text = fan.fwt.Text.make();
  text.m_multiLine = true;
  text.m_prefRows = 20;
  text.text$(buf.toStr());

  var cons = fan.fwt.ConstraintPane.make();
  cons.m_minw = 650;
  cons.m_maxw = 650;
  cons.content$(text);

  var dlg = fan.fwt.Dialog.make(this.table.window());
  dlg.title$("Show CSV");
  dlg.body$(cons);
  dlg.commands$(fan.sys.List.make(fan.sys.Obj.$type, [fan.fwt.Dialog.ok()]));
  dlg.open();
}
