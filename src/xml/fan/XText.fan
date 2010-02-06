//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Nov 08  Brian Frank  Creation
//

**
** XText represents the character data inside an element.
**
class XText : XNode
{

  **
  ** Construct a text node with the specified value.
  **
  new make(Str val)
  {
    this.val = val
  }

  **
  ** Return the `XNodeType.text`.
  **
  override XNodeType nodeType() { return XNodeType.text }

  **
  ** Character data for this text node.  If this text is to
  ** be written as a CDATA section, then this value must not
  ** contain the "]]>" substring.
  **
  Str val

  **
  ** If true then this text node was read/will be
  ** written as a CDATA section.  If set to true, then
  ** `val` must not contain the "]]>" substring.
  **
  Bool cdata

  **
  ** Return the string value (truncated if it is long).
  **
  override Str toStr()
  {
    if (val.size > 20) return val[0..20] + "..."
    return val
  }

  **
  ** Make a copy of this text node.
  **
  This copy()
  {
    return XText(val) { it.cdata = this.cdata }
  }

  **
  ** Write this node to the output stream.  If this node
  ** is set to be written as a CDATA section and the `val`
  ** string contains the "]]>" substring then throw IOErr.
  **
  override Void write(OutStream out)
  {
    if (cdata)
    {
      if (val.contains("]]>")) throw IOErr("CDATA val contains ']]>'")
      out.writeChars("<![CDATA[").writeChars(val).writeChars("]]>")
    }
    else
    {
      out.writeXml(val)
    }
  }

}