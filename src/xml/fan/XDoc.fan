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

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the `XNodeType.doc`.
  **
  override XNodeType nodeType() { return XNodeType.doc }

  **
  ** Document type declaration or null if undefined.
  **
  XDocType? docType

  **
  ** Return string representation.
  **
  override Str toStr()
  {
    return "<?xml version='1.0'?>"
  }

//////////////////////////////////////////////////////////////////////////
// Children
//////////////////////////////////////////////////////////////////////////

  **
  ** Root element.
  **
  XElem root
  {
    set
    {
      if (it.parent != null) throw ArgErr("Node already parented: $it")
      it.parent = this
      this.&root = it
    }
  }

  **
  ** Get any processing instructions declared before the
  ** root element.  Processing instructions after the root
  ** are not supported.
  **
  XNode[] pis() { return piList.ro }

  **
  ** Add a node to the document.  If the node is an XElem then it
  ** is defined as the `root` element, otherwise the child must be
  ** a `XPi`.  Return this.
  **
  This add(Obj child)
  {
    if (child is XElem) { root = child; return this }
    pi := (XPi)child
    if (pi.parent != null) throw ArgErr("Node already parented: $pi")
    pi.parent = this
    piList = piList.rw
    piList.add(pi)
    return this
  }

  **
  ** Remove the processing instruction by reference.
  **
  XPi? removePi(XPi pi)
  {
    if (piList.isEmpty) return null
    if (piList.removeSame(pi) !== pi) return null
    pi.parent = null
    return pi
  }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  **
  ** Write this node to the output stream.
  **
  override Void write(OutStream out)
  {
    out.writeChars("<?xml version='1.0' encoding='${out.charset}'?>\n")
    if (docType != null) out.writeChars(docType.toStr).writeChar('\n')
    piList.each |XPi pi| { pi.write(out); out.writeChar('\n') }
    root.write(out)
    out.writeChar('\n')
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal const static XPi[] noPis := XPi[,]

  internal XPi[] piList :=  noPis

}