//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jun 10  Andy Frank  Creation
//

/**
 * ObjEncoder serializes an object to an output stream.
 */
function fanx_ObjEncoder(out, options)
{
  this.out    = out;
  this.level  = 0;
  this.indent = 0;
  this.skipDefaults = false;
  this.skipErrors   = false;
  this.curFieldType = null;
  if (options != null) this.initOptions(options);
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fanx_ObjEncoder.encode = function(obj)
{
  var buf = fan.sys.StrBuf.make();
  var out = new fan.sys.StrBufOutStream(buf);
  new fanx_ObjEncoder(out, null).writeObj(obj);
  return buf.toStr();
}

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

fanx_ObjEncoder.prototype.writeObj = function(obj)
{
  if (obj == null)
  {
    this.w("null");
    return;
  }

  var t = typeof obj;
  if (t === "boolean") { this.w(obj.toString()); return; }
  if (t === "number")  { this.w(obj.toString()); return; }
  if (t === "string")  { this.wStrLiteral(obj.toString(), '"'); return; }

  var f = obj.$fanType;
  if (f === fan.sys.Float.$type)   { fan.sys.Float.encode(obj, this); return; }
//  if (f === fan.sys.Decimal.$type) { FanDecimal.encode((BigDecimal)obj, this); return; }

  if (obj.$literalEncode)
  {
    obj.$literalEncode(this);
    return;
  }

fan.sys.ObjUtil.echo(">>>> ObjEncoder.writeObj Serializable not implemented!");

  var type = fan.sys.ObjUtil.$typeof(obj);
  var ser = null;//type.facet(fan.sys.Serializable.$type, false);
  if (ser != null)
  {
  //  if (ser.simple)
  //    writeSimple(type, obj);
  //  else
  //    writeComplex(type, obj, ser);
  }
  else
  {
    if (this.skipErrors)
      this.w("null /* Not serializable: ").w(type.qname()).w(" */");
    else
      throw fan.sys.IOErr.make("Not serializable: " + type);
  }
}

//////////////////////////////////////////////////////////////////////////
// Simple
//////////////////////////////////////////////////////////////////////////

fanx_ObjEncoder.prototype.writeSimple = function(type, obj)
{
  var str = fan.sys.ObjUtil.toStr(obj);
  this.wType(type).w('(').wStrLiteral(str, '"').w(')');
}

//////////////////////////////////////////////////////////////////////////
// Complex
//////////////////////////////////////////////////////////////////////////

/*
private void writeComplex(Type type, Object obj, Serializable ser)
{
  wType(type);

  boolean first = true;
  Object defObj = null;
  if (skipDefaults) defObj = FanObj.typeof(obj).make();

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
  if (m == null) throw IOErr.make("Missing " + type.qname() + ".each").val;

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
  if (list.typeof() == curFieldType)
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
  if (t.equals(curFieldType))
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
*/

//////////////////////////////////////////////////////////////////////////
// Output
//////////////////////////////////////////////////////////////////////////

fanx_ObjEncoder.prototype.wType = function(t)
{
  return this.w(t.signature());
}

fanx_ObjEncoder.prototype.wStrLiteral = function(s, quote)
{
  var len = s.length;
  this.w(quote);
  // NOTE: these escape sequences are duplicated in FanStr.toCode()
  for (var i=0; i<len; ++i)
  {
    var c = s.charAt(i);
    switch (c)
    {
      case '\n': this.w('\\').w('n'); break;
      case '\r': this.w('\\').w('r'); break;
      case '\f': this.w('\\').w('f'); break;
      case '\t': this.w('\\').w('t'); break;
      case '\\': this.w('\\').w('\\'); break;
      case '"':  if (quote == '"') this.w('\\').w('"'); else this.w(c); break;
      case '`':  if (quote == '`') this.w('\\').w('`'); else this.w(c); break;
      case '$':  this.w('\\').w('$'); break;
      default:   this.w(c);
    }
  }
  return this.w(quote);
}

fanx_ObjEncoder.prototype.wIndent = function()
{
  var num = level*indent;
  for (var i=0; i<num; ++i) this.w(' ');
  return this;
}

fanx_ObjEncoder.prototype.w = function(s)
{
  var len = s.length;
  for (var i=0; i<len; ++i)
    this.out.writeChar(s.charCodeAt(i));
  return this;
}

//////////////////////////////////////////////////////////////////////////
// Options
//////////////////////////////////////////////////////////////////////////

fanx_ObjEncoder.prototype.initOptions = function(options)
{
  this.indent = fanx_ObjEncoder.option(options, "indent", this.indent);
  this.skipDefaults = fanx_ObjEncoder.option(options, "skipDefaults", this.skipDefaults);
  this.skipErrors = fanx_ObjEncoder.option(options, "skipErrors", this.skipErrors);
}

fanx_ObjEncoder.option = function(options, name, def)
{
  var val = options.get(name);
  if (val == null) return def;
  return val;
}