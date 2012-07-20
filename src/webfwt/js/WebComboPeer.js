//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Dec 2011  Andy Frank  Creation
//

/**
 * WebComboPeer.
 */
fan.webfwt.WebComboPeer = fan.sys.Obj.$extend(fan.fwt.ComboPeer);
fan.webfwt.WebComboPeer.prototype.$ctor = function(self)
{
  fan.fwt.ComboPeer.prototype.$ctor.call(this, self);
}

// backdoor hook to override item text
fan.webfwt.WebComboPeer.prototype.$itemText = function(self, item)
{
  return self.itemText(item);
}
