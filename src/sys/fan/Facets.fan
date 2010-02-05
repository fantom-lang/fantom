//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jul 09  Brian Frank  Creation
//   04 Feb 10  Brian Frank  Rework from old Symbol design
//

**************************************************************************
** Serializable
**************************************************************************

**
** Serializable is a facet used to annotate types which can be serialized.
** Objects are serialized via `sys::OutStream.writeObj` and deserialized
** via `sys::InStream.readObj`.
**
** See the [Serialization Doc]`docLang::Serialization` for details.
**
facet class Serializable
{
  **
  ** Simples are serialized atomically via a customized string representation
  ** using the following rules:
  **   - Override `sys::Obj.toStr` to return a suitable string representation
  **     of the object.
  **   - Must declare a static method called 'fromStr' which takes one 'Str'
  **     parameter and returns an instance of the declaring type.  The 'fromStr'
  **     method may contain additional parameters if they declare defaults.
  **
  const Bool simple := false

  **
  ** Collections are serializabled with a collection of child objects
  ** using the following  rules where 'Item' is the item type:
  **   - Provide an 'add(Item)' method to add child items during 'readObj'
  **   - Provide an 'each(|Item| f)' method to iterate children item
  **     during 'writeObj'
  **
  const Bool collection := false
}

**************************************************************************
** Transient
**************************************************************************

**
** Transient is a facet used to annotate fields which should not be
** serialized inside a [serializable]`#serializable` type.  See the
** [Serialization Doc]`docLang::Serialization` for details.
**
facet class Transient {}

**************************************************************************
** Js
**************************************************************************

**
** Used to annoate pods and types which should be compiled into JavaScript.
**
facet class Js {}

**************************************************************************
** NoDoc
**************************************************************************

**
** This facet is used on pods, public types, and slots to indicate they should
** not be documented with automated tools such as [Fandoc]`docLib::Fandoc`.
** As a developer you should avoid using these types and slots since they
** are explicitly marked as not part of the public API.
**
facet class NoDoc {}

/*

**
** Used on `UriScheme` subclasses to implement a URI scheme handler.
** See [docLang]`docLang::Naming`.
**
Str uriScheme := ""


**
** Indicates that a type or slot is obsolete
**
Bool deprecated := false

//////////////////////////////////////////////////////////////////////////
// Pod Build-time Facets
//////////////////////////////////////////////////////////////////////////

**
** Dependencies of the pod.
**
Depend[] podDepends := Depend[,]

**
** List of facet symbols to index for the type database.
**
** See [Facet Indexing]`docLang::TypeDatabase#facetIndexing` for details.
**
Symbol[] podIndexFacets := Symbol[,]

**
** List of Uris relative to "pod.fan" of directories containing
** the Fan source files to compile.
**
Uri[]? podSrcDirs := null

**
** List of Uris relative to "pod.fan" of directories of resources
** files to package into pod zip file.  Optional.
**
Uri[]? podResDirs := null

**
** List of Uris relative to "pod.fan" of directories containing
** the Java source files to compile for Java native methods.
**
Uri[]? podJavaDirs := null

**
** List of Uris relative to "pod.fan" of directories containing
** the C# source files to compile for .NET native methods.
**
Uri[]? podDotnetDirs := null

**
** List of Uris relative to "pod.fan" of directories containing
** the JavaScript source files to compile for JavaScript native methods.
**
Uri[]? podJsDirs := null

**
** Pod facet for account used to build pod.
** Facet is set automatically by compiler.
**
Str podBuildUser := ""

**
** Pod facet for host machine used to build pod
** Facet is set automatically by compiler.
**
Str podBuildHost := ""

**
** Pod facet for time target was pod was built local to build host.
** Facet is set automatically by compiler.
**
DateTime? podBuildTime := null

**
** This facet is used on pods to indicate whether the source code
** should be included in the documentation.  By default source code
** it *not* included.
**
Bool docsrc := false

*/