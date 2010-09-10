//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 10  Brian Frank  Creation
//
package fanx.emit;

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
    for (int i=0; i <facets.length; ++i)
    {
      FAttrs.FFacet facet = facets[i];
      FTypeRef type = pod.typeRef(facet.type);
      if (type.isFFI())
        encode(info, type, facet.val);
    }
  }

  private void encode(Box info, FTypeRef type, String val)
  {
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
  {
    // element_name_index
    info.u2(emit.utf(elem.name));

    // element_value_pairs
    Object v = elem.val;
    if (v instanceof Boolean) { encodeBool(info, (Boolean)v); return; }
    if (v instanceof String)  { encodeStr(info, (String)v); return; }
    throw new RuntimeException("Unsupported annotation element type '" + type + "." + elem.name + "': " + elem.val.getClass().getName());
  }

  private void encodeBool(Box info, Boolean val)
  {
    info.u1('Z');
    info.u2(emit.intConst(val.booleanValue() ? 1 : 0));
  }

  private void encodeStr(Box info, String val)
  {
    info.u1('s');
    info.u2(emit.utf(val));
  }

  private Elem[] parseElems(String val)
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
      acc.add(new Elem(n, ObjDecoder.decode(v)));
    }
    return (Elem[])acc.toArray(new Elem[acc.size()]);
  }

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
}