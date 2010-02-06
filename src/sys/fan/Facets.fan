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
** Transient is a facet used to annotate fields which
** should be serialized inside a `Serializable` type.
** See the [Serialization Doc]`docLang::Serialization` for
** details.
**
facet class Transient {}

**************************************************************************
** Js
**************************************************************************

**
** Used to annoate types which should be compiled into JavaScript.
**
facet class Js {}

**************************************************************************
** NoDoc
**************************************************************************

**
** This facet is used on public types and slots to indicate they should
** not be documented with automated tools such as [Fandoc]`fandoc::pod-doc`.
** As a developer you should avoid using these types and slots since they
** are explicitly marked as not part of the public API.
**
facet class NoDoc {}

**************************************************************************
** Deprecated
**************************************************************************

**
** Indicates that a type or slot is obsolete
**
facet class Deprecated
{
  **
  ** Message for compiler output when deprecated type or slot is used.
  **
  const Str msg := ""
}

