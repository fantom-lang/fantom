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
      DndUtil.setData(e.dataTransfer, data)
      if (cbDragImage != null)
      {
        this.dragImage = cbDragImage.call(data)
        this.dragImage.style->position = "absolute"
        this.dragImage.style->top      = "-1000px"
        this.dragImage.style->right    = "-1000px"
        Win.cur.doc.body.add(dragImage)
        e.dataTransfer.setDragImage(dragImage, 0, 0)
      }
    }
    elem.onEvent("dragend", false) |e|
    {
      if (cbEnd != null) cbEnd(elem)
      dragImage?.parent?.remove(dragImage)
      DndUtil.clearData(e.dataTransfer)
    }
  }

  ** Callback to get data payload for drag event.
  Void onDrag(|Elem->Obj| f) { cbDrag = f }

  ** Callback to customize the drag image for drag event.
  Void onDragImage(|Obj->Elem| f) { cbDragImage = f }

  ** Callback when the drag event has ended.
  Void onEnd(|Elem| f) { cbEnd = f }

  private Func? cbDrag
  private Func? cbDragImage
  private Func? cbEnd
  private Elem? dragImage
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
      {
        elem.style.removeClass("domkit-dnd-over")
        cbLeave?.call()
      }
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

  ** Callback when drag target has left this drop target.
  Void onLeave(|->| f) { this.cbLeave = f }

  private Bool _canDrop(Obj data)
  {
    cbCanDrop == null ? true : cbCanDrop.call(data)
  }

  private Func? cbCanDrop
  private Func? cbDrop
  private Func? cbOver
  private Func? cbLeave
  private Int depth
}

**************************************************************************
** DndUtil
**************************************************************************

**
** Internal drag and drop utilities.
**
@NoDoc @Js class DndUtil
{
  ** Cache for current drag-and-drop operation
  private const static AtomicRef dataRef := AtomicRef(Unsafe(null))

  ** Get the data payload for given transfer instance.
  static Obj getData(DataTransfer dt)
  {
    // then check Fantom object from cache
    data := ((Unsafe)dataRef.val).val
    if (data != null) return data

    // check files first
    if (!dt.files.isEmpty) return dt.files

    // return plain text
    return dt.getData("text/plain")
  }

  ** Set the data payload on given transfer instance.
  static Void setData(DataTransfer dt, Obj data)
  {
    dataRef.val = Unsafe(data)
    dt.setData("text/plain", data.toStr)
  }

  ** Clear data cache
  static Void clearData(DataTransfer dt)
  {
    dataRef.val = Unsafe(null)
  }
}