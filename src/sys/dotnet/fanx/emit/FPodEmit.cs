//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Oct 05  Andy Frank  Creation
//

using System;
using PERWAPI;
using Fan.Sys;
using Fanx.Fcode;
using Fanx.Util;

namespace Fanx.Emit
{

  /// <summary>
  /// FPodEmit translates FPod fcode to IL as a class called <podName>.$Pod.
  /// The pod class itself defines all the constants used by it's types.
  /// </summary>
  public class FPodEmit
  {

  //////////////////////////////////////////////////////////////////////////
  // Emit
  //////////////////////////////////////////////////////////////////////////

    public static void emit(Emitter emitter, FPod pod)
    {
      //FPodEmit emit = new FPodEmit(pod);

      TypeAttr tattr = TypeAttr.Public | TypeAttr.Sealed;
      FieldAttr fattr = FieldAttr.Public | FieldAttr.Static;

      emitter.emitClass("System.Object", FanUtil.toDotnetTypeName(pod.m_podName, "$Pod", false),
        new string[0], tattr);

      pod.readLiterals();

      // generate constant fields other types will reference, we don't
      // initialize them, rather we do that later via reflection
      for (int i=0; i<pod.m_literals.m_ints.size(); i++)
        emitter.emitField("I" + i, "System.Int64", fattr);
      for (int i=0; i<pod.m_literals.m_floats.size(); i++)
        emitter.emitField("F" + i, "System.Double", fattr);
      for (int i=0; i<pod.m_literals.m_decimals.size(); i++)
        emitter.emitField("D" + i, "Fan.Sys.BigDecimal", fattr);
      for (int i=0; i<pod.m_literals.m_strs.size(); i++)
        emitter.emitField("S" + i, "System.String", fattr);
      for (int i=0; i<pod.m_literals.m_durations.size(); i++)
        emitter.emitField("Dur" + i, "Fan.Sys.Duration", fattr);
      for (int i=0; i<pod.m_literals.m_uris.size(); i++)
        emitter.emitField("U" + i, "Fan.Sys.Uri", fattr);
    }

  //////////////////////////////////////////////////////////////////////////
  // Load
  //////////////////////////////////////////////////////////////////////////

    public static System.Type load(System.Reflection.Assembly assembly, FPod pod)
    {
      System.Type type = null;
      string name = FanUtil.toDotnetTypeName(pod.m_podName, "$Pod", false);

      //if (Sys.usePrecompiledOnly)
      //  type = System.Type.GetType(name);
      //else
        type = assembly.GetType(name);

      initFields(pod, type);
      return type;
    }

    private static void initFields(FPod pod, System.Type type)
    {
      FLiterals literals = pod.readLiterals();

      for (int i=0; i<literals.m_ints.size(); i++)
        type.GetField("I"+i).SetValue(null, literals.m_ints.get(i));
      for (int i=0; i<literals.m_floats.size(); i++)
        type.GetField("F"+i).SetValue(null, literals.m_floats.get(i));
      for (int i=0; i<literals.m_decimals.size(); i++)
        type.GetField("D"+i).SetValue(null, literals.m_decimals.get(i));
      for (int i=0; i<literals.m_strs.size(); i++)
        type.GetField("S"+i).SetValue(null, literals.m_strs.get(i));
      for (int i=0; i<literals.m_durations.size(); i++)
        type.GetField("Dur"+i).SetValue(null, literals.m_durations.get(i));
      for (int i=0; i<literals.m_uris.size(); i++)
        type.GetField("U"+i).SetValue(null, literals.m_uris.get(i));
    }
  }
}