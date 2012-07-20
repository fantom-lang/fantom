//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 09  Andy Frank  Creation
//

fan.webfwt.UploaderPeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.webfwt.UploaderPeer.prototype.$ctor = function(self) {}

fan.webfwt.UploaderPeer.prototype.submit = function(self, id)
{
  var form = document.getElementById(id);
  form.submit();
}

