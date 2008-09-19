//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//
package fanx.emit;

import fan.sys.*;
import fanx.fcode.*;
import fanx.util.*;

/**
 * FPodEmit translates FPod fcode to Java bytecode as a class called <podName>.$Pod.
 * The pod class itself defines all the constants used by it's types.
 */
public class FPodEmit
  extends Emitter
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  public static Class emitAndLoad(FPod pod)
  {
    try
    {
      // lookup or load class
      Class cls;
      if (Sys.usePrecompiledOnly)
      {
        cls = Class.forName("fan." + pod.podName + ".$Pod");
      }
      else
      {
        FPodEmit emit = emit(pod);
        cls = FanClassLoader.loadClass(emit.className.replace('/', '.'), emit.classFile);
      }

      // set literal fields
      initFields(pod, cls);
      return cls;
    }
    catch (Exception e)
    {
      e.printStackTrace();
      throw new RuntimeException(e.toString());
    }
  }

  public static FPodEmit emit(FPod pod)
    throws Exception
  {
    FPodEmit emit = new FPodEmit(pod);
    emit.classFile = emit.emit();
    return emit;
  }

  public static void initFields(FPod fpod, Class cls)
    throws Exception
  {
    FLiterals literals = fpod.readLiterals();

    for (int i=0; i<literals.ints.size(); ++i)
      cls.getField("I"+i).set(null, literals.ints.get(i));
    for (int i=0; i<literals.floats.size(); ++i)
      cls.getField("F"+i).set(null, literals.floats.get(i));
    for (int i=0; i<literals.decimals.size(); ++i)
      cls.getField("D"+i).set(null, literals.decimals.get(i));
    for (int i=0; i<literals.strs.size(); ++i)
      cls.getField("S"+i).set(null, literals.strs.get(i));
    for (int i=0; i<literals.durations.size(); ++i)
      cls.getField("Dur"+i).set(null, literals.durations.get(i));
    for (int i=0; i<literals.uris.size(); ++i)
      cls.getField("U"+i).set(null, literals.uris.get(i));

    fpod.literals = null;
  }

  private FPodEmit(FPod pod)
    throws Exception
  {
    this.pod = pod;
    this.literals = pod.readLiterals();
  }

//////////////////////////////////////////////////////////////////////////
// Emit
//////////////////////////////////////////////////////////////////////////

  /**
   * Emit to bytecode classfile.
   */
  private Box emit()
  {
    init("fan/" + pod.podName + "/$Pod", "java/lang/Object", new String[0], EmitConst.PUBLIC | EmitConst.FINAL);

    // generate constant fields other types will reference, we don't
    // initialize them, rather we do that later via reflection
    for (int i=0; i<literals.ints.size(); ++i)
      emitField("I" + i, "Lfan/sys/Int;", EmitConst.PUBLIC | EmitConst.STATIC);
    for (int i=0; i<literals.floats.size(); ++i)
      emitField("F" + i, "Lfan/sys/Float;", EmitConst.PUBLIC | EmitConst.STATIC);
    for (int i=0; i<literals.decimals.size(); ++i)
      emitField("D" + i, "Lfan/sys/Decimal;", EmitConst.PUBLIC | EmitConst.STATIC);
    for (int i=0; i<literals.strs.size(); ++i)
      emitField("S" + i, "Lfan/sys/Str;", EmitConst.PUBLIC | EmitConst.STATIC);
    for (int i=0; i<literals.durations.size(); ++i)
      emitField("Dur" + i, "Lfan/sys/Duration;", EmitConst.PUBLIC | EmitConst.STATIC);
    for (int i=0; i<literals.uris.size(); ++i)
      emitField("U" + i, "Lfan/sys/Uri;", EmitConst.PUBLIC | EmitConst.STATIC);

    return pack();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public Box classFile;
  FPod pod;
  FLiterals literals;

}
