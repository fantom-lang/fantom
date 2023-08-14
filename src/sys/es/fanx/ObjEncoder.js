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
  var buf = StrBuf.make();
  var out = new StrBufOutStream(buf);
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

  var f = obj.fanType$;
  if (f === Float.type$)   { Float.encode(obj, this); return; }
  if (f === Decimal.type$) { Decimal.encode(obj, this); return; }

  if (obj.literalEncode$)
  {
    obj.literalEncode$(this);
    return;
  }
  var type = ObjUtil.typeof$(obj);
  var ser = type.facet(Serializable.type$, false);
  if (ser != null)
  {
    if (ser.simple())
      this.writeSimple(type, obj);
    else
      this.writeComplex(type, obj, ser);
  }
  else
  {
    if (this.skipErrors) // NOTE: /* not playing nice in str - escape as unicode char
      this.w("null /\u002A Not serializable: ").w(type.qname()).w(" */");
    else
      throw IOErr.make("Not serializable: " + type);
  }
}

//////////////////////////////////////////////////////////////////////////
// Simple
//////////////////////////////////////////////////////////////////////////

fanx_ObjEncoder.prototype.writeSimple = function(type, obj)
{
  var str = ObjUtil.toStr(obj);
  this.wType(type).w('(').wStrLiteral(str, '"').w(')');
}

//////////////////////////////////////////////////////////////////////////
// Complex
//////////////////////////////////////////////////////////////////////////

fanx_ObjEncoder.prototype.writeComplex = function(type, obj, ser)
{
  this.wType(type);

  var first = true;
  var defObj = null;
  if (this.skipDefaults)
  {
    // attempt to instantiate default object for type,
    // this will fail if complex has it-block ctor
    try { defObj = ObjUtil.typeof$(obj).make(); } catch(e) {}
  }

  var fields = type.fields();
  for (var i=0; i<fields.size(); ++i)
  {
    var f = fields.get(i);

    // skip static, transient, and synthetic (once) fields
    if (f.isStatic() || f.isSynthetic() || f.hasFacet(Transient.type$))
      continue;

    // get the value
    var val = f.get(obj);

    // if skipping defaults
    if (defObj != null)
    {
      var defVal = f.get(defObj);
      if (ObjUtil.equals(val, defVal)) continue;
    }

    // if first then open braces
    if (first) { this.w('\n').wIndent().w('{').w('\n'); this.level++; first = false; }

    // field name =
    this.wIndent().w(f.name()).w('=');

    // field value
    this.curFieldType = f.type().toNonNullable();
    this.writeObj(val);
    this.curFieldType = null;

    this.w('\n');
  }

  // if collection
  if (ser.collection())
    first = this.writeCollectionItems(type, obj, first);

  // if we output fields, then close braces
  if (!first) { this.level--; this.wIndent().w('}'); }
}

//////////////////////////////////////////////////////////////////////////
// Collection (@collection)
//////////////////////////////////////////////////////////////////////////

fanx_ObjEncoder.prototype.writeCollectionItems = function(type, obj, first)
{
  // lookup each method
  var m = type.method("each", false);
  if (m == null) throw IOErr.make("Missing " + type.qname() + ".each");

  // call each(it)
  var enc = this;
  /*
  var it  = Func.make(
    List.make(Param.type$),
    Void.type$,
    function(obj)
    {
      if (first) { enc.w('\n').wIndent().w('{').w('\n'); enc.level++; first = false; }
      enc.wIndent();
      enc.writeObj(obj);
      enc.w(',').w('\n');
      return null;
    });
    */

  const it = (obj) => {
    if (first) { enc.w('\n').wIndent().w('{').w('\n'); enc.level++; first = false; }
    enc.wIndent();
    enc.writeObj(obj);
    enc.w(',').w('\n');
    return null;
  }

  m.invoke(obj, List.make(Obj.type$, [it]));
  return first;
}

//////////////////////////////////////////////////////////////////////////
// List
//////////////////////////////////////////////////////////////////////////

fanx_ObjEncoder.prototype.writeList = function(list)
{
  // get of type
  var of = list.of();

  // decide if we're going output as single or multi-line format
  var nl = this.isMultiLine(of);

  // figure out if we can use an inferred type
  var inferred = false;
  if (this.curFieldType != null && (this.curFieldType instanceof ListType))
  {
    inferred = true;
  }

  // clear field type, so it doesn't get used for inference again
  this.curFieldType = null;

  // if we don't have an inferred type, then prefix of type
  if (!inferred) this.wType(of);

  // handle empty list
  var size = list.size();
  if (size == 0) { this.w("[,]"); return; }

  // items
  if (nl) this.w('\n').wIndent();
  this.w('[');
  this.level++;
  for (var i=0; i<size; ++i)
  {
    if (i > 0) this.w(',');
     if (nl) this.w('\n').wIndent();
    this.writeObj(list.get(i));
  }
  this.level--;
  if (nl) this.w('\n').wIndent();
  this.w(']');
}

//////////////////////////////////////////////////////////////////////////
// Map
//////////////////////////////////////////////////////////////////////////

fanx_ObjEncoder.prototype.writeMap = function(map)
{
  // get k,v type
  var t = map.typeof$();

  // decide if we're going output as single or multi-line format
  var nl = this.isMultiLine(t.k) || this.isMultiLine(t.v);

  // figure out if we can use an inferred type
  var inferred = false;
  if (this.curFieldType != null && (this.curFieldType instanceof MapType))
  {
    inferred = true;
  }

  // clear field type, so it doesn't get used for inference again
  this.curFieldType = null;

  // if we don't have an inferred type, then prefix of type
  if (!inferred) this.wType(t);

  // handle empty map
  if (map.isEmpty()) { this.w("[:]"); return; }

  // items
  this.level++;
  this.w('[');
  var first = true;
  var keys = map.keys();
  for (var i=0; i<keys.size(); i++)
  {
    if (first) first = false; else this.w(',');
    if (nl) this.w('\n').wIndent();
    var key = keys.get(i);
    var val = map.get(key);
    this.writeObj(key); this.w(':'); this.writeObj(val);
  }
  this.w(']');
  this.level--;
}

fanx_ObjEncoder.prototype.isMultiLine = function(t)
{
  return t.pod() != Pod.sysPod$;
}

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
  var num = this.level * this.indent;
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