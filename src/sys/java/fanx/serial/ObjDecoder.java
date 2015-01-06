//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Aug 07  Brian Frank  Creation
//
package fanx.serial;

import fan.sys.*;
import fanx.util.*;
import java.util.LinkedHashMap;
import java.util.Iterator;
import java.util.Map.Entry;

/**
 * ObjDecoder parses an object tree from an input stream.
 */
public class ObjDecoder
{

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

  public static Object decode(String s)
  {
    return new ObjDecoder(FanStr.in(s), null).readObj();
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  /**
   * Construct for input stream.
   */
  public ObjDecoder(InStream in, Map options)
  {
    tokenizer = new Tokenizer(in);
    this.options = options;
    consume();
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  /**
   * Read an object from the stream.
   */
  public final Object readObj()
  {
    readHeader();
    return readObj(null, null, true);
  }

  /**
   * header := [using]*
   */
  private void readHeader()
  {
    while (curt == Token.USING)
    {
      Using u = readUsing();
      if (usings == null) usings = new Using[8];
      if (numUsings  >= usings.length)
      {
        Using[] temp = new Using[usings.length*2];
        System.arraycopy(usings, 0, temp, 0, numUsings );
        usings = temp;
      }
      usings[numUsings++] = u;
    }
  }

  /**
   * using     := usingPod | usingType | usingAs
   * usingPod  := "using" podName
   * usingType := "using" podName::typeName
   * usingAs   := "using" podName::typeName "as" name
   */
  private Using readUsing()
  {
    int line = tokenizer.line;
    consume();

    String podName = consumeId("Expecting pod name");
    Pod pod = Pod.find(podName, false);
    if (pod == null) throw err("Unknown pod: " + podName);
    if (curt != Token.DOUBLE_COLON)
    {
      endOfStmt(line);
      return new UsingPod(pod);
    }

    consume();
    String typeName = consumeId("Expecting type name");
    Type t = pod.type(typeName, false);
    if (t == null) throw err("Unknown type: " + podName + "::" + typeName);

    if (curt == Token.AS)
    {
      consume();
      typeName = consumeId("Expecting using as name");
    }

    endOfStmt(line);
    return new UsingType(t, typeName);
  }

  /**
   * obj := literal | simple | complex
   */
  private Object readObj(Field curField, Type peekType, boolean root)
  {
    // literals are stand alone
    if (Token.isLiteral(curt))
    {
      Object val = tokenizer.val;
      consume();
      return val;
    }

    // [ is always list/map collection (or map/FFI type)
    if (curt == Token.LBRACKET)
      return readCollection(curField, peekType);

    // at this point all remaining options must start
    // with a type signature - if peekType is non-null
    // then we've already read the type signature
    int line = tokenizer.line;
    Type t = (peekType != null) ? peekType : readType();

    // type:     type#
    // simple:   type(
    // list/map: type[
    // complex:  type || type{
    if (curt == Token.LPAREN)
      return readSimple(line, t);
    else if (curt == Token.POUND)
      return readTypeOrSlotLiteral(line, t);
    else if (curt == Token.LBRACKET)
      return readCollection(curField, t);
    else
      return readComplex(line, t, root);
  }

  /**
   * typeLiteral := type "#"
   * slotLiteral := type "#" id
   */
  private Object readTypeOrSlotLiteral(int line, Type t)
  {
    consume(Token.POUND, "Expected '#' for type literal");
    if (curt == Token.ID && !isEndOfStmt(line))
    {
      String slotName = consumeId("slot literal name");
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
  private Object readSimple(int line, Type t)
  {
    // parse: type(str)
    consume(Token.LPAREN, "Expected ( in simple");
    String str = consumeStr("Expected string literal for simple");
    consume(Token.RPAREN, "Expected ) in simple");

    // lookup the fromString method
    t.finish();
    Method m = t.method("fromStr", false);
    if (m == null)
    {
      // fallback to valueOf for java.lang.Enums
      if (t instanceof JavaType) m = t.method("valueOf", false);
      if (m == null)
        throw err("Missing method: " + t.qname() + ".fromStr", line);
    }

    // invoke parse method to translate into instance
    try
    {
      return m.invoke(null, new Object[] { str });
    }
    catch (ParseErr e)
    {
      throw ParseErr.make(e.msg() + " [Line " + line + "]");
    }
    catch (Throwable e)
    {
      throw ParseErr.make(e.toString() + " [Line " + line + "]", e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Complex
//////////////////////////////////////////////////////////////////////////

  /**
   * complex := type [fields]
   * fields  := "{" field (eos field)* "}"
   * field   := name "=" obj
   */
  private Object readComplex(int line, Type t, boolean root)
  {
    Map toSet = new Map(Sys.FieldType, Sys.ObjType.toNullable());
    List toAdd = new List(Sys.ObjType.toNullable());

    // read fields/collection into toSet/toAdd
    readComplexFields(t, toSet, toAdd);

    // get the make constructor
    Method makeCtor = t.method("make", false);
    if (makeCtor == null || !makeCtor.isPublic())
      throw err("Missing public constructor " + t.qname() + ".make", line);

    // get argument lists
    List args = null;
    if (root && options != null)
      args = (List)options.get("makeArgs");

    // construct object
    Object obj = null;
    boolean setAfterCtor = true;
    try
    {
      // if first parameter is an function then pass toSet
      // as an it-block for setting the fields
      Param p = (Param)makeCtor.params().first();
      if (args == null && p != null && p.type().fits(Sys.FuncType))
      {
        args = new List(Sys.ObjType).add(Field.makeSetFunc(toSet));
        setAfterCtor = false;
      }

      // invoke make to construct object
      obj = makeCtor.callList(args);
    }
    catch (Throwable e)
    {
      throw err("Cannot make " + t + ": " + e, line, e);
    }

    // set fields (if not passed to ctor as it-block)
    if (setAfterCtor && toSet.size() > 0)
    {
      Iterator it = toSet.pairsIterator();
      while (it.hasNext())
      {
        Entry e = (Entry)it.next();
        complexSet(obj, (Field)e.getKey(), e.getValue(), line);
      }
    }

    // add
    if (toAdd.size() > 0)
    {
      Method addMethod = t.method("add", false);
      if (addMethod == null) throw err("Method not found: " + t.qname() + ".add", line);
      for (int i=0; i<toAdd.sz(); ++i)
        complexAdd(t, obj, addMethod, toAdd.get(i), line);
    }

    return obj;
  }

  private void readComplexFields(Type t, Map toSet, List toAdd)
  {
    if (curt != Token.LBRACE) return;
    consume();

    // fields and/or collection items
    while (curt != Token.RBRACE)
    {
      // try to read "id =" to see if we have a field
      int line = tokenizer.line;
      boolean readField = false;
      if (curt == Token.ID)
      {
        String name = consumeId("Expected field name");
        if (curt == Token.EQ)
        {
          // we have "id =" so read field
          consume();
          readComplexSet(t, line, name, toSet);
          readField = true;
        }
        else
        {
          // pushback to reset on start of collection item
          tokenizer.undo(tokenizer.type, tokenizer.val, tokenizer.line);
          curt = tokenizer.reset(Token.ID, name, line);
        }
      }

      // if we didn't read a field, we assume a collection item
      if (!readField) readComplexAdd(t, line, toAdd);

      if (curt == Token.COMMA) consume();
      else endOfStmt(line);
    }
    consume(Token.RBRACE, "Expected '}'");
  }

  void readComplexSet(Type t, int line, String name, Map toSet)
  {
    // resolve field
    Field field = t.field(name, false);
    if (field == null) throw err("Field not found: " + t.qname() + "." + name, line);

    // parse value
    Object val = readObj(field, null, false);

    try
    {
      // if const field, then make val immutable
      if (field.isConst()) val = OpUtil.toImmutable(val);
    }
    catch (Throwable ex)
    {
      throw err("Cannot make object const for " + field.qname() + ": " + ex, line, ex);
    }

    // add to map
    toSet.set(field, val);
  }

  void complexSet(Object obj, Field field, Object val, int line)
  {
    try
    {
      if (field.isConst())
        field.set(obj, OpUtil.toImmutable(val), false);
      else
        field.set(obj, val);
    }
    catch (Throwable ex)
    {
      throw err("Cannot set field " + field.qname() + ": " + ex, line, ex);
    }
  }

  void readComplexAdd(Type t, int line, List toAdd)
  {
    Object val = readObj(null, null, false);

    // add to list
    toAdd.add(val);
  }

  void complexAdd(Type t, Object obj, Method addMethod, Object val, int line)
  {
    try
    {
      addMethod.invoke(obj, new Object[] { val });
    }
    catch (Throwable ex)
    {
      throw err("Cannot call " + t.qname() + ".add: " + ex, line, ex);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Collection
//////////////////////////////////////////////////////////////////////////

  /**
   * collection := list | map
   */
  private Object readCollection(Field curField, Type t)
  {
    // opening [
    consume(Token.LBRACKET, "Expecting '['");

    // if this could be a map/FFI type signature:
    //    [qname:qname]
    //    [qname:qname][]
    //    [qname:qname][][] ...
    //    [java]foo.bar
    // or it could just be the type signature of
    // of a embedded simple, complex, or list
    Type peekType = null;
    if (curt == Token.ID && t == null)
    {
      // peek at the type
      peekType = readType(true);

      // if we have [mapType] then this is non-inferred type signature
      if (curt == Token.RBRACKET && peekType instanceof MapType)
      {
        t = peekType; peekType = null;
        consume();
        while (curt == Token.LRBRACKET) { consume(); t = t.toListOf(); }
        if (curt == Token.QUESTION) { consume(); t = t.toNullable(); }
        if (curt == Token.POUND) { consume(); return t; }
        consume(Token.LBRACKET, "Expecting '['");
      }

      // if the type was a FFI JavaType, this isn't a collection
      if (peekType != null && peekType.isJava())
        return readObj(curField, peekType, false);
    }

    // handle special case of [,]
    if (curt == Token.COMMA && peekType == null)
    {
      consume();
      consume(Token.RBRACKET, "Expecting ']'");
      return new List(toListOfType(t, curField, false));
    }

    // handle special case of [:]
    if (curt == Token.COLON && peekType == null)
    {
      consume();
      consume(Token.RBRACKET, "Expecting ']'");
      return new Map(toMapType(t, curField, false));
    }

    // read first list item or first map key
    Object first = readObj(null, peekType, false);

    // now we can distinguish b/w list and map
    if (curt == Token.COLON)
      return readMap(toMapType(t, curField, true), first);
    else
      return readList(toListOfType(t, curField, true), first);
  }

  /**
   * list := "[" obj ("," obj)* "]"
   */
  private Object readList(Type of, Object first)
  {
    // setup accumulator
    Object[] acc = new Object[8];
    int n = 0;
    acc[n++] = first;

    // parse list items
    while (curt != Token.RBRACKET)
    {
      consume(Token.COMMA, "Expected ','");
      if (curt == Token.RBRACKET) break;
      if (n >= acc.length)
      {
        Object[] temp = new Object[n*2];
        System.arraycopy(acc, 0, temp, 0, n);
        acc = temp;
      }
      acc[n++] = readObj(null, null, false);
    }
    consume(Token.RBRACKET, "Expected ']'");

    // infer type if needed
    if (of == null) of = Type.common(acc, n);

    return new List(of, acc, n);
  }

  /**
   * map     := "[" mapPair ("," mapPair)* "]"
   * mapPair := obj ":" + obj
   */
  private Object readMap(MapType mapType, Object firstKey)
  {
    // setup accumulator
    LinkedHashMap map = new LinkedHashMap();

    // finish first pair
    consume(Token.COLON, "Expected ':'");
    map.put(firstKey, readObj(null, null, false));

    // parse map pairs
    while (curt != Token.RBRACKET)
    {
      consume(Token.COMMA, "Expected ','");
      if (curt == Token.RBRACKET) break;
      Object key = readObj(null, null, false);
      consume(Token.COLON, "Expected ':'");
      Object val = readObj(null, null, false);
      map.put(key, val);
    }
    consume(Token.RBRACKET, "Expected ']'");

    // infer type if necessary
    if (mapType == null)
    {
      int size = map.size();
      Type k = Type.common(map.keySet().toArray(new Object[size]), size);
      Type v = Type.common(map.values().toArray(new Object[size]), size);
      mapType = new MapType(k, v);
    }

    return new Map((MapType)mapType, map);
  }

  /**
   * Figure out the type of the list:
   *   1) if t was explicit then use it
   *   2) if we have field typed as a list, then use its definition
   *   3) if inferred is false, then drop back to list of Obj
   *   4) If inferred is true then return null and we'll infer the common type
   */
  private Type toListOfType(Type t, Field curField, boolean infer)
  {
    if (t != null) return t;
    if (curField != null)
    {
      Type ft = curField.type().toNonNullable();
      if (ft instanceof ListType) return ((ListType)ft).v;
    }
    if (infer) return null;
    return Sys.ObjType.toNullable();
  }

  /**
   * Figure out the map type:
   *   1) if t was explicit then use it (check that it was a map type)
   *   2) if we have field typed as a map , then use its definition
   *   3) if inferred is false, then drop back to Obj:Obj
   *   4) If inferred is true then return null and we'll infer the common key/val types
   */
  private MapType toMapType(Type t, Field curField, boolean infer)
  {
    if (t != null)
    {
      try { return (MapType)t; }
      catch (ClassCastException e) { throw err("Invalid map type: " + t); }
    }

    if (curField != null)
    {
      Type ft = curField.type().toNonNullable();
      if (ft instanceof MapType) return (MapType)ft;
    }

    if (infer) return null;

    if (defaultMapType == null)
      defaultMapType = new MapType(Sys.ObjType, Sys.ObjType.toNullable());
    return defaultMapType;
  }

  private static MapType defaultMapType;

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
  private Type readType() { return readType(false); }
  private Type readType(boolean lbracket)
  {
    Type t = readSimpleType(lbracket);
    if (curt == Token.QUESTION)
    {
      consume();
      t = t.toNullable();
    }
    if (curt == Token.COLON)
    {
      consume();
      t = new MapType(t, readType());
    }
    while (curt == Token.LRBRACKET)
    {
      consume();
      t = t.toListOf();
    }
    if (curt == Token.QUESTION)
    {
      consume();
      t = t.toNullable();
    }
    return t;
  }

  /**
   * qname := [podName "::"] typeName
   */
  private Type readSimpleType(boolean lbracket)
  {
    // parse identifier
    int line = tokenizer.line;
    String n = consumeId("Expected type signature");
    boolean ffi = false;

    // handle [java]foo.bar
    if (n.equals("java") && lbracket)
    {
      ffi = true;
      consume(Token.RBRACKET, "Expected ] in Java FFI [java]");
      n = "[java]" + consumeId("Expected Java FFI type name");
      while (curt == Token.DOT || curt == Token.DOLLAR)
      {
        String symbol = Token.toString(curt);
        consume();
        n += symbol + consumeId("Expected Java FFI type name");
      }
    }

    // check for using imported name
    if (curt != Token.DOUBLE_COLON)
    {
      for (int i=0; i<numUsings; ++i)
      {
        Type t = usings[i].resolve(n);
        if (t != null) return t;
      }
      throw err("Unresolved type name: " + n);
    }

    // must be fully qualified
    consume(Token.DOUBLE_COLON, "Expected ::");
    String typeName = consumeId("Expected type name");

    // handle Outer$Inner for Java FFI
    if (curt == Token.DOLLAR)
    {
      String symbol = Token.toString(curt);
      consume();
      typeName += symbol + consumeId("Expected Java FFI type name");
    }

    // if Java FFI, then don't optimize pod/type lookup
    if (ffi) return Type.find(n + "::" + typeName);

    // resolve pod
    Pod pod = Pod.find(n, false);
    if (pod == null) throw err("Pod not found: " + n, line);

    // resolve type
    Type type = pod.type(typeName, false);
    if (type == null) throw err("Type not found: " + n + "::" + typeName, line);
    return type;
  }

//////////////////////////////////////////////////////////////////////////
// Error Handling
//////////////////////////////////////////////////////////////////////////

  /**
   * Create error reporting exception.
   */
  static RuntimeException err(String msg, int line) { return err(msg, line, null); }
  static RuntimeException err(String msg, int line, Throwable e)
  {
    return IOErr.make(msg + " [Line " + line + "]", e);
  }

  /**
   * Create exception based on tokenizers current line.
   */
  private RuntimeException err(String msg)
  {
    return err(msg, tokenizer.line);
  }

//////////////////////////////////////////////////////////////////////////
// Tokens
//////////////////////////////////////////////////////////////////////////

  /**
   * Consume the current token as a identifier.
   */
  private String consumeId(String expected)
  {
    verify(Token.ID, expected);
    String id = (String)tokenizer.val;
    consume();
    return id;
  }

  /**
   * Consume the current token as a String literal.
   */
  private String consumeStr(String expected)
  {
    verify(Token.STR_LITERAL, expected);
    String id = (String)tokenizer.val;
    consume();
    return id;
  }

  /**
   * Check that the current token matches the
   * specified type, and then consume it.
   */
  private void consume(int type, String expected)
  {
    verify(type, expected);
    consume();
  }

  /**
   * Check that the current token matches the specified
   * type, but do not consume it.
   */
  private void verify(int type, String expected)
  {
    if (curt != type)
      throw err(expected + ", not '" + Token.toString(curt) + "'");
  }

  /**
   * Consume the current token.
   */
  private void consume()
  {
    curt = tokenizer.next();
  }

  /**
   * Is current token part of the next statement?
   */
  private boolean isEndOfStmt(int lastLine)
  {
    if (curt == Token.EOF) return true;
    if (curt == Token.SEMICOLON) return true;
    return lastLine < tokenizer.line;
  }

  /**
   * Statements can be terminated with a semicolon, end of line or } end of block.
   */
  private void endOfStmt(int lastLine)
  {
    if (curt == Token.EOF) return;
    if (curt == Token.SEMICOLON) { consume(); return; }
    if (lastLine < tokenizer.line) return;
    if (curt == Token.RBRACE) return;
    throw err("Expected end of statement: semicolon, newline, or end of block; not '" + Token.toString(curt) + "'");
  }

//////////////////////////////////////////////////////////////////////////
// Using
//////////////////////////////////////////////////////////////////////////

  static abstract class Using
  {
    abstract Type resolve(String name);
  }

  static class UsingPod extends Using
  {
    UsingPod(Pod p) { pod = p; }
    Type resolve(String n) { return pod.type(n, false); }
    final Pod pod;
  }

  static class UsingType extends Using
  {
    UsingType(Type t, String n) { type = t; name = n; }
    Type resolve(String n) { return name.equals(n) ? type : null; }
    final String name;
    final Type type;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Tokenizer tokenizer;    // tokenizer
  int curt;               // current token type
  Map options;            // decode option name/value pairs
  Using[] usings;         // using imports
  int numUsings = 0;      // number of using imports

}