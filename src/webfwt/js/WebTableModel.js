//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Apr 10  Andy Frank  Creation
//

// background hooks to plug into fwt::TableModel

fan.webfwt.WebTableModel.prototype.$halignImage = function(col)
{
  return this.halignImage(col);
}

fan.webfwt.WebTableModel.prototype.$imageSel = function(col,row)
{
  return this.imageSel(col, row);
}

fan.webfwt.WebTableModel.prototype.$uri = function(col,row)
{
  return this.uri(col, row);
}

fan.webfwt.WebTableModel.prototype.$uriTarget = function(col,row)
{
  return this.uriTarget(col, row);
}

fan.webfwt.WebTableModel.prototype.$onMouseDown = function(event,col,row)
{
  this.onMouseDown(event, col, row);
}

