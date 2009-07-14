//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jul 09  Brian Frank  Creation
//

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

**
** Transient is a facet used to annotate fields which should not be
** serialized inside a [serializable]`#serializable` type.  See the
** [Serialization Doc]`docLang::Serialization` for details.
**
Bool transient := false

**
** Serializable is a Bool marker facet used to annotate types which can be
** serialized.  Objects are serialized via `sys::OutStream.writeObj` and
** deserialized via `sys::InStream.readObj`.  Types which implement this facet
** or inherit it are serialized as a *complex*.  If a type should be serialized
** atomically as a simple then implement the [simple]`#simple` facet (never
** implement both).  See the [Serialization Doc]`docLang::Serialization` for
** details.
**
Bool serializable := false

**
** Simple is a Bool marker facet used to annotate types which are serialized
** automatically via a string representation.  All types which implement this
** facet must follow these rules:
**
**   - Override `sys::Obj.toStr` to return a suitable string representation
**     of the object.
**   - Must declare a static method called 'fromStr' which takes one 'Str'
**     parameter and returns an instance of the declaring type.  The 'fromStr'
**     method may contain additional parameters if they declare defaults.
**
Bool simple := false

**
** Collection is a Bool marker facet used to annotate serializable
** types as a collection of child objects.  All types which implement
** this facet must follow these rules where 'Item' is the item type:
**
**   - Provide an 'add(Item)' method to add child items during 'readObj'
**   - Provide an 'each(|Item| f)' method to iterate children item
**     during 'writeObj'
**
** See the [Serialization Doc]`docLang::Serialization` for details.
**
Bool collection := false

**
** This facet is used on public types and slots to indicate they should
** not be documented with automated tools such as [Fandoc]`docLib::Fandoc`.
** As a developer you should avoid using these types and slots since they
** are explicitly marked as not part of the public API.
**
Bool nodoc := false

