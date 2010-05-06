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
**
** See [pod doc]`pod-doc#views` for details.
**
abstract class View : ContentPane
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor.
  **
  new make()
  {
    this.commandStack = CommandStack()
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the top level flux frame associated with this view.
  **
  Frame? frame { internal set }

  **
  ** Get the command history for undo/redo.
  **
  CommandStack commandStack
  {
    set { &commandStack = it; it.onModify.add {commandStackModified } }
  }
  internal Void commandStackModified() { frame?.commands?.updateEdit }

  **
  ** Current resource loaded into this view.
  **
  Resource? resource { internal set }

  **
  ** Reload this view.
  **
  Void reload()
  {
    if (frame.view !== this) throw Err("Current view not this")
    frame.load(resource.uri)
  }

  **
  ** The dirty state indicates if unsaved changes have been
  ** made to the view.  Views should set dirty to true on
  ** modification.  Dirty is automatically cleared `onSave`.
  **
  Bool dirty := false
  {
    set
    {
      if (&dirty == it) return
      &dirty = it
      tab?.onDirty(this, it)
    }
  }

//////////////////////////////////////////////////////////////////////////
// ToolBar/Menu Merging
//////////////////////////////////////////////////////////////////////////

  **
  ** Build a view specific toolbar to merge into the frame.
  ** This method is called after `onLoad`, but before mounting.
  ** Return null for no toolbar.  See `flux::Frame.command` if you
  ** wish to use predefined commands like cut/copy/paste.
  **
  virtual Widget? buildToolBar() { return null }

  **
  ** Build a view specific status bar to merge into the frame.
  ** This method is called after `onLoad`, but before mounting.
  ** Return null for no status bar.
  **
  virtual Widget? buildStatusBar() { return null }

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

  **
  ** Callback when the view is selected as the current tab.
  ** This method should be used to enable predefined commands
  ** such as find or replace which the view will handle.
  **
  virtual Void onActive() {}

  **
  ** Callback when the view is deactivated because the user
  ** has selected another tab.
  **
  virtual Void onInactive() {}

  **
  ** Callback when predefined view managed commands such as
  ** find and replace are invoked. Before view managed commands
  ** are routed to the view, they must be enabled in the onActive
  ** callback.  A convenient technique is to route to handler
  ** methods via trap:
  **
  **    trap("on${id.capitalize}", [event])
  **
  virtual Void onCommand(Str id, Event? event) {}

  **
  ** Callback when the frame's list of marks is updated.
  ** This callback can be used for the view to highlight
  ** mark locations.  The list of marks is the same as
  ** `flux::Frame.marks` and might contain marks outside of
  ** this view's uri.
  **
  virtual Void onMarks(Mark[] marks) {}

  **
  ** Callback when the view should jump to the specified
  ** mark.  The mark's uri will always be the same as this
  ** view's resource.  But the mark might also specify a
  ** specific line number and column number.
  **
  virtual Void onGotoMark(Mark mark) {}

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal ViewTab? tab
}