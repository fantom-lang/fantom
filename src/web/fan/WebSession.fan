//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 08  Brian Frank  Creation
//

**
** WebSession provides a name/value map associated with a specific
** browser "connection" to the web server.  Any values stored in a
** WebSession must be both immutable and serializable.  Get the
** current WebSession via `WebReq.session`.
**
** See [pod doc]`pod-doc#sessions`.
**
abstract class WebSession
{
  **
  ** Get the unique id used to identify this session.
  **
  abstract Str id()

  **
  ** Return `id`.
  **
  override Str toStr() { id }

  **
  ** Iterate the key/value pairs
  **
  abstract Void each(|Obj?,Str| f)

  **
  ** Get session value or return def if not defined.
  **
  @Operator abstract Obj? get(Str name, Obj? def := null)

  **
  ** Set a session value which must be immutable and serializable.
  **
  @Operator abstract Void set(Str name, Obj? val)

  **
  ** Remove a session key
  **
  abstract Void remove(Str name)

  **
  ** Application name/value pairs which are persisted
  ** between HTTP requests.  The values stored in this
  ** map must be serializable.
  **
  @Deprecated { msg = "Use get, set, remove, each" }
  abstract Str:Obj? map() // TODO

  **
  ** Delete this web session which clears both the user
  ** agent cookie and the server side session instance.
  ** This method must be called before the WebRes is
  ** committed otherwise the server side instance is cleared,
  ** but the user agent cookie will remain uncleared.
  **
  abstract Void delete()

}