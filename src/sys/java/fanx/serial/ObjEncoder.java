//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Aug 07  Brian Frank  Creation
//
package fanx.serial;

import java.math.BigDecimal;
import java.util.Iterator;
import java.util.Map.Entry;
import fan.sys.*;
import fanx.util.*;

/**
 * ObjEncoder serializes an object to an output stream.
 */
public class ObjEncoder
{

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

  public static String encode(Object obj)
  {
    StrBufOutStream out = new StrBufOutStream();
    new ObjEncoder(out, null).writeObj(obj);
    return out.string();
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public ObjEncoder(OutStream out, Map options)
  {
    this.out = out;
    if (options != null) initOptions(options);
  }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  public void writeObj(Object obj)
  {
    if (obj == null)
    {
      w("null");
      return;
    }

    if (obj.getClass().getName().charAt(0) == 'j')
    {
      if (obj instanceof Boolean) { w(obj.toString()); return; }
      if (obj instanceof String)  { wStrLiteral(obj.toString(), '"'); return; }
      if (obj instanceof Long)    { w(obj.toString()); return; }
      if (obj instanceof Double)  { FanFloat.encode((Double)obj, this); return; }
      if (obj instanceof BigDecimal) { FanDecimal.encode((BigDecimal)obj, this); return; }
    }

    if (obj instanceof Literal)
    {
      ((Literal)obj).encode(this);
      return;
    }

    Type type = FanObj.typeof(obj);
    Serializable ser = (Serializable)type.facet(Sys.SerializableType, false);
    if (ser != null)
    {
      if (ser.simple)
        writeSimple(type, obj);
      else
        writeComplex(type, obj, ser);
    }
    else
    {
      if (skipErrors)
        w("null /* Not serializable: ").w(type.qname()).w(" */");
      else
        throw IOErr.make("Not serializable: " + type);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Simple
//////////////////////////////////////////////////////////////////////////

  private void writeSimple(Type type, Object obj)
  {
    wType(type).w('(').wStrLiteral(FanObj.toStr(obj), '"').w(')');
  }

//////////////////////////////////////////////////////////////////////////
// Complex
//////////////////////////////////////////////////////////////////////////

  private void writeComplex(Type type, Object obj, Serializable ser)
  {
    wType(type);

    boolean first = true;
    Object defObj = null;
    if (skipDefaults)
    {
      // attempt to instantiate default object for type,
      // this will fail if complex has it-block ctor
      try { defObj = FanObj.typeof(obj).make(); } catch (Exception e) {}
    }

    List fields = type.fields();
    for (int i=0; i<fields.sz(); ++i)
    {
      Field f = (Field)fields.get(i);

      // skip static, transient, and synthetic (once) fields
      if (f.isStatic() || f.isSynthetic() || f.hasFacet(Sys.TransientType))
        continue;

      // get the value
      Object val = f.get(obj);

      // if skipping defaults
      if (defObj != null)
      {
        Object defVal = f.get(defObj);
        if (OpUtil.compareEQ(val, defVal)) continue;
      }

      // if first then open braces
      if (first) { w('\n').wIndent().w('{').w('\n'); level++; first = false; }

      // field name =
      wIndent().w(f.name()).w('=');

      // field value
      curFieldType = f.type().toNonNullable();
      writeObj(val);
      curFieldType = null;

      w('\n');
    }

    // if collection
    if (ser.collection)
      first = writeCollectionItems(type, obj, first);

    // if we output fields, then close braces
    if (!first) { level--; wIndent().w('}'); }
  }

//////////////////////////////////////////////////////////////////////////
// Collection (@collection)
//////////////////////////////////////////////////////////////////////////

  private boolean writeCollectionItems(Type type, Object obj, boolean first)
  {
    // lookup each method
    Method m = type.method("each", false);
    if (m == null) throw IOErr.make("Missing " + type.qname() + ".each");

    // call each(it)
    EachIterator it = new EachIterator(first);
    m.invoke(obj, new Object[] { it });
    return it.first;
  }

  static final FuncType eachIteratorType = new FuncType(new Type[] { Sys.ObjType }, Sys.VoidType);

  class EachIterator extends Func.Indirect1
  {
    EachIterator (boolean first) { super(eachIteratorType); this.first = first; }
    public Object call(Object obj)
    {
      if (first) { w('\n').wIndent().w('{').w('\n'); level++; first = false; }
      wIndent();
      writeObj(obj);
      w(',').w('\n');
      return null;
    }
    boolean first;
  }

//////////////////////////////////////////////////////////////////////////
// List
//////////////////////////////////////////////////////////////////////////

  public void writeList(List list)
  {
    // get of type
    Type of = list.of();

    // decide if we're going output as single or multi-line format
    boolean nl = isMultiLine(of);

    // figure out if we can use an inferred type
    boolean inferred = false;
    if (curFieldType != null && curFieldType.fits(Sys.ListType))
    {
      inferred = true;
    }

    // clear field type, so it doesn't get used for inference again
    curFieldType = null;

    // if we don't have an inferred type, then prefix of type
    if (!inferred) wType(of);

    // handle empty list
    int size = list.sz();
    if (size == 0) { w("[,]"); return; }

    // items
    if (nl) w('\n').wIndent();
    w('[');
    level++;
    for (int i=0; i<size; ++i)
    {
      if (i > 0) w(',');
       if (nl) w('\n').wIndent();
      writeObj(list.get(i));
    }
    level--;
    if (nl) w('\n').wIndent();
    w(']');
  }

//////////////////////////////////////////////////////////////////////////
// Map
//////////////////////////////////////////////////////////////////////////

  public void writeMap(Map map)
  {
    // get k,v type
    MapType t = (MapType)map.typeof();

    // decide if we're going output as single or multi-line format
    boolean nl = isMultiLine(t.k) || isMultiLine(t.v);

    // figure out if we can use an inferred type
    boolean inferred = false;
    if (curFieldType != null && curFieldType.fits(Sys.MapType))
    {
      inferred = true;
    }

    // clear field type, so it doesn't get used for inference again
    curFieldType = null;

    // if we don't have an inferred type, then prefix of type
    if (!inferred) wType(t);

    // handle empty map
    if (map.isEmpty()) { w("[:]"); return; }

    // items
    level++;
    w('[');
    boolean first = true;
    Iterator it = map.pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      if (first) first = false; else w(',');
      if (nl) w('\n').wIndent();
      Object key = e.getKey();
      Object val = e.getValue();
      writeObj(key); w(':'); writeObj(val);
    }
    w(']');
    level--;
  }

  private boolean isMultiLine(Type t)
  {
    return t.pod() != Sys.sysPod;
  }

//////////////////////////////////////////////////////////////////////////
// Output
//////////////////////////////////////////////////////////////////////////

  public final ObjEncoder wType(Type t)
  {
    return w(t.signature());
  }

  public final ObjEncoder wStrLiteral(String s, char quote)
  {
    int len = s.length();
    w(quote);
    // NOTE: these escape sequences are duplicated in FanStr.toCode()
    for (int i=0; i<len; ++i)
    {
      char c = s.charAt(i);
      switch (c)
      {
        case '\n': w('\\').w('n'); break;
        case '\r': w('\\').w('r'); break;
        case '\f': w('\\').w('f'); break;
        case '\t': w('\\').w('t'); break;
        case '\\': w('\\').w('\\'); break;
        case '"':  if (quote == '"') w('\\').w('"'); else w(c); break;
        case '`':  if (quote == '`') w('\\').w('`'); else w(c); break;
        case '$':  w('\\').w('$'); break;
        default:   w(c);
      }
    }
    return w(quote);
  }

  public final ObjEncoder wIndent()
  {
    int num = level*indent;
    for (int i=0; i<num; ++i) w(' ');
    return this;
  }

  public final ObjEncoder w(String s)
  {
    int len = s.length();
    for (int i=0; i<len; ++i)
      out.writeChar(s.charAt(i));
    return this;
  }

  public final ObjEncoder w(char ch)
  {
    out.writeChar(ch);
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Options
//////////////////////////////////////////////////////////////////////////

  private void initOptions(Map options)
  {
    indent = option(options, "indent", indent);
    skipDefaults = option(options, "skipDefaults", skipDefaults);
    skipErrors = option(options, "skipErrors", skipErrors);
  }

  private static int option(Map options, String name, int def)
  {
    Long val = (Long)options.get(name);
    if (val == null) return def;
    return val.intValue();
  }

  private static boolean option(Map options, String name, boolean def)
  {
    Boolean val = (Boolean)options.get(name);
    if (val == null) return def;
    return val;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream out;
  int level  = 0;
  int indent = 0;
  boolean skipDefaults = false;
  boolean skipErrors = false;
  Type curFieldType;

}