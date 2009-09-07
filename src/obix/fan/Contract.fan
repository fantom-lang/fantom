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
  static Contract? fromStr(Str s, Bool checked := false)
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

  **
  ** The empty contract with no URIs.
  **
  static const Contract empty := Contract(Uri[,])

  internal static const Contract batchIn := Contract([`obix:BatchIn`])
  internal static const Contract read    := Contract([`obix:Read`])
  internal static const Contract write   := Contract([`obix:Write`])
  internal static const Contract invoke  := Contract([`obix:Invoke`])
}