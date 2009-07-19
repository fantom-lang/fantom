//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation (Java)
//   19 Jul 09  Brian Frank  Port to C#
//

using System;
using Fan.Sys;

namespace Fanx.Fcode
{
  /// <summary>
  /// FSymbolRef stores a symbolRef structure used to reference symbol.
  /// </summary>
  public sealed class FSymbolRef
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    FSymbolRef(string podName, string symbolName)
    {
      this.podName = podName;
      this.symbolName = symbolName;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public string qname() { return podName + "::" + symbolName; }

    /** Attempt to resolve, if not print error and return null */
    public Symbol resolve()
    {
      try
      {
        return Pod.find(podName).symbol(symbolName);
      }
      catch (Exception e) {  Err.dumpStack(e); }
      return null;
    }

    public override string ToString() { return "@" + podName + "::" + symbolName; }

    public static FSymbolRef read(FStore.Input input)
    {
      return new FSymbolRef(input.fpod.name(input.u2()), input.fpod.name(input.u2()));
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public readonly string podName;     // pod name "sys"
    public readonly string symbolName;  // simple type name "serializable"

  }
}