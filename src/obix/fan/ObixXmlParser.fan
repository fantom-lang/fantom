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
      // advance to first node
      xparser.next

      // skip processing instructions
      while (xparser.nodeType === XNodeType.pi) xparser.next

      // parse object
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
      // if processing instruction skip it
      if (xparser.nodeType === XNodeType.pi)
      {
        xparser.next
        continue
      }

      // if unknown element, then gracefully skip it
      if (!ObixUtil.elemNames[xparser.elem.name])
      {
        xparser.skip
        xparser.next
        continue
      }

      // assume next node is an object element
      try
        obj.add(parseObj)
      catch (ArgErr e)
        throw err(e.toStr)
    }

    // advance past element end
    xparser.next

    // if a value wasn't specified, check for default
    if (obj.val == null)
    {
      defVal := ObixUtil.elemNameToDefaultVal[obj.elemName]
      if (defVal === ObixUtil.defaultsToNull)
        obj.isNull = true
      else
        obj.val = defVal
    }

    return obj
  }

  private Void parseAttr(ObixObj obj, XElem elem, XAttr attr)
  {
    try
    {
      switch (attr.name)
      {
        // identity
        case "name": obj.name = attr.val
        case "href": obj.href = ObixUtil.parseUri(attr.val)
        case "is":   obj.contract = Contract(attr.val)
        case "of":   obj.of = Contract(attr.val)
        case "in":   obj.in = Contract(attr.val)
        case "out":  obj.out = Contract(attr.val)

        // value
        case "val":  parseVal(obj, attr.val, elem)
        case "null": obj.isNull = attr.val.toBool

        // facets
        case "displayName": obj.displayName = attr.val
        case "display":     obj.display = attr.val
        case "icon":        obj.icon = ObixUtil.parseUri(attr.val)
        case "min":         obj.min = parseMinMax(attr.val, elem)
        case "max":         obj.max = parseMinMax(attr.val, elem)
        case "range":       obj.range = ObixUtil.parseUri(attr.val)
        case "precision":   obj.precision = attr.val.toInt
        case "status":      obj.status = Status(attr.val)
        case "tz":          if (obj.tz == null) obj.tz = parseTimeZone(attr.val)
        case "unit":        if (attr.val.startsWith("obix:units/")) obj.unit = Unit.fromStr(attr.val[11..-1], false)
        case "writable":    obj.writable = attr.val.toBool
      }
    }
    catch (XErr e) throw e
    catch (Err e) throw err("Cannot parse attribute '$attr.name'", e)
  }

  private Void parseVal(ObixObj obj, Str valStr, XElem elem)
  {
    func := ObixUtil.elemNameToFromStrFunc[elem.name]

    // older versions of Niagara use '<obj>' with a value, so
    // be lenient and turn those into '<str>' objects
    if (func == null && obj.elemName == "obj")
    {
      obj.elemName = "str"
      obj.val = valStr
      return
    }

    try
      obj.val = func(valStr, elem)
    catch (Err e)
      throw err("Cannot parse <$elem.name> value: $valStr.toCode", e)
  }

  private Obj parseMinMax(Str valStr, XElem elem)
  {
    func := ObixUtil.elemNameToMinMaxFunc[elem.name]
    if (func == null) throw err("Element <$elem.name> cannot have val min/max")
    try
      return func(valStr, elem)
    catch (Err e)
      throw err("Cannot parse <$elem.name> min/max: $valStr.toCode", e)
  }

  private TimeZone? parseTimeZone(Str str)
  {
    ObixUtil.tzSwizzles[str] ?: TimeZone(str)
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