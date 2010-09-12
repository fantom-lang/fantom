//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 10  Brian Frank  Creation
//
package fanx.emit;

import java.lang.Enum;
import java.util.*;
import fan.sys.*;
import fan.sys.List;
import fanx.fcode.*;
import fanx.serial.*;
import fanx.util.*;

/**
 * FFacetEmit is used to emit Fantom facets as Java annotations.
 */
class FFacetEmit
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// Factories for Type, Field, and Methods
//////////////////////////////////////////////////////////////////////////

  static void emitType(Emitter emit, FPod pod, FAttrs attrs)
  {
    FFacetEmit x = new FFacetEmit(emit, pod, attrs);
    if (x.num == 0) return;

    AttrEmit attr = emit.emitAttr("RuntimeVisibleAnnotations");
    x.doEmit(attr.info);
  }

  static void emitField(FieldEmit fe, FPod pod, FAttrs attrs)
  {
    FFacetEmit x = new FFacetEmit(fe.emit, pod, attrs);
    if (x.num == 0) return;

    AttrEmit attr = fe.emitAttr("RuntimeVisibleAnnotations");
    x.doEmit(attr.info);
  }

  static void emitMethod(MethodEmit me, FPod pod, FAttrs attrs)
  {
    FFacetEmit x = new FFacetEmit(me.emit, pod, attrs);
    if (x.num == 0) return;

    AttrEmit attr = me.emitAttr("RuntimeVisibleAnnotations");
    x.doEmit(attr.info);
  }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  private FFacetEmit(Emitter emit, FPod pod, FAttrs attrs)
  {
    this.emit   = emit;
    this.pod    = pod;
    this.facets = attrs.facets;
    this.num    = computeNumJavaFacets();
  }

  private int computeNumJavaFacets()
  {
    if (facets == null) return 0;
    int num = 0;
    for (int i=0; i <facets.length; ++i)
      if (pod.typeRef(facets[i].type).isFFI()) num++;
    return num;
  }

//////////////////////////////////////////////////////////////////////////
// RuntimeVisibleAnnotation Generation
//////////////////////////////////////////////////////////////////////////

  private void doEmit(Box info)
  {
    info.u2(num);
    try
    {
      for (int i=0; i <facets.length; ++i)
      {
        FAttrs.FFacet facet = facets[i];
        FTypeRef type = pod.typeRef(facet.type);
        if (type.isFFI()) encode(info, type, facet.val);
      }
    }
    catch (Exception e)
    {
      System.out.println("ERROR: Cannot emit annotations for " + emit.className);
      System.out.println("  Facet type: " + curType);
      e.printStackTrace();
      info.len = 0;
      info.u2(0);
    }
  }

  private void encode(Box info, FTypeRef type, String val)
    throws Exception
  {
    // reset type class
    this.curType  = type;
    this.curClass = null;

    // parse value into name/value elements
    Elem[] elems = parseElems(val);

    // annotation type
    int cls = emit.cls(type.jname());
    info.u2(cls);
    info.u2(elems.length);
    for (int i=0; i<elems.length; ++i)
      encodeElem(info, type, elems[i]);
  }

  private void encodeElem(Box info, FTypeRef type, Elem elem)
    throws Exception
  {
    // element_name_index
    info.u2(emit.utf(elem.name));

    // element_value_pairs
    Object v = elem.val;
    if (v instanceof String)  { encodeStr(info, elem);   return; }
    if (v instanceof Boolean) { encodeBool(info, elem);  return; }
    if (v instanceof Long)    { encodeInt(info, elem);   return; }
    if (v instanceof Double)  { encodeFloat(info, elem); return; }
    if (v instanceof Enum)    { encodeEnum(info, elem);  return; }
    if (v instanceof Type)    { encodeType(info, elem);  return; }
    throw new RuntimeException("Unsupported annotation element type '" + type + "." + elem.name + "': " + elem.val.getClass().getName());
  }

  private void encodeStr(Box info, Elem elem)
  {
    String val = (String)elem.val;
    info.u1('s');
    info.u2(emit.utf(val));
  }

  private void encodeBool(Box info, Elem elem)
  {
    Boolean val = (Boolean)elem.val;
    info.u1('Z');
    info.u2(emit.intConst(val.booleanValue() ? 1 : 0));
  }

  private void encodeInt(Box info, Elem elem)
    throws Exception
  {
    Long val = (Long)elem.val;
    Class cls = curClassElemType(elem.name);

    if (cls == int.class)
    {
      info.u1('I');
      info.u2(emit.intConst(Integer.valueOf(val.intValue())));
    }
    else if (cls == short.class)
    {
      info.u1('S');
      info.u2(emit.intConst(Integer.valueOf(val.intValue())));
    }
    else if (cls == byte.class)
    {
      info.u1('B');
      info.u2(emit.intConst(Integer.valueOf(val.intValue())));
    }
    else
    {
      info.u1('J');
      info.u2(emit.longConst(val));
    }
  }

  private void encodeFloat(Box info, Elem elem)
    throws Exception
  {
    Double val = (Double)elem.val;
    Class cls = curClassElemType(elem.name);
    if (cls == double.class)
    {
      info.u1('D');
      info.u2(emit.doubleConst(val));
    }
    else
    {
      info.u1('F');
      info.u2(emit.floatConst(Float.valueOf(val.floatValue())));
    }
  }

  private void encodeEnum(Box info, Elem elem)
    throws Exception
  {
    Enum e = (Enum)elem.val;
    info.u1('e');
    info.u2(emit.utf(e.getClass().getName()));
    info.u2(emit.utf(e.toString()));
  }

  private void encodeType(Box info, Elem elem)
    throws Exception
  {
    Type t = (Type)elem.val;
    info.u1('c');
    info.u2(emit.utf(FanUtil.toJavaMemberSig(t)));
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private Class curClassElemType(String name)
    throws Exception
  {
    return curClass().getMethod(name, new Class[0]).getReturnType();
  }

  private Class curClass()
    throws Exception
  {
    if (curClass == null)
      curClass = Env.cur().loadJavaClass(curType.jname().replace("/", "."));
    return curClass;
  }

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  private Elem[] parseElems(String val)
    throws Exception
  {
    if (val.length() == 0) return noElems;

    // TODO: temp hack to parse serialized Fantom object
    // without real Fantom type to use
    ArrayList acc = new ArrayList();
    val= val.substring(val.indexOf('{')+1, val.length()-2);
    StringTokenizer st = new StringTokenizer(val, ";");
    while (st.hasMoreTokens())
    {
      String pair = st.nextToken();
      int eq = pair.indexOf('=');
      String n  = pair.substring(0, eq);
      String v = pair.substring(eq+1);
      acc.add(new Elem(n, parseElemVal(n, v)));
    }
    return (Elem[])acc.toArray(new Elem[acc.size()]);
  }

  private Object parseElemVal(String name, String val)
    throws Exception
  {
    try
    {
      return ObjDecoder.decode(val);
    }
    catch (Exception e)
    {
      throw new Exception("Cannot parse " + curType + "." + name + " = " + val + "\n  " + e, e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Elem
//////////////////////////////////////////////////////////////////////////

  static class Elem
  {
    Elem(String name, Object val) { this.name = name; this.val = val; }
    String name;
    Object val;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final Elem[] noElems = new Elem[0];

  private final Emitter emit;
  private final FPod pod;
  private final FAttrs.FFacet[] facets;
  private final int num;
  private FTypeRef curType;
  private Class curClass;
}