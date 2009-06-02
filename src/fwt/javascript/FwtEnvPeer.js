//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Jun 09  Andy Frank  Creation
//

/**
 * FwtEnvPeer.
 */
var fwt_FwtEnvPeer = sys_Obj.$extend(sys_Obj);
fwt_FwtEnvPeer.prototype.$ctor = function(self) {}

//FwtEnvPeer.prototype.imageSize(Image i)
//FwtEnvPeer.prototype.imageResize(Image i, Size s)

fwt_FwtEnvPeer.prototype.fontHeight = function(self, font)  { return 10; }
fwt_FwtEnvPeer.prototype.fontAscent = function(self, font)  { return 10; }
fwt_FwtEnvPeer.prototype.fontDescent = function(self, font) { return 10; }
fwt_FwtEnvPeer.prototype.fontLeading = function(self, font) { return 10; }
fwt_FwtEnvPeer.prototype.fontWidth = function(self, font, str) { return str.length * 7; }

