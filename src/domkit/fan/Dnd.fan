//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 2015  Andy Frank  Creation
//

using concurrent
using dom
using graphics

**************************************************************************
** DragTarget
**************************************************************************

**
** DragTarget converts an Elem into a drag target for
** a drag-and-drop events.
**
** See also: [docDomkit]`docDomkit::Dnd`
**
@Js class DragTarget
{
  ** Convert given Elem into a drag target.
  static DragTarget bind(Elem elem) { make(elem) }

  ** Private ctor.
  private new make(Elem elem)
  {
    elem->draggable = true
    elem.onEvent("dragstart", false) |e|
    {
      if (cbDrag == null) return
      data := cbDrag.call(elem)
      DndUtil.map[data.hash] = data
      e.dataTransfer.setData("text/plain", data.hash.toStr)
    }
    elem.onEvent("dragend", false) |e|
    {
      if (cbEnd != null) cbEnd(elem)
    }
  }

  ** Callback to get data payload for drag event.
  Void onDrag(|Elem->Obj| f) { cbDrag = f }

  ** Callback when the drag event has ended.
  Void onEnd(|Elem| f) { cbEnd = f }

  private Func? cbDrag
  private Func? cbEnd
}

**************************************************************************
** DropTarget
**************************************************************************

**
** DropTarget converts an Elem into a drop target for drag and drop
** events. The 'canDrop' callback is used to indicate if 'data' can be
** dropped on this target.  The 'onDrop' callback is invoked when a
** drop event completes.
**
** See also: [docDomkit]`docDomkit::Dnd`
**
@Js class DropTarget
{
  ** Convert given Elem into a drop target.
  static DropTarget bind(Elem elem) { make(elem) }

  ** Private ctor.
  private new make(Elem elem)
  {
    // setup elem positioning if needed
    pos := elem.style["position"]
    if (pos != "relative" || pos != "absolute") elem.style["position"] = "relative"

    // setup events
    elem.onEvent("dragenter", false) |e|
    {
      e.stop
      data := DndUtil.getData(e.dataTransfer)
      if (_canDrop(data)) elem.style.addClass("domkit-dnd-over")
    }
    elem.onEvent("dragover",  false) |e|
    {
      e.stop
      if (cbOver != null)
      {
        // TODO: need to translate these to pageX,pageY
        Int x := e->clientX
        Int y := e->clientY
        cbOver(Point(x,y))
      }
    }
    elem.onEvent("dragleave", false) |e|
    {
      if (e.target == elem)
        elem.style.removeClass("domkit-dnd-over")
    }
    elem.onEvent("drop", false) |e|
    {
      e.stop
      elem.style.removeClass("domkit-dnd-over")
      data := DndUtil.getData(e.dataTransfer)
      if (_canDrop(data)) cbDrop?.call(data)
    }
  }

  ** Callback to indicate if 'data' can be dropped on this target.
  Void canDrop(|Obj data->Bool| f) { this.cbCanDrop = f }

  ** Callback when 'data' is dropped on this target.
  Void onDrop(|Obj data| f) { this.cbDrop = f }

  ** Callback when drag target is over this drop target, where
  ** 'pagePos' is the current drag node.
  Void onOver(|Point pagePos| f) { this.cbOver = f }

  private Bool _canDrop(Obj data)
  {
    cbCanDrop == null ? true : cbCanDrop.call(data)
  }

  private Func? cbCanDrop
  private Func? cbDrop
  private Func? cbOver
  private Int depth
}

**************************************************************************
** DndUtil
**************************************************************************

**
** Internal drag and drop utilities.
**
@Js internal class DndUtil
{
  ** Global map of data payloads.
  static Int:Obj map()
  {
    m := Actor.locals["domkit.dnd.map"] as Int:Obj
    if (m == null) Actor.locals["domkit.dnd.map"] = m = Int:Obj[:]
    return m
  }

  ** Get the data payload for given transfer instance.
  static Obj getData(DataTransfer dt)
  {
    key := dt.getData("text/plain").toInt(10, false)
    if (key == null) throw ArgErr("Drag target not found: $dt")
    val := map[key] ?: throw ArgErr("Drag target not found: $dt")
    return val
  }
}