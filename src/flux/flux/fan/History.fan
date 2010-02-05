//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 08  Brian Frank  Creation
//

using gfx
using fwt

**
** History maintains the most recent navigation history
** of the entire application.
**
@Serializable { collection = true }
class History
{

  **
  ** Convenience for loading from "session/history"
  **
  static History load()
  {
    return Flux.loadOptions(Flux.pod, "session/history", History#)
  }

  **
  ** Convenience for save to "session/history".
  ** Return this.
  **
  This save()
  {
    Flux.saveOptions(Flux.pod, "session/history", this)
    return this
  }

  **
  ** Log navigation to the specified resource
  ** into the history.  Return this.
  **
  This push(Resource r)
  {
    // don't log flux: uris
    if (r.uri.scheme == "flux") return this

    // map resource to item
    item := HistoryItem
    {
      uri = r.uri
      iconUri = r.icon.uri
      time = DateTime.now
    }

    // push as most recent (remove old record for uri if found)
    dup := items.findIndex |HistoryItem i->Bool| { return i.uri == r.uri }
    if (dup != null) list.removeAt(dup)
    while (items.size >= max) list.removeAt(-1)
    list.insert(0, item)

    return this
  }

  **
  ** Get a readonly copy of all the items in the history.
  ** The first item is the most recent navigation and the last
  ** item is the oldest navigation.
  **
  HistoryItem[] items()
  {
    return list.ro
  }

  **
  ** Add a new history item to the end of the history.
  ** This method is typically only used for serialization.
  ** See `push` to log navigation of a Uri.  Return this.
  **
  This add(HistoryItem item)
  {
    if ((Obj?)item.uri == null || (Obj?)item.time == null)
      throw ArgErr("Invalid item: " + item)
    list.add(item)
    return this
  }

  **
  ** Iterate the history items from most recent to oldest.
  **
  Void each(|HistoryItem item| f)
  {
    list.each(f)
  }

  @Transient private Int max := 40
  @Transient private HistoryItem[] list := HistoryItem[,]
}

**************************************************************************
** HistoryItem
**************************************************************************

**
** HistoryItem stores information about navigation to a specific uri.
**
@Serializable
const class HistoryItem
{
  **
  ** Default constructor with it-block
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Uri of resource.
  **
  const Uri uri := ``

  **
  ** Last time of access.
  **
  const DateTime time := DateTime.now

  **
  ** Uri for icon of resource or null.
  **
  const Uri? iconUri

  **
  ** Return uri string.
  **
  override Str toStr() { return uri.toStr }
}

**************************************************************************
** HistoryPicker
**************************************************************************

class HistoryPicker : EdgePane
{
  new make(HistoryItem[] items, Bool fullPath, |HistoryItem, Event| onAction)
  {
    model := HistoryPickerModel(items, fullPath)
    center = Table
    {
      it.headerVisible = false
      it.model = model
      it.onAction.add |Event e|
      {
        onAction(model.items[e.index], e)
      }
      it.onKeyDown.add |Event e|
      {
        code := e.keyChar
        if (code >= 97 && code <= 122) code -= 32
        code -= 65
        if (code >= 0 && code < 26 && code < model.numRows)
          onAction(model.items[code], e)
      }
    }
  }
}

internal class HistoryPickerModel : TableModel
{
  new make(HistoryItem[] items, Bool fullPath)
  {
    this.items = items
    this.fullPath = fullPath
    icons = items.map |HistoryItem item->Image|
    {
      Image(item.iconUri, false) ?: def
    }
  }

  override Int numCols() { return 2 }
  override Int numRows() { return items.size }
  override Int? prefWidth(Int col)
  {
    switch (col)
    {
      case 0: return fullPath ? 450 : 250
      case 1: return 20
      default: return null
    }
  }
  override Image? image(Int col, Int row) { return col==0 ? icons[row] : null }
  override Font? font(Int col, Int row) { return col==1 ? accFont : null }
  override Color? fg(Int col, Int row)  { return col==1 ? accColor : null }
  override Str text(Int col, Int row)
  {
    switch (col)
    {
      case 0:  uri := items[row].uri; return fullPath ? uri.toStr : uri.name
      case 1:  return (row < 26) ? (row+65).toChar : ""
      default: return ""
    }
  }
  HistoryItem[] items
  Image[] icons
  Image def := Flux.icon(`/x16/file.png`)
  Font accFont := Desktop.sysFont.toSize(Desktop.sysFont.size-1)
  Color accColor := Color("#666")
  Bool fullPath
}

