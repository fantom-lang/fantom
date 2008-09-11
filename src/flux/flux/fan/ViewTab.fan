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
internal class ViewTab : EdgePane //Tab
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(Frame frame) { this.frame = frame }

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  Void loadUri(Uri uri, Bool addToHistory)
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
          loadErr(ErrResource(uri), "Uknown resource mapping: $obj.type", addToHistory)
          return
        }
        r = rtype.make([uri, obj])
      }

      // load with mapped resource
      load(r, addToHistory)
    }
    catch (UnresolvedErr err)
    {
      loadErr(ErrResource(uri), "Resource not found", addToHistory, err)
    }
    catch (Err err)
    {
      loadErr(ErrResource(uri), "Cannot load view", addToHistory, err)
    }
  }

  Void load(Resource r, Bool addToHistory)
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
          loadErr(r, "Unknown view type '$qname'", addToHistory)
          return
        }
      }
      else
      {
        viewType = r.views?.first
        if (viewType == null)
        {
          loadErr(r, "No views registered", addToHistory)
          return
        }
      }

      // create view
      view := viewType.make as View
      if (view == null)
      {
        loadErr(r, "Incorrect view type: '$viewType' is not 'flux::View'", addToHistory)
        return
      }

      // load view
      view.load(r)
      doLoad(r, view, addToHistory)
    }
    catch (Err err)
    {
      loadErr(r, "Cannot load view", addToHistory, err)
    }
  }

  Void loadErr(Resource r, Str msg, Bool addToHistory, Err cause := null)
  {
    view := ErrView(msg, cause)
    view.load(r)
    doLoad(r, view, addToHistory)
  }

  private Void doLoad(Resource r, View newView, Bool addToHistory)
  {
    if (newView == null) throw ArgErr("newView is null")
    oldView := this.view

    // suspend dirty handling
    ignoreDirty = true

    // unload old view
    try { oldView.onUnload  } catch (Err e) { e.trace }

    // add to history if needed
    if (resource != null && addToHistory)
    {
      push(historyBack, resource)
      historyForward.clear
    }

    // update my state
    this.text  = r.name
    this.image = r.icon
    this.resource = r
    this.view = newView
    //removeAll.add(newView)
    center = newView
    parent?.relayout

    // resume dirty handling
    newView.dirty = false
    ignoreDirty = false

    // update frame
    frame.locator.load(r)
    frame.commands.update
  }

  private Void dumpHistory()
  {
    echo("===============")
    historyBack.each |Resource x| { echo("    $x.uri") }
    echo("--> $resource.uri")
    historyForward.eachr |Resource x| { echo("    $x.uri") }
  }

//////////////////////////////////////////////////////////////////////////
// View Callbacks
//////////////////////////////////////////////////////////////////////////

  Bool dirty() { return view != null ? view.dirty : false }

  Void onDirty(View view, Bool dirty)
  {
    if (ignoreDirty) return
    name := resource.name
    if (dirty) name += " *"
    this.text = name
    frame.commands.updateSave
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
    load(resource, false)
  }

  Void up()
  {
    parent := resource.uri.parent
    if (parent == null) return
    loadUri(parent, true)
  }

  Void back()
  {
    if (!backEnabled) return
    oldr := resource
    newr := historyBack.pop
    push(historyForward, oldr)
    load(newr, false)
  }

  Void forward()
  {
    if (!forwardEnabled) return
    oldr := resource
    newr := historyForward.pop
    push(historyBack, oldr)
    load(newr, false)
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