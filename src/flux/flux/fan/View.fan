//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** View is a plugin designed to view or edit a `Resource`.
** See `docLib::Flux` for details.
**
abstract class View : ContentPane
{

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the top level flux frame associated with this view.
  **
  Frame frame { internal set }

  **
  ** Get the command history for undo/redo.
  **
  CommandStack commandStack := CommandStack { onModify.add(&commandStackModified) }
  internal Void commandStackModified() { frame?.commands?.updateEdit }

  **
  ** Current resource loaded into this view.
  **
  Resource resource { internal set }

  **
  ** The dirty state indicates if unsaved changes have been
  ** made to the view.  Views should set dirty to true on
  ** modification.  Dirty is automatically cleared `onSave`.
  **
  Bool dirty := false
  {
    set
    {
      if (@dirty == val) return
      @dirty = val
      tab?.onDirty(this, val)
    }
  }

//////////////////////////////////////////////////////////////////////////
// ToolBar/Menu Merging
//////////////////////////////////////////////////////////////////////////

  **
  ** Build a view specific toolbar to merge into the frame.
  ** This method is called after `onLoad`, but before mounting.
  ** Return null for no toolbar.  See `Frame.command` if you
  ** wish to use predefined commands like cut/copy/paste.
  **
  virtual Widget buildToolBar() { return null }

  **
  ** Build a view specific status bar to merge into the frame.
  ** This method is called after `onLoad`, but before mounting.
  ** Return null for no status bar.
  **
  virtual Widget buildStatusBar() { return null }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  **
  ** Callback to load the `resource`.  At this point the
  ** view can access `frame`, but has not been mounted yet.
  **
  abstract Void onLoad()

  **
  ** Callback to save the view's modification to the `resource`.
  ** Save is only called for a dirty view.
  **
  virtual Void onSave() {}

  **
  ** Callback when the view is being unloaded.
  **
  virtual Void onUnload() {}

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal ViewTab tab
}