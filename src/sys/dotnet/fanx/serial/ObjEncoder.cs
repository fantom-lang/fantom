//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Sep 07  Andy Frank  Creation
//

using System.Collections;
using Fan.Sys;
using Fanx.Util;

namespace Fanx.Serial
{
  /// <summary>
  /// ObjEncoder serializes an object to an output stream.
  /// </summary>
  public class ObjEncoder
  {

  //////////////////////////////////////////////////////////////////////////
  // Static
  //////////////////////////////////////////////////////////////////////////

    public static string encode(object obj)
    {
      StrBufOutStream @out = new StrBufOutStream();
      new ObjEncoder(@out, null).writeObj(obj);
      return @out.@string();
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public ObjEncoder(OutStream @out, Map options)
    {
      this.@out = @out;
      if (options != null) initOptions(options);
    }

  //////////////////////////////////////////////////////////////////////////
  // Write
  //////////////////////////////////////////////////////////////////////////

    public void writeObj(object obj)
    {
      if (obj == null)
      {
        w("null");
        return;
      }

      if (obj.GetType().FullName[0] == 'S')
      {
        if (obj is bool && (bool)obj)  { w("true");  return; }
        if (obj is bool && !(bool)obj) { w("false"); return; }
        if (obj is double) { FanFloat.encode((double)obj, this); return; }
        if (obj is long)   { FanInt.encode((long)obj, this); return; }
        if (obj is string) { wStrLiteral(obj.ToString(), '"'); return; }
      }

      if (obj.GetType().FullName[0] == 'F')
      {
        if (obj is Boolean && (obj as Boolean).booleanValue())  { w("true"); return; }
        if (obj is Boolean && !(obj as Boolean).booleanValue()) { w("false"); return; }
        if (obj is Double) { FanFloat.encode((obj as Double).doubleValue(), this); return; }
        if (obj is Long)   { FanInt.encode((obj as Long).longValue(), this); return; }
        if (obj is BigDecimal) { FanDecimal.encode((BigDecimal)obj, this); return; }
      }

      if (obj is Literal)
      {
        ((Literal)obj).encode(this);
        return;
      }

      Type type = FanObj.@typeof(obj);
      Serializable ser = (Serializable)type.facet(Sys.SerializableType, false);
      if (ser != null)
      {
        if (ser.m_simple)
          writeSimple(type, obj);
        else
          writeComplex(type, obj, ser);
      }
      else
      {
        if (skipErrors)
          w("null /* Not serializable: ").w(type.qname()).w(" */");
        else
          throw IOErr.make("Not serializable: " + type).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Simple
  //////////////////////////////////////////////////////////////////////////

    private void writeSimple(Type type, object obj)
    {
      wType(type).w('(').wStrLiteral(FanObj.toStr(obj), '"').w(')');
    }

  //////////////////////////////////////////////////////////////////////////
  // Complex
  //////////////////////////////////////////////////////////////////////////

    private void writeComplex(Type type, object obj, Serializable ser)
    {
      wType(type);

      bool first = true;
      object defObj = null;
      if (skipDefaults) defObj = FanObj.@typeof(obj).make();

      List fields = type.fields();
      for (int i=0; i<fields.sz(); ++i)
      {
        Field f = (Field)fields.get(i);

        // skip static, transient, and synthetic (once) fields
        if (f.isStatic() || f.isSynthetic() || f.hasFacet(Sys.TransientType))
          continue;

        // get the value
        object val = f.get(obj);

        // if skipping defaults
        if (defObj != null)
        {
          object defVal = f.get(defObj);
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
      if (ser.m_collection)
        first = writeCollectionItems(type, obj, first);

      // if we output fields, then close braces
      if (!first) { level--; wIndent().w('}'); }
    }

  //////////////////////////////////////////////////////////////////////////
  // Collection (@collection)
  //////////////////////////////////////////////////////////////////////////

    private bool writeCollectionItems(Type type, object obj, bool first)
    {
      // lookup each method
      Method m = type.method("each", false);
      if (m == null) throw IOErr.make("Missing " + type.qname() + ".each").val;

      // call each(it)
      EachIterator it = new EachIterator(this, first);
      m.invoke(obj, new object[] { it });
      return it.first;
    }

    static FuncType eachIteratorType = new FuncType(new Type[] { Sys.ObjType }, Sys.VoidType);

    internal class EachIterator : Func.Indirect1
    {
      internal EachIterator(ObjEncoder encoder, bool first)
        : base(eachIteratorType)
      {
        this.encoder = encoder;
        this.first = first;
      }
      public override object call(object obj)
      {
        if (first) { encoder.w('\n').wIndent().w('{').w('\n'); encoder.level++; first = false; }
        encoder.wIndent();
        encoder.writeObj(obj);
        encoder.w(',').w('\n');
        return null;
      }
      private ObjEncoder encoder;
      internal bool first;
    }

  //////////////////////////////////////////////////////////////////////////
  // List
  //////////////////////////////////////////////////////////////////////////

    public void writeList(List list)
    {
      // get of type
      Type of = list.of();

      // decide if we're going output as single or multi-line format
      bool nl = isMultiLine(of);

      // figure out if we can use an inferred type
      bool inferred = false;
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
      MapType t = (MapType)map.@typeof();

      // decide if we're going output as single or multi-line format
      bool nl = isMultiLine(t.m_k) || isMultiLine(t.m_v);

      // figure out if we can use an inferred type
      bool inferred = false;
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
      bool first = true;
      IDictionaryEnumerator en = map.pairsIterator();
      while (en.MoveNext())
      {
        if (first) first = false; else w(',');
        if (nl) w('\n').wIndent();
        object key = en.Key;
        object val = en.Value;
        writeObj(key); w(':'); writeObj(val);
      }
      w(']');
      level--;
    }

    private bool isMultiLine(Type t)
    {
      return t.pod() != Sys.m_sysPod;
    }

  //////////////////////////////////////////////////////////////////////////
  // Output
  //////////////////////////////////////////////////////////////////////////

    public ObjEncoder wType(Type t)
    {
      return w(t.signature());
    }

    public ObjEncoder wStrLiteral(string s, char quote)
    {
      int len = s.Length;
      w(quote);
      // NOTE: these escape sequences are duplicated in FanStr.toCode()
      for (int i=0; i<len; ++i)
      {
        char c = s[i];
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
          default:   w(c); break;
        }
      }
      return w(quote);
    }

    public ObjEncoder wIndent()
    {
      int num = level*indent;
      for (int i=0; i<num; ++i) w(' ');
      return this;
    }

    public ObjEncoder w(string s)
    {
      int len = s.Length;
      for (int i=0; i<len; ++i)
        @out.writeChar(s[i]);
      return this;
    }

    public ObjEncoder w(char ch)
    {
      @out.writeChar(ch);
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

    private static int option(Map options, string name, int def)
    {
      Long val = (Long)options.get(name);
      if (val == null) return def;
      return val.intValue();
    }

    private static bool option(Map options, string name, bool def)
    {
      Boolean val = (Boolean)options.get(name);
      if (val == null) return def;
      return val.booleanValue();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    OutStream @out;
    int level  = 0;
    int indent = 0;
    bool skipDefaults = false;
    bool skipErrors = false;
    Type curFieldType;

  }
}