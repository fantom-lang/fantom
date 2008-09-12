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
  ** Get the top level flux window.
  **
  Frame frame() { return (Frame)window }

  **
  ** Get the command history for undo/redo.
  **
  CommandStack commandStack := CommandStack { onModify.add(&commandStackModified) }
  internal Void commandStackModified() { frame?.commands?.updateEdit }

  **
  ** Get the parent view tab.
  **
  internal ViewTab viewTab() { return parent as ViewTab }

  **
  ** Current resource loaded into this view.
  **
  readonly Resource resource

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
      viewTab?.onDirty(this, val)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  **
  ** Load the specified resource.
  **
  internal Void load(Resource r)
  {
    resource = r
    onLoad
  }

  **
  ** Save the specified resource.
  **
  internal Void save()
  {
    if (!dirty) return
    onSave
    dirty = false
  }

  **
  ** Callback to load the `resource`.
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