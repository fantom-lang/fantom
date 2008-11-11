//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Nov 08  Brian Frank  Creation
//

**
** Models a XML Namespace uri.  It also defines a prefix to
** use to qualify element and attribute names.  XNs instances
** are passed to the constructor of `XElem` and `XAttr`.  You
** can define the namespace attribute via `XAttr.makeNs`.
**
const class XNs
{

  **
  ** Construct an XML namespace with the specified prefix and Uri.
  ** Pass "" for prefix if this is the default XML namespace.
  **
  new make(Str prefix, Uri uri)
  {
    this.prefix = prefix
    this.uri = uri
  }

  **
  ** The prefix used to quality element and attribute names
  ** with this namespace's uri.  If this is the default namespace
  ** prefix is "".
  **
  const Str prefix

  **
  ** The uri which defines a universally unique namespace.
  **
  const Uri uri

  **
  ** Return if this a default namespace which has a prefix of "".
  **
  Bool isDefault() { return prefix == "" }

  **
  ** Return the uri's hash code.
  **
  override Int hash()
  {
    return uri.hash
  }

  **
  ** Two namespaces are equal if they have the same uri.
  **
  override Bool equals(Obj? that)
  {
    if (that isnot XNs) return false
    return uri == ((XNs)that).uri
  }

  **
  ** Return the uri as the string representation.
  **
  override Str toStr() { return uri.toStr }

}