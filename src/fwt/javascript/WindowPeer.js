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

fwt_WindowPeer.prototype.relayout = function(self)
{
  self.peer.size$set(gfx_Size.make(this.shell.offsetWidth, this.shell.offsetHeight));
  fwt_PanePeer.prototype.relayout.call(this, self);
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
    background = "#fff";
  }
  document.body.appendChild(shell);

  // mount window
  self.peer.shell = shell;
  this.attachTo(self, shell);
  self.relayout();
}


