//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Nov 08  Brian Frank  Creation
//

**
** XML processing instruction node.
**
class XPi : XNode
{

  **
  ** Construct a processing instruction with specified target and val.
  **
  new make(Str target, Str val)
  {
    this.target = target
    this.val = val
  }

  **
  ** Return the `XNodeType.pi`.
  **
  override XNodeType nodeType() { return XNodeType.pi }

  **
  ** Target name for the processing instruction.  It
  ** must be a valid XML name production.
  **
  Str target

  **
  ** String value of processing instruction.  This value
  ** must not contain the "?>".
  **
  Str val

  **
  ** Return string representation of this processing instruction.
  **
  override Str toStr()
  {
    return "<?${target} ${val}?>"
  }

  **
  ** Write this node to the output stream.
  **
  override Void write(OutStream out)
  {
    out.writeChar('<').writeChar('?').writeChars(target).writeChar(' ')
       .writeChars(val).writeChar('?').writeChar('>')
  }

}