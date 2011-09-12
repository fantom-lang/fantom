//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 11  Brian Frank  Creation
//

/**
 * ClipboardPeer.
 */
fan.fwt.ClipboardPeer  = fan.sys.Obj.$extend(fan.sys.Obj);
fan.fwt.ClipboardPeer.prototype.$ctor = function(self) {}

fan.fwt.ClipboardPeer.prototype.getText = function(self)
{
  throw fan.sys.UnsupportedErr.make("Clipboard.getText");
}

fan.fwt.ClipboardPeer.prototype.setText = function(self, data)
{
  throw fan.sys.UnsupportedErr.make("Clipboard.setText");
}