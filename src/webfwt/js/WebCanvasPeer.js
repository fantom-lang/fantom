//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Sep 2011  Andy Frank  Creation
//

/**
 * WebCanvasPeer.
 */
fan.webfwt.WebCanvasPeer = fan.sys.Obj.$extend(fan.fwt.CanvasPeer);
fan.webfwt.WebCanvasPeer.prototype.$ctor = function(self) {}

fan.webfwt.WebCanvasPeer.prototype.clearOnRepaint = function(self) { return this.m_clearOnRepaint; }
fan.webfwt.WebCanvasPeer.prototype.clearOnRepaint$ = function(self, val) { this.m_clearOnRepaint = val; }
fan.webfwt.WebCanvasPeer.prototype.m_clearOnRepaint = true;
