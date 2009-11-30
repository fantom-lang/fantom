//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 08  Brian Frank  Creation
//

**
** WebSession provides a name/value map associated with
** a specific browser "connection" to the web server.  Any
** values stored in a WebSession must be serializable.
** Get the current WebSession via `WebReq.session`.
**
** See [docLib::Web]`docLib::Web#sessions`
**
@serializable
abstract class WebSession
{
  **
  ** Construct with optional id.
  **
  new make(Str? id := null)
  {
    if (id != null) this.id = id
  }

  **
  ** Get the unique id used to identify this session.
  **
  const Str id := ""

  **
  ** Return `id`.
  **
  override Str toStr() { return id }

  **
  ** Convenience for 'map.get(name, def)'.
  **
  Obj? get(Str name, Obj? def := null) { return map.get(name, def) }

  **
  ** Convenience for 'map.set(name, val)'.
  **
  Void set(Str name, Obj? val) { map[name] = val }

  **
  ** Application name/value pairs which are persisted
  ** between HTTP requests.  The values stored in this
  ** map must be serializable.
  **
  readonly Str:Obj? map := Str:Obj?[:]

  **
  ** Delete this web session which clears both the user
  ** agent cookie and the server side session instance.
  ** This method must be called before the WebRes is
  ** committed otherwise the server side instance is cleared,
  ** but the user agent cookie will remain uncleared.
  **
  abstract Void delete()

}