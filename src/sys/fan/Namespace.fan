//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Mar 08  Brian Frank  Creation
//

**
** Namespace models a Uri to Obj map.  Namespaces provide a unified
** CRUD (create/read/update/delete) interface for managing objects
** keyed by a Uri.  The root namespace accessed via `Sys.ns` provides
** a thread-safe memory database.  Custom namespaces can be mounted
** into the system via the `Sys.mount` method.
**
** See `docLang::Namespaces` for details.
**
abstract const class Namespace
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  **
  ** Create a Namespace which maps Uris to a directory tree.
  ** The resulting namespace may then be mounted via `Sys.mount`
  ** to alias namespace Uris to files within the directory.
  ** Throw ArgErr if dir does not map to an existing directory.
  ** Note that uris will resolve successfully directories without
  ** a trailing slash.
  **
  ** Example:
  **   Sys.mount(`/foo/`, Namespace.makeDir(`/pub/`.toFile))
  **   Sys.ns[`/foo/file.html`]  =>  `/pub/file.html`
  **
  static Namespace makeDir(File dir)

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the Uri that this Namespace is mounted
  ** under or null if not mounted.
  **
  Uri uri()

  **
  ** Get the object mapped by the specified Uri.  If the Uri
  ** doesn't map to a valid object and checked is false then
  ** return null, otherwise throw UnresolvedErr.  Throw
  ** ArgErr if uri returns false for [isPathOnly]`Uri.isPathOnly`.
  **
  abstract Obj get(Uri uri, Bool checked := true)

  **
  ** Create the specified uri/object pair in this namespace.
  ** Pass null for uri if the namespace should generate a new
  ** uri automatically.  Return the newly created uri.  If
  ** the uri is already mapped, then throw ArgErr.  Throw
  ** ArgErr if uri returns false for [isPathOnly]`Uri.isPathOnly`.
  **
  ** The root namespace stores the object in the memory
  ** database - the object must be immutable or serializable.
  **
  ** The default implementation for subclasses is to throw
  ** UnsupportedErr.
  **
  virtual Uri create(Uri uri, Obj obj)

  **
  ** Update the object mapped by the specified uri.  If
  ** the uri isn't mapped then throw UnresolvedErr. Throw
  ** ArgErr if uri returns false for [isPathOnly]`Uri.isPathOnly`.
  **
  ** The root namespace stores the object back to the memory
  ** database - the object must be immutable or serializable.
  **
  ** The default implementation for subclasses is to throw
  ** UnsupportedErr.
  **
  virtual Void put(Uri uri, Obj obj)

  **
  ** Delete the object mapped by the specified uri.  If
  ** the uri isn't mapped then throw UnresolvedErr. Throw
  ** ArgErr if uri returns false for [isPathOnly]`Uri.isPathOnly`.
  **
  ** The root namespace removes the uri/object pair from
  ** the memory database.
  **
  ** The default implementation for subclasses is to throw
  ** UnsupportedErr.
  **
  virtual Void delete(Uri uri)

}

**************************************************************************
** RootNamespace
**************************************************************************

internal const class RootNamespace : Namespace
{
  override Obj get(Uri uri, Bool checked := true)
}

**************************************************************************
** SysNamespace
**************************************************************************

internal const class SysNamespace : Namespace
{
  override Obj get(Uri uri, Bool checked := true)
}

**************************************************************************
** DirNamespace
**************************************************************************

internal const class DirNamespace : Namespace
{
  override Obj get(Uri uri, Bool checked := true)
}

