//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 Nov 08  Brian Frank  Creation
//

**
** XML document encapsulates the root element and document type.
**
class XDoc : XNode
{

  **
  ** Construct with optional root elem.
  **
  new make(XElem? root := null)
  {
    if (root != null)
      this.root = root
    else
      this.root = XElem("undefined")
  }

  **
  ** Return the `XNodeType.doc`.
  **
  override XNodeType nodeType() { return XNodeType.doc }

  **
  ** Document type declaration or null if undefined.
  **
  XDocType? docType

  **
  ** Root element.
  **
  XElem root
  {
    set { val.parent = this; @root = val }
  }

  **
  ** Return string representation of this processing instruction.
  **
  override Str toStr()
  {
    return "<?xml version='1.0'?>"
  }

  **
  ** Write this node to the output stream.
  **
  override Void write(OutStream out)
  {
    out.writeChars("<?xml version='1.0' encoding='${out.charset}'?>\n")
    if (docType != null) out.writeChars(docType.toStr).write('\n')
    root.write(out)
    out.writeChar('\n')
  }

}