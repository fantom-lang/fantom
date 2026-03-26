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
  var pod = Pod.find(podName, false);
  if (pod == null) throw this.err("Unknown pod: " + podName);
  if (this.curt != fanx_Token.DOUBLE_COLON)
  {
    this.endOfStmt(line);
    return new fanx_UsingPod(pod);
  }

  this.consume();
  var typeName = this.consumeId("Expecting type name");
  var t = pod.type(typeName, false);
  if (t == null) throw this.err("Unknown type: " + podName + "::" + typeName);

  if (this.curt == fanx_Token.AS)
  {
    this.consume();
    typeName = this.consumeId("Expecting using as name");
  }

  this.endOfStmt(line);
  return new fanx_UsingType(t, typeName);
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
    return this.readTypeOrSlotLiteral(line, t);
  else if (this.curt == fanx_Token.LBRACKET)
    return this.readCollection(curField, t);
  else
    return this.readComplex(line, t, root);
}

/**
 * typeLiteral := type "#"
 * slotLiteral := type "#" id
 */
fanx_ObjDecoder.prototype.readTypeOrSlotLiteral = function(line, t)
{
  this.consume(fanx_Token.POUND, "Expected '#' for type literal");
  if (this.curt == fanx_Token.ID && !this.isEndOfStmt(line))
  {
    var slotName = this.consumeId("slot literal name");
    return t.slot(slotName);
  }
  else
  {
    return t;
  }
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

  try
  {
    const val = t.method("fromStr").invoke(null, [str]);
    return val;
  }
  catch (e)
  {
    throw ParseErr.make(e.toString() + " [Line " + this.line + "]", e);
  }

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

//////////////////////////////////////////////////////////////////////////
// Complex
//////////////////////////////////////////////////////////////////////////

/**
 * complex := type [fields]
 * fields  := "{" field (eos field)* "}"
 * field   := name "=" obj
 */
fanx_ObjDecoder.prototype.readComplex = function(line, t, root)
{
  var toSet = Map.make(Field.type$, Obj.type$.toNullable());
  var toAdd = List.make(Obj.type$.toNullable());

  // read fields/collection into toSet/toAdd
  this.readComplexFields(t, toSet, toAdd);

  // get the make constructor
  var makeCtor = t.method("make", false);
  if (makeCtor == null || !makeCtor.isPublic())
    throw this.err("Missing public constructor " + t.qname() + ".make", line);

  // get argument lists
  var args = null;
  if (root && this.options != null && this.options.get("makeArgs") != null)
    args = List.make(Obj.type$).addAll(this.options.get("makeArgs"));

  // construct object
  var obj = null;
  var setAfterCtor = true;
  try
  {
    // if last parameter is an function then pass toSet
    // as an it-block for setting the fields
    var p = makeCtor.params().last();
    if (p != null && p.type().fits(Func.type$))
    {
      if (args == null) args = List.make(Obj.type$);
      args.add(Field.makeSetFunc(toSet));
      setAfterCtor = false;
    }

    // invoke make to construct object
    obj = makeCtor.callList(args);
  }
  catch (e)
  {
    throw this.err("Cannot make " + t + ": " + e, line, e);
  }

  // set fields (if not passed to ctor as it-block)
  if (setAfterCtor && toSet.size() > 0)
  {
    var keys = toSet.keys();
    for (var i=0; i<keys.size(); i++)
    {
      var field = keys.get(i);
      var val = toSet.get(field);
      this.complexSet(obj, field, val, line);
    }
  }

  // add
  if (toAdd.size() > 0)
  {
    var addMethod = t.method("add", false);
    if (addMethod == null) throw this.err("Method not found: " + t.qname() + ".add", line);
    for (var i=0; i<toAdd.size(); ++i)
      this.complexAdd(t, obj, addMethod, toAdd.get(i), line);
  }

  return obj;
}

fanx_ObjDecoder.prototype.readComplexFields = function(t, toSet, toAdd)
{
  if (this.curt != fanx_Token.LBRACE) return;
  this.consume();

  // fields and/or collection items
  while (this.curt != fanx_Token.RBRACE)
  {
    // try to read "id =" to see if we have a field
    var line = this.tokenizer.line;
    var readField = false;
    if (this.curt == fanx_Token.ID)
    {
      var name = this.consumeId("Expected field name");
      if (this.curt == fanx_Token.EQ)
      {
        // we have "id =" so read field
        this.consume();
        this.readComplexSet(t, line, name, toSet);
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
    if (!readField) this.readComplexAdd(t, line, toAdd);

    if (this.curt == fanx_Token.COMMA) this.consume();
    else this.endOfStmt(line);
  }
  this.consume(fanx_Token.RBRACE, "Expected '}'");
}

fanx_ObjDecoder.prototype.readComplexSet = function(t, line, name, toSet)
{
  // resolve field
  var field = t.field(name, false);
  if (field == null) throw this.err("Field not found: " + t.qname() + "." + name, line);

  // parse value
  var val = this.$readObj(field, null, false);

  try
  {
    // if const field, then make val immutable
    if (field.isConst()) val = ObjUtil.toImmutable(val);
  }
  catch (ex)
  {
    throw this.err("Cannot make object const for " + field.qname() + ": " + ex, line, ex);
  }

  // add to map
  toSet.set(field, val);
}

fanx_ObjDecoder.prototype.complexSet = function(obj, field, val, line)
{
  try
  {
    if (field.isConst())
      field.set(obj, ObjUtil.toImmutable(val), false);
    else
      field.set(obj, val);
  }
  catch (ex)
  {
    throw this.err("Cannot set field " + field.qname() + ": " + ex, line, ex);
  }
}

fanx_ObjDecoder.prototype.readComplexAdd = function(t, line, toAdd)
{
  var val = this.$readObj(null, null, false);

  // add to list
  toAdd.add(val);
}

fanx_ObjDecoder.prototype.complexAdd = function(t, obj, addMethod, val, line)
{
  try
  {
    addMethod.invoke(obj, List.make(Obj.type$, [val]));
  }
  catch (ex)
  {
    throw this.err("Cannot call " + t.qname() + ".add: " + ex, line, ex);
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
    if (this.curt == fanx_Token.RBRACKET && peekType instanceof MapType)
    {
      t = peekType; peekType = null;
      this.consume();
      while (this.curt == fanx_Token.LRBRACKET) { this.consume(); t = t.toListOf(); }
      if (this.curt == fanx_Token.QUESTION) { this.consume(); t = t.toNullable(); }
      if (this.curt == fanx_Token.POUND) { this.consume(); return t; }
      this.consume(fanx_Token.LBRACKET, "Expecting '['");
    }

    // if the type was a FFI JavaType, this isn't a collection
//    if (peekType != null && peekType.isJava())
//      return this.$readObj(curField, peekType, false);
  }

  // handle special case of [,]
  if (this.curt == fanx_Token.COMMA && peekType == null)
  {
    this.consume();
    this.consume(fanx_Token.RBRACKET, "Expecting ']'");
    return List.make(this.toListOfType(t, curField, false), []);
  }

  // handle special case of [:]
  if (this.curt == fanx_Token.COLON && peekType == null)
  {
    this.consume();
    this.consume(fanx_Token.RBRACKET, "Expecting ']'");
    return Map.make(this.toMapType(t, curField, false));
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
  if (of == null) of = Type.common$(acc);

  return List.make(of, acc);
}

/**
 * map     := "[" mapPair ("," mapPair)* "]"
 * mapPair := obj ":" + obj
 */
fanx_ObjDecoder.prototype.readMap = function(mapType, firstKey)
{
  // create map
  var map = mapType == null
    ? Map.make(Obj.type$, Obj.type$.toNullable())
    : Map.make(mapType);

  // we don't encode whether the original map was ordered or not,
  // so assume it was to ensure map is still ordered after decode
  map.ordered(true);

  // finish first pair
  this.consume(fanx_Token.COLON, "Expected ':'");
  map.set(firstKey, this.$readObj(null, null, false));

  // parse map pairs
  while (this.curt != fanx_Token.RBRACKET)
  {
    this.consume(fanx_Token.COMMA, "Expected ','");
    if (this.curt == fanx_Token.RBRACKET) break;
    var key = this.$readObj(null, null, false);
    this.consume(fanx_Token.COLON, "Expected ':'");
    var val = this.$readObj(null, null, false);
    map.set(key, val);
  }
  this.consume(fanx_Token.RBRACKET, "Expected ']'");

  // infer type if necessary
  if (mapType == null)
  {
    var size = map.size();
    var k = Type.common$(map.keys().__values());
    var v = Type.common$(map.vals().__values());
    map.__type(new MapType(k, v));
  }

  return map;
}

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
    if (ft instanceof ListType) return ft.v;
  }
  if (infer) return null;
  return Obj.type$.toNullable();
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
  if (t instanceof MapType)
    return t;

  if (curField != null)
  {
    var ft = curField.type().toNonNullable();
    if (ft instanceof MapType) return ft;
  }

  if (infer) return null;

  if (fanx_ObjDecoder.defaultMapType == null)
    fanx_ObjDecoder.defaultMapType =
      new MapType(Obj.type$, Obj.type$.toNullable());
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
    var lbracket2 = this.curt == fanx_Token.LBRACKET;
    if (lbracket2) this.consume();
    t = new MapType(t, this.readType(lbracket2));
    if (lbracket2) this.consume(fanx_Token.RBRACKET, "Expected closeing ']'");
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
  var pod = Pod.find(n, false);
  if (pod == null) throw this.err("Pod not found: " + n, line);

  // resolve type
  var type = pod.type(typeName, false);
  if (type == null) throw this.err("Type not found: " + n + "::" + typeName, line);
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
 * Is current token part of the next statement?
 */
fanx_ObjDecoder.prototype.isEndOfStmt = function(lastLine)
{
  if (this.curt == fanx_Token.EOF) return true;
  if (this.curt == fanx_Token.SEMICOLON) return true;
  return lastLine < this.tokenizer.line;
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
  return new fanx_ObjDecoder(InStream.__makeForStr(s), null).readObj();
}

fanx_ObjDecoder.err = function(msg, line)
{
  return IOErr.make(msg + " [Line " + line + "]");
}

fanx_ObjDecoder.defaultMapType = null;

//////////////////////////////////////////////////////////////////////////
// Using
//////////////////////////////////////////////////////////////////////////

function fanx_UsingPod(p) { this.pod = p; }
fanx_UsingPod.prototype.resolve = function(n)
{
  return this.pod.type(n, false);
}

function fanx_UsingType(t,n) { this.type = t; this.name = n; }
fanx_UsingType.prototype.resolve = function(n)
{
  return this.name == n ? this.type : null;
}

