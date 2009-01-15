//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jan 09  Brian Frank  Creation
//

**
** ObixObj models an 'obix:obj' element.
**
class ObixObj
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Programatic name of the object which defines role of
  ** this object in its parent.  Throw UnsupportedErr if an
  ** attempt is made to set the name once mounted under a parent.
  **
  Str? name
  {
    set
    {
      if (parent != null) throw UnsupportedErr("cannot set name while parented")
      @name = val
    }
  }

  **
  ** URI of this object. The root object of a document must have
  ** an absolute URI, other objects may have a URI relative to
  ** the document root.  See `normalizedHref` to get this href
  ** normalized against the root object.
  **
  Uri? href

  **
  ** Get this objects `href` normalized against the root object's
  ** URI.  Return null no href defined.
  **
  Uri? normalizedHref()
  {
    if (href == null) return null
    r := root
    if (r.href == null) return null
    return r.href + href
  }

  **
  ** The list of contracts this object implemented as specified
  ** by 'is' attribute.
  **
  Uri[] contracts := noUris

  **
  ** The XML element name to use for this object.
  **
  Str elemName := "obj"
  {
    set
    {
      // TODO
      @elemName = val
    }
  }

  **
  ** Return string representation.
  **
  override Str toStr()
  {
    s := StrBuf()
    s.add("<").add(elemName)
    if (name != null) s.add(" name='").add(name).add("'")
    if (href != null) s.add(" href='").add(href).add("'")
    if (val != null)  s.add(" val='").add(valToStr).add("'")
    s.add(">");
    return s.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Value
//////////////////////////////////////////////////////////////////////////

  **
  ** The null flag indicates the absense of a value.
  **
  Bool isNull

  **
  ** Object value for value object types:
  **   - obix:bool    => sys::Bool
  **   - obix:int     => sys::Int
  **   - obix:real    => sys::Float
  **   - obix:str     => sys::Str
  **   - obix:enum    => sys::Str
  **   - obix:uri     => sys::Uri
  **   - obix:abstime => sys::DateTime
  **   - obix:reltime => sys::Duration
  **   - obix:date    => sys::Date
  **   - obix:time    => sys::Time
  **
  ** If the value is not one of the types listed above, then ArgErr is
  ** thrown.  If the value is set to non-null, then the `elemName` is
  ** automatically updated.
  **
  Obj? val
  {
    set
    {
      if (val != null)
      {
        elem := ObixUtil.valTypeToElemName[val.type]
        if (elem == null) throw ArgErr("Invalid val type: $val.type")
        @elemName = elem
      }
      @val = val
    }
  }

  **
  ** Get the value encoded as a string.  If the value
  ** is null then return "null".
  **
  Str valToStr()
  {
    // everything but Uri and DateTime uses its toStr format
    if (val == null) return "null"
    func := ObixUtil.valTypeToStrFunc[val.type]
    if (func != null) return func(val)
    return val.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Parent/Child Tree
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the root ancestor of this object, or
  ** return 'this' if no parent.
  **
  ObixObj root()
  {
    x := this
    while (x.parent != null) x = x.parent
    return x
  }

  **
  ** Parent object or null if unparented.
  **
  readonly ObixObj? parent

  **
  ** Return is size is zero.
  **
  Bool isEmpty() { return kidsCount == 0 }

  **
  ** Return number of child objects.
  **
  Int size() { return kidsCount }

  **
  ** Return if there is child object by the specified name.
  **
  Bool has(Str name)
  {
    if (kidsByName == null) return false
    return kidsByName.containsKey(name)
  }

  **
  ** Get a child by name or return null if not found.
  **
  ObixObj? get(Str name)
  {
    if (kidsByName == null) return null
    return kidsByName[name]
  }

  **
  ** Get a readonly list of the children objects or empty
  ** list if no children.  If iterating the children it is
  ** more efficient to use `each`.
  **
  ObixObj[] list()
  {
    if (kidsCount == 0) return noChildren
    list := ObixObj[,] { capacity = kidsCount }
    for (ObixObj? p := kidsHead; p != null; p = p.next) list.add(p)
    return list.ro
  }

  **
  ** Iterate each of the children objects.
  **
  Void each(|ObixObj child| f)
  {
    for (ObixObj? p := kidsHead; p != null; p = p.next) f(p)
  }

  **
  ** Add a child object.  Throw ArgErr if this child is
  ** already parented or has a duplicate name.  Return this.
  **
  This add(ObixObj kid)
  {
    // sanity checks
    if (kid.parent != null || kid.prev != null || kid.next != null)
      throw ArgErr("Child is already parented")
    if (kid.name != null && kidsByName != null && kidsByName.containsKey(kid.name))
      throw ArgErr("Duplicate child name '$kid.name'")

    // if named, add to name map
    if (kid.name != null)
    {
      if (kidsByName == null) kidsByName = Str:ObixObj[:]
      kidsByName[kid.name] = kid
    }

    // add to ordered linked list
    if (kidsTail == null) { kidsHead = kidsTail = kid }
    else { kidsTail.next = kid; kid.prev = kidsTail; kidsTail = kid }

    // update kid's references and count
    kidsCount++
    kid.parent = this
    return this
  }

  **
  ** Remove the specified child object by reference.
  ** Throw ArgErr if not my child.  Return this
  **
  This remove(ObixObj kid)
  {
    // sanity checks
    if (kid.parent != this) throw ArgErr("Not parented by me")

    // remove from name map if applicable
    if (kid.name != null) kidsByName.remove(kid.name)

    // remove from linked list
    if (kidsHead == kid) { kidsHead = kid.next }
    else { kid.prev.next = kid.next }
    if (kidsTail == kid) { kidsTail = kid.prev }
    else { kid.next.prev = kid.prev }

    // clear kid's references and count
    kidsCount--
    kid.parent = null
    kid.prev   = null
    kid.next   = null
    return this
  }

  **
  ** Remove all children objects.  Return this.
  **
  This clear()
  {
    ObixObj? p := kidsHead
    while (p != null)
    {
      x := p.next
      p.parent = p.prev = p.next = null
      p = x
    }

    kidsByName.clear
    kidsHead = kidsTail = null
    kidsCount = 0
    return this
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse an XML document into memory as a tree of ObixObj.
  ** If close is true, then the input stream is guaranteed to
  ** be closed.
  **
  static ObixObj readXml(InStream in, Bool close := true)
  {
    return ObixXmlParser(in).parse(close)
  }

  **
  ** Write this ObixObj as an XML document to the specified stream.
  ** No XML prolog is specified so that this method can used to
  ** write a snippet of the overall document.
  **
  virtual Void writeXml(OutStream out, Int indent := 0)
  {
    out.print(Str.spaces(indent)).print("<").print(elemName)
    if (name != null) out.print(" name='").writeXml(name, xmlEsc).print("'")
    if (href != null) out.print(" href='").print(href.encode).print("'")
    if (isNull) out.print(" isNull='true'")
    if (val != null)
    {
      out.print(" val='").writeXml(valToStr, xmlEsc).print("'")
      if (val is DateTime) out.print(" tz='").print(((DateTime)val).timeZone.fullName).print("'")
    }
    if (isEmpty) out.print("/>\n")
    else
    {
      out.print(">\n")
      each |ObixObj kid| { kid.writeXml(out, indent+1) }
      out.print(Str.spaces(indent)).print("</").print(elemName).print(">\n")
    }
    if (parent == null) out.flush
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal static const Uri[] noUris := Uri[,]
  internal static const ObixObj[] noChildren := ObixObj[,]
  internal static const Int xmlEsc := OutStream.xmlEscNewlines | OutStream.xmlEscQuotes

  private [Str:Obj]? kidsByName   // map of children by name
  private ObixObj? kidsHead       // children linked list
  private ObixObj? kidsTail       // children linked list
  private Int kidsCount           // children linked list
  private ObixObj? prev           // sibling in parents linked list
  private ObixObj? next           // sibling in parents linked list

}