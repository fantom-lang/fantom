//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jun 2012  Andy Frank  Creation
//

/**
 * WebTablePeer.
 */
fan.webfwt.WebTablePeer = fan.sys.Obj.$extend(fan.fwt.TablePeer);
fan.webfwt.WebTablePeer.prototype.$ctor = function(self)
{
  fan.fwt.TablePeer.prototype.$ctor.call(this, self);
}

fan.webfwt.WebTablePeer.prototype.cellPos = function(self,col,row)
{
  return this.$cellPos(self, col, row);
}

fan.webfwt.WebTablePeer.prototype.scrollToBottom = function(self)
{
  this.elem.scrollTop = this.elem.scrollHeight;
  return self;
}

fan.webfwt.WebTablePeer.prototype.scrollTop  = function(self)
{
  return (this.elem === undefined) ? 0 : this.elem.scrollTop;
}
fan.webfwt.WebTablePeer.prototype.scrollTop$ = function(self, val)
{
  if (this.elem !== undefined) this.elem.scrollTop = val;
}
