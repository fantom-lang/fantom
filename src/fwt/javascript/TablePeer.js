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
var fwt_TablePeer = sys_Obj.$extend(fwt_WidgetPeer);
fwt_TablePeer.prototype.$ctor = function(self) {}

// TODO
//fwt_TablePeer.prototype.colAt = function(self, pos) {}
//fwt_TablePeer.prototype.rowAt = function(self, pos) {}
//fwt_TablePeer.prototype.refreshAll = function(self) {}
//fwt_TablePeer.prototype.selected ...

fwt_TablePeer.prototype.headerVisible$get = function(self) { return this.headerVisible; }
fwt_TablePeer.prototype.headerVisible$set = function(self, val) { this.headerVisible = val; }
fwt_TablePeer.prototype.headerVisible = true;

fwt_TablePeer.prototype.create = function(parentElem)
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

fwt_TablePeer.prototype.sync = function(self)
{
  // build new content
  var tbody = document.createElement("tbody");
  var model = self.model;
  var rows  = model.numRows();
  var cols  = model.numCols();

  if (this.headerVisible)
  {
    var tr = document.createElement("tr");
    for (var c=0; c<cols; c++)
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
        //cursor: default;
        if (c < cols-1) borderRight = "1px solid #a5a5a5";
      }
      fix.appendChild(document.createTextNode(model.header(c)));
      var th = document.createElement("th");
      with (th.style)
      {
        margin  = "0px";
        padding = "0px";
        border  = "none"; //Bottom = "1px solid #555";
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
    for (var c=0; c<cols; c++)
    {
      var td = document.createElement("td");
      with (td.style)
      {
        padding     = "4px 6px";
        textAlign   = "left";
        whiteSpace  = "nowrap";
        if (r % 2 == 0) background  = "#f1f5fa";
        if (c < cols-1) borderRight = "1px solid #d9d9d9";
      }
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
            position = null;
            left     = null;
            top      = null;
            width    = null;
            height   = null;
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

  // account for border
  var w = this.size.w - 2;
  var h = this.size.h - 2;
  fwt_WidgetPeer.prototype.sync.call(this, self, w, h);
}