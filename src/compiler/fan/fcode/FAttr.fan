//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//   19 Aug 06  Brian Frank  Ported from Java to Fan
//

**
** FAttr is attribute meta-data for a FType or FSlot
**
class FAttr : FConst
{

//////////////////////////////////////////////////////////////////////////
// Data
//////////////////////////////////////////////////////////////////////////

  Str utf() { return data.seek(0).readUtf }

  Int u2() { return data.seek(0).readU2 }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  Void write(OutStream out)
  {
    out.writeI2(name)
    FUtil.writeBuf(out, data)
  }

  FAttr read(InStream in)
  {
    name  = in.readU2
    data  = FUtil.readBuf(in)
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Int name    // name index
  Buf? data

}