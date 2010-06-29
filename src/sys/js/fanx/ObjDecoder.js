//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 May 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * ObjDecoder parses an object tree from an input stream.
 */
function fanx_ObjDecoder(input, options)
{
  this.tokenizer = new fanx_Tokenizer(input);
  this.options = options;
  this.curt = null;
  this.usings = [];
  this.numUsings = 0;
  this.consume();

  fanx_ObjDecoder.defaultMapType =
    new fan.sys.MapType(fan.sys.Obj.$type, fan.sys.Obj.$type);
}

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

/**
 * Read an object from the stream.
 */
fanx_ObjDecoder.prototype.readObj = function()
{
  this.readHeader();
  return this.$readObj(null, null, true);
}

/**
 * header := [using]*
 */
fanx_ObjDecoder.prototype.readHeader = function()
{
  while (this.curt == fanx_Token.USING)
    this.usings[this.numUsings++] = this.readUsing();
}

/**
 * using     := usingPod | usingType | usingAs
 * usingPod  := "using" podName
 * usingType := "using" podName::typeName
 * usingAs   := "using" podName::typeName "as" name
 */
fanx_ObjDecoder.prototype.readUsing = function()
{
  var line = this.tokenizer.line;
  this.consume();

  var podName = this.consumeId("Expecting pod name");
  var pod = fan.sys.Pod.find(podName, false);
  if (pod == null) throw this.err("Unknown pod: " + podName);
  if (this.curt != fanx_Token.DOUBLE_COLON)
  {
    this.endOfStmt(line);
    return new fanx_UsingPod(pod);
  }

  this.consume();
  var typeName = this.consumeId("Expecting type name");
  var t = pod.findType(typeName, false);
  if (t == null) throw this.err("Unknown type: " + podName + "::" + typeName);

  if (this.curt == fanx_Token.AS)
  {
    this.consume();
    typeName = consumeId("Expecting using as name");
  }

  this.endOfStmt(line);
  return new UsingType(t, typeName);
}

/**
 * obj := literal | simple | complex
 */
fanx_ObjDecoder.prototype.$readObj = function(curField, peekType, root)
{
  // literals are stand alone
  if (fanx_Token.isLiteral(this.curt))
  {
    var val = this.tokenizer.val;
    this.consume();
    return val;
  }

  // [ is always list/map collection
  if (this.curt == fanx_Token.LBRACKET)
    return this.readCollection(curField, peekType);

  // at this point all remaining options must start
  // with a type signature - if peekType is non-null
  // then we've already read the type signature
  var line = this.tokenizer.line;
  var t = (peekType != null) ? peekType : this.readType();

  // type:     type#
  // simple:   type(
  // list/map: type[
  // complex:  type || type{
  if (this.curt == fanx_Token.LPAREN)
    return this.readSimple(line, t);
  else if (this.curt == fanx_Token.POUND)
    return this.readTypeLiteral(line, t);
  else if (this.curt == fanx_Token.LBRACKET)
    return this.readCollection(curField, t);
  else
    return this.readComplex(line, t, root);
}

/**
 * typeLiteral := type "#"
 */
fanx_ObjDecoder.prototype.readTypeLiteral = function(line, t)
{
  this.consume(fanx_Token.POUND, "Expected '#' for type literal");
  return t;
}

/**
 * simple := type "(" str ")"
 */
fanx_ObjDecoder.prototype.readSimple = function(line, t)
{
  // parse: type(str)
  this.consume(fanx_Token.LPAREN, "Expected ( in simple");
  var str = this.consumeStr("Expected string literal for simple");
  this.consume(fanx_Token.RPAREN, "Expected ) in simple");

// TEMP
//var script = t.qname().replace("::","_") + ".fromStr('" + str + "')";
var script = "fan." + t.pod().name() + "." + t.name() + ".fromStr('" + str + "')";
return eval(script);

  // lookup the fromString method
// TODO
//    t.finish();
//    Method m = t.method("fromStr", false);
//    if (m == null)
//      throw err("Missing method: " + t.qname() + ".fromStr", line);
//
//    // invoke parse method to translate into instance
//    try
//    {
//      return m.invoke(null, new Object[] { str });
//    }
//    catch (ParseErr.Val e)
//    {
//      throw ParseErr.make(e.err().msg() + " [Line " + line + "]").val;
//    }
//    catch (Throwable e)
//    {
//      throw ParseErr.make(e.toString() + " [Line " + line + "]", e).val;
//    }
}

/**
 * complex := type [fields]
 * fields  := "{" field (eos field)* "}"
 * field   := name "=" obj
 */
fanx_ObjDecoder.prototype.readComplex = function(line, t, root)
{
  // make instance
  var obj = null;
  try
  {
    var args = null;
    if (root && this.options != null)
      args = this.options.get("makeArgs");
    obj = t.make(args);
  }
  catch (e)
  {
    throw fan.sys.IOErr.make("Cannot make " + t + ": " + e + " [Line " + line + "]", e);
  }

  // check for braces
  if (this.curt != fanx_Token.LBRACE) return obj;
  this.consume();

  // fields and/or collection items
  while (this.curt != fanx_Token.RBRACE)
  {
    // try to read "id =" to see if we have a field
    line = this.tokenizer.line;
    var readField = false;
    if (this.curt == fanx_Token.ID)
    {
      var name = this.consumeId("Expected field name");
      if (this.curt == fanx_Token.EQ)
      {
        // we have "id =" so read field
        this.consume();
        this.readComplexField(t, obj, line, name);
        readField = true;
      }
      else
      {
        // pushback to reset on start of collection item
        this.tokenizer.undo(this.tokenizer.type, this.tokenizer.val, this.tokenizer.line);
        this.curt = this.tokenizer.reset(fanx_Token.ID, name, line);
      }
    }

    // if we didn't read a field, we assume a collection item
    if (!readField) this.readComplexAdd(t, obj, line);

    if (this.curt == fanx_Token.COMMA) this.consume();
    else this.endOfStmt(line);
  }
  this.consume(fanx_Token.RBRACE, "Expected '}'");

  return obj;
}

fanx_ObjDecoder.prototype.readComplexAdd = function(t, obj, line)
{
  var val = this.$readObj(null, null, false);
  var m = t.method("add", false);
  if (m == null) throw this.err("Method not found: " + t.qname() + ".add", line);
  try
  {
    m.invoke(obj, [val]);
  }
  catch (err)
  {
    throw fan.sys.IOErr.make("Cannot call " + t.qname() + ".add: " + err + " [Line " + line + "]", err);
  }
}

fanx_ObjDecoder.prototype.readComplexField = function(t, obj, line, name)
{
  // resolve field
  var field = t.field(name, false);
  if (field == null) throw this.err("Field not found: " + t.qname() + "." + name, line);

  // parse value
  var val = this.$readObj(field, null, false);

  // set field value (skip const check)
  try
  {
    if (field.isConst())
      field.set(obj, OpUtil.toImmutable(val), false);
    else
      field.set(obj, val);
  }
  catch (err)
  {
    throw fan.sys.IOErr.make("Cannot set field " + t.qname() + "." + name + ": " + err + " [Line " + line + "]", err);
  }
}

//////////////////////////////////////////////////////////////////////////
// Collection
//////////////////////////////////////////////////////////////////////////

/**
 * collection := list | map
 */
fanx_ObjDecoder.prototype.readCollection = function(curField, t)
{
  // opening [
  this.consume(fanx_Token.LBRACKET, "Expecting '['");

  // if this could be a map type signature:
  //    [qname:qname]
  //    [qname:qname][]
  //    [qname:qname][][] ...
  // or it could just be the type signature of
  // of a embedded simple, complex, or list
  var peekType = null;
  if (this.curt == fanx_Token.ID && t == null)
  {
    // peek at the type
    peekType = this.readType();

    // if we have [mapType] then this is non-inferred type signature
    if (this.curt == fanx_Token.RBRACKET && peekType instanceof fan.sys.MapType)
    {
      t = peekType; peekType = null;
      this.consume();
      while (this.curt == fanx_Token.LRBRACKET) { this.consume(); t = t.toListOf(); }
      this.consume(fanx_Token.LBRACKET, "Expecting '['");
    }
  }

  // handle special case of [,]
  if (this.curt == fanx_Token.COMMA && peekType == null)
  {
    this.consume();
    this.consume(fanx_Token.RBRACKET, "Expecting ']'");
    return fan.sys.List.make(this.toListOfType(t, curField, false), []);
  }

  // handle special case of [:]
  if (this.curt == fanx_Token.COLON && peekType == null)
  {
    this.consume();
    this.consume(fanx_Token.RBRACKET, "Expecting ']'");
    return fan.sys.Map.make(this.toMapType(t, curField, false));
  }

  // read first list item or first map key
  var first = this.$readObj(null, peekType, false);

  // now we can distinguish b/w list and map
  if (this.curt == fanx_Token.COLON)
    return this.readMap(this.toMapType(t, curField, true), first);
  else
    return this.readList(this.toListOfType(t, curField, true), first);
}

/**
 * list := "[" obj ("," obj)* "]"
 */
fanx_ObjDecoder.prototype.readList = function(of, first)
{
  // setup accumulator
  var acc = [];
  acc.push(first)

  // parse list items
  while (this.curt != fanx_Token.RBRACKET)
  {
    this.consume(fanx_Token.COMMA, "Expected ','");
    if (this.curt == fanx_Token.RBRACKET) break;
    acc.push(this.$readObj(null, null, false));
  }
  this.consume(fanx_Token.RBRACKET, "Expected ']'");

  // infer type if needed
  if (of == null) of = fan.sys.Type.common(acc);

  return fan.sys.List.make(of, acc);
}

/**
 * map     := "[" mapPair ("," mapPair)* "]"
 * mapPair := obj ":" + obj
 */
// TODO
/*
readMap = function(mapType, firstKey)
{
  // setup accumulator
  HashMap map = new HashMap();

  // finish first pair
  consume(fanx_Token.COLON, "Expected ':'");
  map.put(firstKey, this.$readObj(null, null, false));

  // parse map pairs
  while (curt != fanx_Token.RBRACKET)
  {
    consume(fanx_Token.COMMA, "Expected ','");
    if (curt == fanx_Token.RBRACKET) break;
    Object key = this.$readObj(null, null, false);
    consume(fanx_Token.COLON, "Expected ':'");
    Object val = this.$readObj(null, null, false);
    map.put(key, val);
  }
  consume(fanx_Token.RBRACKET, "Expected ']'");

  // infer type if necessary
  if (mapType == null)
  {
    int size = map.size();
    Type k = Type.common(map.keySet().toArray(new Object[size]), size);
    Type v = Type.common(map.values().toArray(new Object[size]), size);
    mapType = new fan.sys.MapType(k, v);
  }

  return fan.sys.Map.make((fan.sys.MapType)mapType, map);
},
*/

/**
 * Figure out the type of the list:
 *   1) if t was explicit then use it
 *   2) if we have field typed as a list, then use its definition
 *   3) if inferred is false, then drop back to list of Obj
 *   4) If inferred is true then return null and we'll infer the common type
 */
fanx_ObjDecoder.prototype.toListOfType = function(t, curField, infer)
{
  if (t != null) return t;
  if (curField != null)
  {
    var ft = curField.type().toNonNullable();
    if (ft instanceof fan.sys.ListType) return ft.v;
  }
  if (infer) return null;
  return fan.sys.Obj.$type.toNullable(); //Sys.ObjType.toNullable();
}

/**
 * Figure out the map type:
 *   1) if t was explicit then use it (check that it was a map type)
 *   2) if we have field typed as a map , then use its definition
 *   3) if inferred is false, then drop back to Obj:Obj
 *   4) If inferred is true then return null and we'll infer the common key/val types
 */
fanx_ObjDecoder.prototype.toMapType = function(t, curField, infer)
{
  if (t instanceof fan.sys.MapType)
    return t;

  if (curField != null)
  {
    var ft = curField.type().toNonNullable();
    if (ft instanceof fan.sys.MapType) return ft;
  }

  if (infer) return null;
  return fanx_ObjDecoder.defaultMapType;
}

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

/**
 * type    := listSig | mapSig1 | mapSig2 | qname
 * listSig := type "[]"
 * mapSig1 := type ":" type
 * mapSig2 := "[" type ":" type "]"
 *
 * Note: the mapSig2 with brackets is handled by the
 * method succinctly named readMapTypeOrCollection().
 */
fanx_ObjDecoder.prototype.readType = function(lbracket)
{
  if (lbracket === undefined) lbracket = false;
  var t = this.readSimpleType();
  if (this.curt == fanx_Token.QUESTION)
  {
    this.consume();
    t = t.toNullable();
  }
  if (this.curt == fanx_Token.COLON)
  {
    this.consume();
    t = new fan.sys.MapType(t, this.readType());
  }
  while (this.curt == fanx_Token.LRBRACKET)
  {
    this.consume();
    t = t.toListOf();
  }
  if (this.curt == fanx_Token.QUESTION)
  {
    this.consume();
    t = t.toNullable();
  }
  return t;
}

/**
 * qname := [podName "::"] typeName
 */
fanx_ObjDecoder.prototype.readSimpleType = function()
{
  // parse identifier
  var line = this.tokenizer.line;
  var n = this.consumeId("Expected type signature");

  // check for using imported name
  if (this.curt != fanx_Token.DOUBLE_COLON)
  {
    for (var i=0; i<this.numUsings; ++i)
    {
      var t = this.usings[i].resolve(n);
      if (t != null) return t;
    }
    throw this.err("Unresolved type name: " + n);
  }

  // must be fully qualified
  this.consume(fanx_Token.DOUBLE_COLON, "Expected ::");
  var typeName = this.consumeId("Expected type name");

  // resolve pod
  var pod = fan.sys.Pod.find(n, false);
  if (pod == null) throw this.err("Pod not found: " + n, line);

  // resolve type
  var type = pod.findType(typeName, false);
  if (type == null) throw fanx_ObjDecoder.err("Type not found: " + n + "::" + typeName, line);
  return type;
}

//////////////////////////////////////////////////////////////////////////
// Error Handling
//////////////////////////////////////////////////////////////////////////

/**
 * Create exception based on tokenizers current line.
 */
fanx_ObjDecoder.prototype.err = function(msg)
{
  return fanx_ObjDecoder.err(msg, this.tokenizer.line);
}

//////////////////////////////////////////////////////////////////////////
// Tokens
//////////////////////////////////////////////////////////////////////////

/**
 * Consume the current token as a identifier.
 */
fanx_ObjDecoder.prototype.consumeId = function(expected)
{
  this.verify(fanx_Token.ID, expected);
  var id = this.tokenizer.val;
  this.consume();
  return id;
}

/**
 * Consume the current token as a String literal.
 */
fanx_ObjDecoder.prototype.consumeStr = function(expected)
{
  this.verify(fanx_Token.STR_LITERAL, expected);
  var id = this.tokenizer.val;
  this.consume();
  return id;
}

/**
 * Check that the current token matches the
 * specified type, and then consume it.
 */
fanx_ObjDecoder.prototype.consume = function(type, expected)
{
  if (type != undefined)
    this.verify(type, expected);
  this.curt = this.tokenizer.next();
}

/**
 * Check that the current token matches the specified
 * type, but do not consume it.
 */
fanx_ObjDecoder.prototype.verify = function(type, expected)
{
  if (this.curt != type)
    throw this.err(expected + ", not '" + fanx_Token.toString(this.curt) + "'");
}

/**
 * Statements can be terminated with a semicolon, end of line or } end of block.
 */
fanx_ObjDecoder.prototype.endOfStmt = function(lastLine)
{
  if (this.curt == fanx_Token.SEMICOLON) { this.consume(); return; }
  if (lastLine < this.tokenizer.line) return;
  if (this.curt == fanx_Token.RBRACE) return;
  throw this.err("Expected end of statement: semicolon, newline, or end of block; not '" + fanx_Token.toString(this.curt) + "'");
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fanx_ObjDecoder.decode = function(s)
{
  return new fanx_ObjDecoder(fan.sys.InStream.makeForStr(s), null).readObj();
}

fanx_ObjDecoder.err = function(msg, line)
{
  return fan.sys.IOErr.make(msg + " [Line " + line + "]");
}

fanx_ObjDecoder.defaultMapType = null;

//////////////////////////////////////////////////////////////////////////
// Using
//////////////////////////////////////////////////////////////////////////

function fanx_UsingPod(p) { this.pod = p; }
fanx_UsingPod.prototype.resolve = function(n)
{
  return this.pod.findType(n, false);
}

function fanx_UsingType(t,n) { this.type = t; this.name = n; }
fanx_UsingType.prototype.resolve = function(n)
{
  return this.name.equals(n) ? this.type : null;
}

