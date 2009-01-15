//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jan 09  Brian Frank  Creation
//

using xml

**
** ObixXmlParser decodes an XML document into a ObixObj tree
**
internal class ObixXmlParser
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct from input stream.
  **
  new make(InStream in)
  {
    this.xparser = XParser(in)
  }

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse into memory as tree of ObixObjs.  If close is true,
  ** then guaranteed to close the input stream.
  **
  ObixObj parse(Bool close := true)
  {
    try
    {
      xparser.next
      return parseObj
    }
    finally
    {
      if (close) xparser.close
    }
  }

//////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the next object.  The XML parser should be positioned
  ** on the starting element (will automatically skip PIs).
  **
  private ObixObj parseObj()
  {
    // skip processing instructions
    while (xparser.nodeType === XNodeType.pi)
      xparser.next

    // should be on element start
    if (xparser.nodeType !== XNodeType.elemStart)
      throw err("Expected element start not $xparser.nodeType")

    // parse element name into ObixObj
    elem := xparser.elem
    obj := ObixObj()
    obj.elemName = elem.name

    // parse attributes
    elem.eachAttr |XAttr attr| { parseAttr(obj, elem, attr) }

    // advance node, and parse children elements
    xparser.next
    while (xparser.nodeType !== XNodeType.elemEnd)
    {
      // assume next node is an object element
      try
        obj.add(parseObj)
      catch (ArgErr e)
        throw XErr(e.toStr)
    }

    // advance past element end
    xparser.next

    // if a value wasn't specified, check for default
    if (obj.val == null)
      obj.val = ObixUtil.elemNameToDefaultVal[obj.elemName]

    return obj
  }

  private Void parseAttr(ObixObj obj, XElem elem, XAttr attr)
  {
    try
    {
      switch (attr.name)
      {
        case "name": obj.name = attr.val
        case "href": obj.href = Uri.decode(attr.val)
        case "val":  obj.val = parseVal(attr.val, elem)
        case "null": obj.isNull = attr.val.toBool
      }
    }
    catch (XErr e) throw e
    catch (Err e) throw err("Cannot parse attribute '$attr.name'", e)
  }

  private Obj parseVal(Str valStr, XElem elem)
  {
    func := ObixUtil.elemNameToFromStrFunc[elem.name]
    if (func == null) throw err("Element <$elem.name> cannot have val attribute")
    try
      return func(valStr, elem)
    catch (Err e)
      throw err("Cannot parse <$elem.name> value: $valStr.toCode", e)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private XErr err(Str msg, Err? cause := null)
  {
    return XErr(msg, xparser.line, xparser.col, cause)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  XParser xparser
}