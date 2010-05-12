//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Jul 08  Brian Frank  Creation
//

using concurrent
using gfx
using fwt

**
** ViewTab manages the history and state of a single view tab.
**
internal class ViewTab : EdgePane
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(Frame frame)
  {
    this.frame = frame
    this.view = ErrView("init")  // dummy startup view
    this.view.tab = this
  }

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  Void load(Uri uri, LoadMode mode)
  {
    try
    {
      r := loadResource(uri)
      v := loadView(r)
      doOnLoad(v, r)
      doLoad(r, v, mode)
    }
    catch (ViewLoadErr err)
      loadErr(ErrResource(uri), err.msg, mode, err.cause)
    catch (Err err)
      loadErr(ErrResource(uri), "Cannot load view", mode, err)
  }

  private Resource loadResource(Uri uri)
  {
    try
      return Resource.resolve(uri)
    catch (UnresolvedErr err)
      throw ViewLoadErr("Resource not found", err)
    catch (UnsupportedErr err)
      throw ViewLoadErr("Resource type not supported", err)
  }

  private View loadView(Resource r)
  {
    // check for explicit view query param, otherwise
    // default to first registered view on resource type
    Type? viewType
    qname := r.uri.query["view"]
    if (qname != null)
    {
      viewType = Type.find(qname, false)
      if (viewType == null) throw ViewLoadErr("Unknown view type '$qname'")
    }
    else
    {
      viewType = r.views.first
      if (viewType == null) throw ViewLoadErr("No views registered")
    }

    // create view
    view := viewType.make as View
    if (view == null) throw ViewLoadErr("Incorrect view type: '$viewType' is not 'flux::View'")
    return view
  }

  private Void loadErr(Resource r, Str msg, LoadMode mode, Err? cause := null)
  {
    view := ErrView(msg, cause)
    doOnLoad(view, r)
    doLoad(r, view, mode)
  }

  private Void doOnLoad(View view, Resource r)
  {
    view.frame = frame
    view.tab = this
    view.resource = r
    view.onLoad
  }

  private Void doLoad(Resource r, View newView, LoadMode mode)
  {
    if ((Obj?)newView == null) throw ArgErr("newView is null")
    oldView := this.view

    // suspend dirty handling
    ignoreDirty = true

    // unload old view
    deactivate
    try { oldView.onUnload  } catch (Err e) { e.trace }
    oldView.tab = null
    oldView.frame = null
    oldView.resource = null

    // add to histories
    if (mode.addToHistory)
    {
      // add old resource to tab bac/forward history
      if (resource != null)
      {
        push(historyBack, resource)
        historyForward.clear
      }

      // add to most recent history
      History.load.push(r).save
    }

    // update my state
    this.text  = r.name
    this.image = r.icon
    this.resource = r
    this.view = newView
    this.top = doBuildToolBar(newView)
    this.center = newView
    this.bottom = doBuildStatusBar(newView)
    loadCommandStack
    parent?.relayout

    // resume dirty handling
    newView.dirty = false
    ignoreDirty = false

    // update frame
    frame.locator.load(r)
    frame.commands.update
    activate
  }

  Widget? doBuildToolBar(View v)
  {
    try
    {
      return v.buildToolBar
    }
    catch (Err e)
    {
      e.trace
      return null
    }
  }

  Widget? doBuildStatusBar(View v)
  {
    try
    {
      return v.buildStatusBar
      /*
      sb := v.buildStatusBar
      return sb
      //if (sb == null) return sb
      //return EdgePane { top = StatusBarBorder(); bottom = sb }
      */
    }
    catch (Err e)
    {
      e.trace
      return null
    }
  }

  private Void dumpHistory()
  {
    echo("===============")
    historyBack.each |Resource x| { echo("    $x.uri") }
    echo("--> $resource.uri")
    historyForward.eachr |Resource x| { echo("    $x.uri") }
  }

//////////////////////////////////////////////////////////////////////////
// Activation
//////////////////////////////////////////////////////////////////////////

  Void activate()
  {
    frame.title = "Flux - $text"
    frame.commands.update
    if (resource != null) frame.locator.load(resource)
    try { view.onActive } catch (Err e) { e.trace }
    if (view isnot ErrView) frame.sideBarPane.onActive(view)
  }

  Void deactivate()
  {
    try { view.onInactive } catch (Err e) { e.trace }
    frame.commands.disableViewManaged
    if (view isnot ErrView) frame.sideBarPane.onInactive(view)
  }

//////////////////////////////////////////////////////////////////////////
// Command Undo/Redo Stack
//////////////////////////////////////////////////////////////////////////

  Void storeCommandStack()
  {
    if (resource == null) return

    // save undo/redo stack if not empty
    key := "flux.view.commandStack.${resource.uri}"
    if (!view.commandStack.isEmpty)
    {
      Actor.locals[key] = view.commandStack.dup
    }
  }

  Void loadCommandStack()
  {
    if (resource == null) return

    // restore undo/redo stack for uri
    key := "flux.view.commandStack.${resource.uri}"
    cs := Actor.locals[key]
    if (cs != null)
    {
      view.commandStack = cs->dup
    }
  }

//////////////////////////////////////////////////////////////////////////
// Save and Dirty
//////////////////////////////////////////////////////////////////////////

  Void save()
  {
    if (!view.dirty) return
    try
    {
      view.onSave
      view.dirty = false
    }
    catch (Err e)
    {
      e.trace
      Dialog.openErr(frame, "Cannot save view $resource.name", e)
    }
    storeCommandStack
  }

  Bool dirty() { return view.dirty }

  Void onDirty(View view, Bool dirty)
  {
    if (ignoreDirty) return
    name := resource.name
    if (dirty) name += " *"
    this.text = name
    frame.title = "Flux - $text"
    frame.commands.updateSave
    parent?.relayout
  }

  Bool confirmClose()
  {
    if (!dirty) return true
    r := Dialog.openQuestion(frame, "Save changes to $resource.name?",
      [Dialog.yes, Dialog.no, Dialog.cancel])
    if (r == Dialog.cancel) return false
    if (r == Dialog.yes) save
    return true
  }

//////////////////////////////////////////////////////////////////////////
// Marks
//////////////////////////////////////////////////////////////////////////

  Void onMarks(Mark[] marks)
  {
    try { view.onMarks(marks) } catch (Err e) { e.trace }
  }

  Void onGotoMark(Mark mark)
  {
    try { view.onGotoMark(mark) } catch (Err e) { e.trace }
  }

//////////////////////////////////////////////////////////////////////////
// Command Stack
//////////////////////////////////////////////////////////////////////////

  Bool undoEnabled() { return view.commandStack.hasUndo }

  Bool redoEnabled() { return view.commandStack.hasRedo }

  Void undo() { view.commandStack.undo }

  Void redo() { view.commandStack.redo }

//////////////////////////////////////////////////////////////////////////
// Navigation
//////////////////////////////////////////////////////////////////////////

  Bool upEnabled() { return resource == null ? false : resource.uri.path.size > 0 }

  Bool backEnabled() { return !historyBack.isEmpty }

  Bool forwardEnabled() { return !historyForward.isEmpty }

  Void reload()
  {
    if (!confirmClose) return
    load(resource.uri, LoadMode { addToHistory=false })
  }

  Void up()
  {
    parent := resource.uri.parent
    if (parent == null) return
    if (!confirmClose) return
    load(parent, LoadMode { addToHistory=true})
  }

  Void back()
  {
    if (!backEnabled) return
    if (!confirmClose) return
    oldr := resource
    newr := historyBack.pop
    push(historyForward, oldr)
    load(newr.uri, LoadMode { addToHistory=false})
  }

  Void forward()
  {
    if (!forwardEnabled) return
    if (!confirmClose) return
    oldr := resource
    newr := historyForward.pop
    push(historyBack, oldr)
    load(newr.uri, LoadMode { addToHistory=false})
  }

  private Void push(Resource[] list, Resource r)
  {
    if ((Obj?)r == null) throw ArgErr("null resource")
    list.push(r)
    if (list.size > historyLimit) list.removeAt(0)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal const static Int historyLimit := 100

  internal Str text := "???"
  internal Image? image

  internal Frame frame
  internal Resource? resource
  internal View view := ErrView("Booting...")
  internal Resource[] historyBack:= Resource[,]
  internal Resource[] historyForward := Resource[,]
  internal Bool ignoreDirty := true

}

internal const class ViewLoadErr : Err
{
  new make(Str msg, Err? cause := null) : super.make(msg, cause) {}
}