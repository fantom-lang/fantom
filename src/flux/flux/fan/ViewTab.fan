//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Jul 08  Brian Frank  Creation
//

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

  Void loadUri(Uri uri, LoadMode mode)
  {
    try
    {
      // resolve uri
      obj := uri.get

      // if the obj isn't already a resource, we need to wrap
      // as a resource
      r := obj as Resource
      if (r == null)
      {
        rtype := Type.findByFacet("fluxResource", obj.type, true).first
        if (rtype == null)
        {
          loadErr(ErrResource(uri), "Uknown resource mapping: $obj.type", mode)
          return
        }
        r = rtype.make([uri, obj])
      }

      // load with mapped resource
      load(r, mode)
    }
    catch (UnresolvedErr err)
    {
      loadErr(ErrResource(uri), "Resource not found", mode, err)
    }
    catch (Err err)
    {
      loadErr(ErrResource(uri), "Cannot load view", mode, err)
    }
  }

  Void load(Resource r, LoadMode mode)
  {
    if (r == null) throw ArgErr("resource is null")
    try
    {
      // check for explicit view query param, otherwise
      // default to first registered view on resource type
      Type viewType
      qname := r.uri.query["view"]
      if (qname != null)
      {
        viewType = Type.find(qname, false)
        if (viewType == null)
        {
          loadErr(r, "Unknown view type '$qname'", mode)
          return
        }
      }
      else
      {
        viewType = r.views?.first
        if (viewType == null)
        {
          loadErr(r, "No views registered", mode)
          return
        }
      }

      // create view
      view := viewType.make as View
      if (view == null)
      {
        loadErr(r, "Incorrect view type: '$viewType' is not 'flux::View'", mode)
        return
      }

      // view onLoad callback (which might raise exception)
      doOnLoad(view, r)
      doLoad(r, view, mode)
    }
    catch (Err err)
    {
      loadErr(r, "Cannot load view", mode, err)
    }
  }

  Void loadErr(Resource r, Str msg, LoadMode mode, Err cause := null)
  {
    view := ErrView(msg, cause)
    doOnLoad(view, r)
    doLoad(r, view, mode)
  }

  Void doOnLoad(View view, Resource r)
  {
    view.frame = frame
    view.tab = this
    view.resource = r
    view.onLoad
  }

  private Void doLoad(Resource r, View newView, LoadMode mode)
  {
    if (newView == null) throw ArgErr("newView is null")
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
    parent?.relayout

    // resume dirty handling
    newView.dirty = false
    ignoreDirty = false

    // update frame
    frame.locator.load(r)
    frame.commands.update
    activate
  }

  Widget doBuildToolBar(View v)
  {
    try
    {
      return v.buildToolBar
      /*
      tb := v.buildToolBar
      if (tb == null) return tb
      return BorderPane
      {
        content  = tb
        insets   = Insets(4,4,5,4)
        onBorder = |Graphics g, Insets insets, Size size|
        {
          g.brush = Color.sysNormShadow
          g.drawLine(0, size.h-1, size.w, size.h-1)
        }
      }
      */
    }
    catch (Err e)
    {
      e.trace
      return null
    }
  }

  Widget doBuildStatusBar(View v)
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
      Dialog.openErr(frame, "Cannot save view $resource.name")
      // TODO: need standard error dialog
    }
  }

  Bool dirty() { return view != null ? view.dirty : false }

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
    load(resource, LoadMode { addToHistory=false })
  }

  Void up()
  {
    parent := resource.uri.parent
    if (parent == null) return
    loadUri(parent, LoadMode { addToHistory=true})
  }

  Void back()
  {
    if (!backEnabled) return
    oldr := resource
    newr := historyBack.pop
    push(historyForward, oldr)
    load(newr, LoadMode { addToHistory=false})
  }

  Void forward()
  {
    if (!forwardEnabled) return
    oldr := resource
    newr := historyForward.pop
    push(historyBack, oldr)
    load(newr, LoadMode { addToHistory=false})
  }

  private Void push(Resource[] list, Resource r)
  {
    if (r == null) throw ArgErr("null resource")
    list.push(r)
    if (list.size > historyLimit) list.removeAt(0)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal const static Int historyLimit := 100

  internal Str text
  internal Image image

  internal Frame frame
  internal Resource resource
  internal View view := ErrView("Booting...")
  internal Resource[] historyBack:= Resource[,]
  internal Resource[] historyForward := Resource[,]
  internal Bool ignoreDirty := true

}
