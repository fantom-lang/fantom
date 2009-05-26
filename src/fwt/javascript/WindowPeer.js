//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * WindowPeer.
 */
var fwt_WindowPeer = sys_Obj.$extend(fwt_PanePeer);

fwt_WindowPeer.prototype.$ctor = function(self)
{
  fwt_PanePeer.prototype.$ctor.call(this, self);
}

fwt_WindowPeer.prototype.open = function(self)
{
  // mount shell we use to attach widgets to
  var shell = document.createElement("div")
  with (shell.style)
  {
    position   = "fixed";
    top        = "0";
    left       = "0";
    width      = "100%";
    height     = "100%";
    background = "#f00";
  }
  document.body.appendChild(shell);

  // mount window
  this.attachTo(self, shell);
  self.peer.size$set(gfx_Size.make(shell.offsetWidth, shell.offsetHeight));
  self.relayout();
}


