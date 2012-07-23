//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jan 09  Brian Frank  Creation
//

**
** Contract encapsulates a list of URIs to prototype objects.
**
const class Contract
{

  **
  ** Construct with a list of URIs.
  **
  new make(Uri[] uris) { this.uris = uris }

  **
  ** Parse a list of encoded URIs separated by space.  If
  ** format error then throw ParseErr or return null based
  ** on checked flag.
  **
  static new fromStr(Str s, Bool checked := false)
  {
    try
    {
      return make(s.split.map |Str x->Uri| { Uri.decode(x) })
    }
    catch
    {
      if (checked) return null
      throw ParseErr("Contract: $s")
    }
  }

  **
  ** List of uris.
  **
  const Uri[] uris

  **
  ** Convenience for 'uris.isEmpty'.
  **
  Bool isEmpty() { return uris.isEmpty }

  **
  ** Two contracts are equal if they have the same list of URIs.
  **
  override Bool equals(Obj? that)
  {
    x := that as Contract
    if (x == null) return false
    return uris == x.uris
  }

  **
  ** Hash code is list of URIs.
  **
  override Int hash()
  {
    return uris.hash
  }

  **
  ** Return list of encoded uris separated by a space.
  **
  override Str toStr()
  {
    return uris.join(" ") {it.encode}
  }

  ** Return if the contract list contains the given URI
  Bool has(Uri contract) { uris.contains(contract) }

  **
  ** The empty contract with no URIs.
  **
  static const Contract empty := Contract(Uri[,])

  @NoDoc static const Contract lobby           := Contract([`obix:Lobby`])
  @NoDoc static const Contract about           := Contract([`obix:About`])
  @NoDoc static const Contract batchIn         := Contract([`obix:BatchIn`])
  @NoDoc static const Contract batchOut        := Contract([`obix:BatchOut`])
  @NoDoc static const Contract watchService    := Contract([`obix:WatchService`])
  @NoDoc static const Contract watch           := Contract([`obix:Watch`])
  @NoDoc static const Contract watchIn         := Contract([`obix:WatchIn`])
  @NoDoc static const Contract watchOut        := Contract([`obix:WatchOut`])
  @NoDoc static const Contract read            := Contract([`obix:Read`])
  @NoDoc static const Contract write           := Contract([`obix:Write`])
  @NoDoc static const Contract invoke          := Contract([`obix:Invoke`])
  @NoDoc static const Contract badUriErr       := Contract([`obix:BadUriErr`])
  @NoDoc static const Contract point           := Contract([`obix:Point`])
  @NoDoc static const Contract history         := Contract([`obix:History`])
  @NoDoc static const Contract writePointIn    := Contract([`obix:WritePointIn`])
  @NoDoc static const Contract historyFilter   := Contract([`obix:HistoryFilter`])
  @NoDoc static const Contract historyQueryOut := Contract([`obix:HistoryQueryOut`])
}