//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 08  Brian Frank  Creation
//

**
** History maintains the most recent navigation history
** of the entire application.
**
@serializable @collection
class History
{

  **
  ** Convenience for loading from "session/history"
  **
  static History load()
  {
    return Flux.loadOptions("session/history", History#)
  }

  **
  ** Convenience for save to "session/history".
  ** Return this.
  **
  This save()
  {
    Flux.saveOptions("session/history", this)
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
      iconUri = r.icon?.uri
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
    if (item.uri == null || item.time == null)
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

  @transient private Int max := 20
  @transient private HistoryItem[] list := HistoryItem[,]
}

**************************************************************************
** HistoryItem
**************************************************************************

**
** HistoryItem stores information about navigation to a specific uri.
**
@serializable
const class HistoryItem
{
  **
  ** Uri of resource.
  **
  const Uri uri

  **
  ** Last time of access.
  **
  const DateTime time

  **
  ** Uri for icon of resource or null.
  **
  const Uri? iconUri

  **
  ** Return uri string.
  **
  override Str toStr() { return uri.toStr }
}