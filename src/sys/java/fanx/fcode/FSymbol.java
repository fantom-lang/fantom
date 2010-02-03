//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;

/**
 * FSymbol is the fcode representation of sys::Symbol.
 */
public class FSymbol
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// TODO-FACETS: 1.0.45 const mapping to 1.0.51 fcode format
//////////////////////////////////////////////////////////////////////////

  public static int flags(FStore.Input in) throws IOException
  {
    int f = in.u4();
    if (in.fpod.version == 0x1000045) f = oldFlags(f);
    return f;
  }

  public static int oldFlags(int old)
  {
    int flag = 1;
    int r = 0;
    for (int i=0; i<24; ++i)
    {
      if ((old & flag) != 0) r |= oldFlag(flag);
      flag <<= 1;
    }
    return r;
  }

  public static int oldFlag(int old)
  {
    switch (old)
    {
      case 0x00000001: return FConst.Abstract;
      case 0x00000002: return FConst.Const;
      case 0x00000004: return FConst.Ctor;
      case 0x00000008: return FConst.Enum;
      case 0x00000010: return FConst.Final;
      case 0x00000020: return FConst.Getter;
      case 0x00000040: return FConst.Internal;
      case 0x00000080: return FConst.Mixin;
      case 0x00000100: return FConst.Native;
      case 0x00000200: return FConst.Override;
      case 0x00000400: return FConst.Private;
      case 0x00000800: return FConst.Protected;
      case 0x00001000: return FConst.Public;
      case 0x00002000: return FConst.Setter;
      case 0x00004000: return FConst.Static;
      case 0x00008000: return FConst.Storage;
      case 0x00010000: return FConst.Synthetic;
      case 0x00020000: return FConst.Virtual;
      default: throw new RuntimeException("0x" + Integer.toHexString(old));
    }
  }


//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public FSymbol(FPod pod)
  {
    this.pod = pod;
  }

//////////////////////////////////////////////////////////////////////////
// Meta IO
//////////////////////////////////////////////////////////////////////////

  public FSymbol read(FStore.Input in) throws IOException
  {
    name   = in.u2();
flags = FSymbol.flags(in);
//    flags  = in.u4();
    of     = in.u2();
    val    = in.utf();
    attrs  = FAttrs.read(in);
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public FPod pod;        // parent pod
  public int name;        // name index
  public int flags;       // bitmask
  public int of;          // typeRef index
  public String val;      // serialized value
  public FAttrs attrs;    // meta-data attributes

}