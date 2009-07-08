//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Mar 08  Brian Frank  Creation
//    9 Jul 09  Brian        Rename from Namespace
//

**
** UriSpace models a Uri to Obj map.  UriSpaces provide a unified
** CRUD (create/read/update/delete) interface for managing objects
** keyed by a Uri.  The root space is accessed via `UriSpace.root` provides
** a thread-safe memory database.  Custom spaces can be mounted
** into the system via the `UriSpace.mount` method.
**
** See `docLang::UriSpaces` for details.
**
abstract const class UriSpace
{

//////////////////////////////////////////////////////////////////////////
// Mounting
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the root uri space.
  **
  static UriSpace root()

  **
  ** Get the uri space instance which manages the specified
  ** uri or fallback to root uri space.
  **
  static UriSpace find(Uri uri)

  **
  ** Mount a uri space under the specified Uri.  All requests
  ** to process uris contained by the specified uri are routed
  ** to the uri space instance for processing.  Throw ArgErr if
  ** the uri is already or mounted by another uri space.  Throw
  ** ArgErr if the uri isn't path absolute, has a query, or has
  ** fragment.
  **
  static Void mount(Uri uri, UriSpace ns)

  **
  ** Unmount a uri space which was previously mounted by the
  ** `mount` method.  Throw UnresolvedErr is uri doesn't directly
  ** map to a mounted uri space.
  **
  static Void unmount(Uri uri)

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  **
  ** Create a UriSpace which maps Uris to a directory tree.
  ** The resulting uri space may then be mounted via `UriSpace.mount`
  ** to alias uri space Uris to files within the directory.
  ** Throw ArgErr if dir does not map to an existing directory.
  ** Note that uris will resolve successfully directories without
  ** a trailing slash.
  **
  ** Example:
  **   UriSpace.mount(`/foo/`, UriSpace.makeDir(`/pub/`.toFile))
  **   UriSpace.root[`/foo/file.html`]  =>  `/pub/file.html`
  **
  static UriSpace makeDir(File dir)

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the Uri that this UriSpace is mounted
  ** under or null if not mounted.
  **
  Uri? uri()

  **
  ** Get the object mapped by the specified Uri.  If the Uri
  ** doesn't map to a valid object and checked is false then
  ** return null, otherwise throw UnresolvedErr.  Throw
  ** ArgErr if uri returns false for [isPathOnly]`Uri.isPathOnly`.
  **
  abstract Obj? get(Uri uri, Bool checked := true)

  **
  ** Create the specified uri/object pair in this uri space.
  ** Pass null for uri if the uri space should generate a new
  ** uri automatically.  Return the newly created uri.  If
  ** the uri is already mapped, then throw ArgErr.  Throw
  ** ArgErr if uri returns false for [isPathOnly]`Uri.isPathOnly`.
  **
  ** The root uri space stores the object in the memory
  ** database - the object must be immutable or serializable.
  **
  ** The default implementation for subclasses is to throw
  ** UnsupportedErr.
  **
  virtual Uri create(Uri? uri, Obj obj)

  **
  ** Update the object mapped by the specified uri.  If
  ** the uri isn't mapped then throw UnresolvedErr. Throw
  ** ArgErr if uri returns false for [isPathOnly]`Uri.isPathOnly`.
  **
  ** The root uri space stores the object back to the memory
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
  ** The root uri space removes the uri/object pair from
  ** the memory database.
  **
  ** The default implementation for subclasses is to throw
  ** UnsupportedErr.
  **
  virtual Void delete(Uri uri)

}

**************************************************************************
** RootUriSpace
**************************************************************************

internal const class RootUriSpace : UriSpace
{
  override Obj? get(Uri uri, Bool checked := true)
}

**************************************************************************
** SysUriSpace
**************************************************************************

internal const class SysUriSpace : UriSpace
{
  override Obj? get(Uri uri, Bool checked := true)
}

**************************************************************************
** DirUriSpace
**************************************************************************

internal const class DirUriSpace : UriSpace
{
  override Obj? get(Uri uri, Bool checked := true)
}