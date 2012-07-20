//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Sep 2011  Andy Frank  Creation
//

/**
 * WebTextPeer.
 */
fan.webfwt.WebTextPeer = fan.sys.Obj.$extend(fan.fwt.TextPeer);
fan.webfwt.WebTextPeer.prototype.$ctor = function(self)
{
  fan.fwt.TextPeer.prototype.$ctor.call(this, self);
}

// backdoor hook to override style
fan.webfwt.WebTextPeer.prototype.$style = function(self) { return self.m_style; }
fan.webfwt.WebTextPeer.prototype.$disabledStyle = function(self) { return self.m_disabledStyle; }

// backdoor hook to add placeholder text
fan.webfwt.WebTextPeer.prototype.$placeHolder = function(self) { return self.m_placeHolder; }

