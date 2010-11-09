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
      this.&name = it
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
  ** The XML element name to use for this object.  If not
  ** one of the valid oBIX element names then throw ArgErr.
  ** Valid element names are:
  **   obj, bool, int, real, str, enum, uri, abstime,
  **   reltime, date, time, list, op, feed, ref, err
  **
  Str elemName := "obj"
  {
    set
    {
      if (!ObixUtil.elemNames[it]) throw ArgErr("Invalid elemName: $it")
      this.&elemName = it
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
    if (val != null)  s.add(" val='").add(ObixUtil.valToStr(val)).add("'")
    s.add(">");
    return s.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Contracts
//////////////////////////////////////////////////////////////////////////

  **
  ** The list of contract URIs this object implemented
  ** as specified by 'is' attribute.
  **
  Contract contract := Contract.empty

  **
  ** The 'of' contract for lists and feeds.
  **
  Contract? of

  **
  ** The 'in' contract for operations and feeds.
  **
  Contract? in

  **
  ** The 'out' contract for operations.
  **
  Contract? out

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
      // TODO: clean this up
      if (elemName == "enum" && it is Str) { &val = it; return }
      if (it != null)
      {
        elem := ObixUtil.valTypeToElemName[Type.of(it)]
        if (elem == null) throw ArgErr("Invalid val type: ${Type.of(it)}")
        this.&elemName = elem
        if (it is DateTime && tz == null)
        {
          tz := ((DateTime)it).tz
          if (!tz.fullName.startsWith("Etc/")) this.tz = tz
        }
      }
      &val = it
    }
  }

  **
  ** Get the value encoded as a string.  The string is *not*
  ** XML escaped.  If value is null return "null".
  **
  Str valToStr()
  {
    return ObixUtil.valToStr(val)
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
  ** Get a child by name.  If not found and checked is true
  ** then throw NameErr, otherwise null.
  **
  @Operator ObixObj? get(Str name, Bool checked := true)
  {
    child := kidsByName?.get(name)
    if (child != null) return child
    if (checked) throw NameErr("Missing obix child '$name'")
    return null
  }

  **
  ** If the name maps to a child object, then return that
  ** child's value.  Otherwise route to 'Obj.trap'.
  **
  override Obj? trap(Str name, Obj?[]? args)
  {
    child := kidsByName?.get(name)
    if (child != null) return child.val
    return super.trap(name, args)
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
  ** Get the first child returned by `list` or null.
  **
  ObixObj? first() { kidsHead }

  **
  ** Get the last child returned by `list` or null.
  **
  ObixObj? last() { kidsTail }

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
    if (kid.name != null && kidsByName != null && kidsByName.containsKey(kid.name) && elemName != "list")
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
// Facets
//////////////////////////////////////////////////////////////////////////

  **
  ** Localized human readable version of the name attribute.
  **
  Str? displayName

  **
  ** Localized human readable string summary of the object.
  **
  Str? display

  **
  ** Reference to the graphical icon.
  **
  Uri? icon

  **
  ** Inclusive minium for value.
  **
  Obj? min

  **
  ** Inclusive maximum for value.
  **
  Obj? max

  **
  ** Number of decimal places to use for a real value.
  **
  Int? precision

  **
  ** Reference to the range definition of an enum or bool value.
  **
  Uri? range

  **
  ** Status facet indicates quality and state.
  **
  Status status := Status.ok

  **
  ** TimeZone facet assocaited with abstime, date, and time objects.
  ** This field is automatically updated when `val` is assigned a
  ** DateTime unless its timezone is UTC or starts with "Etc/".  After
  ** decoding this field is set only if an explicit "tz" attribute was
  ** specified.
  **
  TimeZone? tz

  **
  ** Unit of measurement for int and real values.  We only support units
  ** which are predefind in the oBIX unit database and specified using the
  ** URI "obix:units/".  These units are mapped to the `sys::Unit` API.
  ** If an unknown unit URI is decoded, then it is silently ignored and
  ** this field will be null.
  **
  Unit? unit

  **
  ** Specifies is this object can be written, or false if readonly.
  **
  Bool writable

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
    // identity
    out.print(Str.spaces(indent)).print("<").print(elemName)
    if (name != null) out.print(" name='").writeXml(name, xmlEsc).print("'")
    if (href != null) out.print(" href='").print(href.encode).print("'")

    // contracts
    if (!contract.isEmpty) out.print(" is='").print(contract).print("'")
    if (of != null && !of.isEmpty) out.print(" of='").print(of).print("'")
    if (in != null && !in.isEmpty) out.print(" in='").print(in).print("'")
    if (this.out != null && !this.out.isEmpty) out.print(" out='").print(this.out).print("'")

    // value
    if (val != null) out.print(" val='").writeXml(valToStr, xmlEsc).print("'")
    if (isNull) out.print(" isNull='true'")

    // facets
    if (displayName != null) out.print(" displayName='").writeXml(displayName, xmlEsc).print("'")
    if (display != null) out.print(" display='").writeXml(display, xmlEsc).print("'")
    if (icon != null) out.print(" icon='").print(icon.encode).print("'")
    if (min != null) out.print(" min='").print(ObixUtil.valToStr(min)).print("'")
    if (max != null) out.print(" max='").print(ObixUtil.valToStr(max)).print("'")
    if (precision != null) out.print(" precision='").print(precision).print("'")
    if (range != null) out.print(" range='").print(range.encode).print("'")
    if (status !== Status.ok) out.print(" status='").print(status).print("'")
    if (status !== Status.ok) out.print(" status='").print(status).print("'")
    if (tz != null) out.print(" tz='").print(tz.fullName).print("'")
    if (unit != null) out.print(" unit='obix:units/").print(unit.name).print("'")
    if (writable) out.print(" writable='true'")

    // children
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
  internal static const Int xmlEsc := OutStream.xmlEscNewlines.or(OutStream.xmlEscQuotes)

  private [Str:ObixObj]? kidsByName // map of children by name
  private ObixObj? kidsHead         // children linked list
  private ObixObj? kidsTail         // children linked list
  private Int kidsCount             // children linked list
  private ObixObj? prev             // sibling in parents linked list
  private ObixObj? next             // sibling in parents linked list

}