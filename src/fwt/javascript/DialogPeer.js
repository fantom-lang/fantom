//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * DialogPeer.
 */
var fwt_DialogPeer = sys_Obj.$extend(fwt_WindowPeer);
fwt_DialogPeer.prototype.$ctor = function(self) {}

fwt_DialogPeer.prototype.open = function(self)
{
  /*
  // mount shell we use to attach widgets to
  var shell = document.createElement("div")
  with (shell.style)
  {
    position   = "fixed";
    top        = "0";
    left       = "0";
    width      = "100%";
    height     = "100%";
    background = "#fff";
  }

  // mount window
  var elem = this.emptyDiv();
  shell.appendChild(elem);
  this.attachTo(self, elem);
  document.body.appendChild(shell);
  self.relayout();
  */

  alert("Dialog.open");
}

fwt_DialogPeer.prototype.sync = function(self)
{
  //var shell = this.elem.parentNode;
  //this.size$set(this, gfx_Size.make(shell.offsetWidth, shell.offsetHeight));
  fwt_WidgetPeer.prototype.sync.call(this, self);
}

