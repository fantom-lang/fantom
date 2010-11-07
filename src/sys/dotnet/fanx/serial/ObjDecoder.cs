//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 07  Andy Frank  Creation
//

using System.Collections;
using Fan.Sys;
using Fanx.Util;

namespace Fanx.Serial
{
  /// <summary>
  /// ObjDecoder parses an object tree from an input stream.
  /// </summary>
  public class ObjDecoder
  {

  //////////////////////////////////////////////////////////////////////////
  // Static
  //////////////////////////////////////////////////////////////////////////

    public static object decode(string s)
    {
      return new ObjDecoder(FanStr.@in(s), null).readObj();
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Construct for input stream.
    /// </summary>
    public ObjDecoder(InStream @in, Map options)
    {
      tokenizer = new Tokenizer(@in);
      this.options = options;
      consume();
    }

  //////////////////////////////////////////////////////////////////////////
  // Parse
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Read an object from the stream.
    /// </summary>
    public object readObj()
    {
      readHeader();
      return readObj(null, null, true);
    }

    /// <summary>
    /// header := [using]*
    /// </summary>
    private void readHeader()
    {
      while (curt == Token.USING)
      {
        Using u = readUsing();
        if (usings == null) usings = new Using[8];
        if (numUsings  >= usings.Length)
        {
          Using[] temp = new Using[usings.Length*2];
          System.Array.Copy(usings, 0, temp, 0, numUsings);
          usings = temp;
        }
        usings[numUsings++] = u;
      }
    }

    /// <summary>
    /// using     := usingPod | usingType | usingAs
    /// usingPod  := "using" podName
    /// usingType := "using" podName::typeName
    /// usingAs   := "using" podName::typeName "as" name
    /// </summary>
    private Using readUsing()
    {
      consume();
      int line = tokenizer.m_line;

      string podName = consumeId("Expecting pod name");
      Pod pod = Pod.find(podName, false);
      if (pod == null) throw err("Unknown pod: " + podName);
      if (curt != Token.DOUBLE_COLON)
      {
        endOfStmt(line);
        return new UsingPod(pod);
      }

      consume();
      string typeName = consumeId("Expecting type name");
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

    /// <summary>
    /// obj := literal | simple | complex
    /// </summary>
    private object readObj(Field curField, Type peekType, bool root)
    {
      // literals are stand alone
      if (Token.isLiteral(curt))
      {
        object val = tokenizer.m_val;
        consume();
        return val;
      }

      // [ is always list/map collection
      if (curt == Token.LBRACKET)
        return readCollection(curField, peekType);

      // at this point all remaining options must start
      // with a type signature - if peekType is non-null
      // then we've already read the type signature
      int line = tokenizer.m_line;
      Type t = (peekType != null) ? peekType : readType();

      // type:     type#"
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

    /// <summary>
    /// typeLiteral := type "#"
    /// slotLiteral := type "#" id
    /// </summary>
    private object readTypeOrSlotLiteral(int line, Type t)
    {
      consume(Token.POUND, "Expected '#' for type literal");
      if (curt == Token.ID)
      {
        string slotName = consumeId("slot literal name");
        return t.slot(slotName);
      }
      else
      {
        return t;
      }
    }

    /// <summary>
    /// simple := type "(" str ")"
    /// </summary>
    private object readSimple(int line, Type t)
    {
      // parse: type(str)
      consume(Token.LPAREN, "Expected ( in simple");
      string str = consumeStr("Expected string literal for simple");
      consume(Token.RPAREN, "Expected ) in simple");

      // lookup the fromStr method
      t.finish();
      Method m = t.method("fromStr", false);
      if (m == null)
        throw err("Missing method: " + t.qname() + ".fromStr", line);

      // invoke parse method to translate into instance
      try
      {
        return m.invoke(null, new object[] { str });
      }
      catch (ParseErr.Val e)
      {
        throw ParseErr.make(e.err().msg() + " [Line " + line + "]").val;
      }
      catch (System.Exception e)
      {
        throw ParseErr.make(e.ToString() + " [Line " + line + "]", e).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Complex
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// complex := type [fields]
    /// fields  := "{" field (eos field)* "}"
    /// field   := name "=" obj
    /// </summary>
    private object readComplex(int line, Type t, bool root)
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
      object obj = null;
      bool setAfterCtor = true;
      try
      {
        // if first parameter is an function then pass toSet
        // as an it-block for setting the fields
        Param p = (Param)makeCtor.@params().first();
        if (args == null && p != null && p.type().fits(Sys.FuncType))
        {
          args = new List(Sys.ObjType).add(Field.makeSetFunc(toSet));
          setAfterCtor = false;
        }

        // invoke make to construct object
        obj = makeCtor.callList(args);
      }
      catch (System.Exception e)
      {
        throw err("Cannot make " + t + ": " + e, line, e);
      }

      // set fields (if not passed to ctor as it-block)
      if (setAfterCtor && toSet.size() > 0)
      {
        IDictionaryEnumerator en = toSet.pairsIterator();
        while (en.MoveNext())
        {
          complexSet(obj, (Field)en.Key, en.Value, line);
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
        int line = tokenizer.m_line;
        bool readField = false;
        if (curt == Token.ID)
        {
          string name = consumeId("Expected field name");
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
            tokenizer.undo(tokenizer.m_type, tokenizer.m_val, tokenizer.m_line);
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

    void readComplexSet(Type t, int line, string name, Map toSet)
    {
      // resolve field
      Field field = t.field(name, false);
      if (field == null) throw err("Field not found: " + t.qname() + "." + name, line);

      // parse value
      object val = readObj(field, null, false);

      try
      {
        // if const field, then make val immutable
        if (field.isConst()) val = OpUtil.toImmutable(val);
      }
      catch (System.Exception ex)
      {
        throw err("Cannot make object const for " + field.qname() + ": " + ex, line, ex);
      }

      // add to map
      toSet.set(field, val);
    }

    void complexSet(object obj, Field field, object val, int line)
    {
      try
      {
        if (field.isConst())
          field.set(obj, OpUtil.toImmutable(val), false);
        else
          field.set(obj, val);
      }
      catch (System.Exception ex)
      {
        throw err("Cannot set field " + field.qname() + ": " + ex, line, ex);
      }
    }

    void readComplexAdd(Type t, int line, List toAdd)
    {
      object val = readObj(null, null, false);

      // add to list
      toAdd.add(val);
    }

    void complexAdd(Type t, object obj, Method addMethod, object val, int line)
    {
      try
      {
        addMethod.invoke(obj, new object[] { val });
      }
      catch (System.Exception ex)
      {
        throw err("Cannot call " + t.qname() + ".add: " + ex, line, ex);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Collection
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// collection := list | map
    /// </summary>
    private object readCollection(Field curField, Type t)
    {
      // opening [
      consume(Token.LBRACKET, "Expecting '['");

      // if this could be a map type signature:
      //    [qname:qname]
      //    [qname:qname][]
      //    [qname:qname][][] ...
      // or it could just be the type signature of
      // of a embedded simple, complex, or list
      Type peekType = null;
      if (curt == Token.ID && t == null)
      {
        // peek at the type
        peekType = readType();

        // if we have [mapType] then this is non-inferred type signature
        if (curt == Token.RBRACKET && peekType is MapType)
        {
          t = peekType; peekType = null;
          consume();
          while (curt == Token.LRBRACKET) { consume(); t = t.toListOf(); }
          if (curt == Token.QUESTION) { consume(); t = t.toNullable(); }
          if (curt == Token.POUND) { consume(); return t; }
          consume(Token.LBRACKET, "Expecting '['");
        }
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
      object first = readObj(null, peekType, false);

      // now we can distinguish b/w list and map
      if (curt == Token.COLON)
        return readMap(toMapType(t, curField, true), first);
      else
        return readList(toListOfType(t, curField, true), first);
    }

    /// <summary>
    /// list := "[" obj ("," obj)* "]"
    /// </summary>
    private object readList(Type of, object first)
    {
      // setup accumulator
      object[] acc = new object[8];
      int n = 0;
      acc[n++] = first;

      // parse list items
      while (curt != Token.RBRACKET)
      {
        consume(Token.COMMA, "Expected ','");
        if (curt == Token.RBRACKET) break;
        if (n >= acc.Length)
        {
          object[] temp = new object[n*2];
          System.Array.Copy(acc, 0, temp, 0, n);
          acc = temp;
        }
        acc[n++] = readObj(null, null, false);
      }
      consume(Token.RBRACKET, "Expected ']'");

      // infer type if needed
      if (of == null) of = Type.common(acc, n);

      return new List(of, acc, n);
    }

    /// <summary>
    /// map     := "[" mapPair ("," mapPair)* "]"
    /// mapPair := obj ":" + obj
    /// </summary>
    private object readMap(MapType mapType, object firstKey)
    {
      // setup accumulator
      Hashtable map = new Hashtable();

      // finish first pair
      consume(Token.COLON, "Expected ':'");
      map[firstKey] = readObj(null, null, false);


      // parse map pairs
      while (curt != Token.RBRACKET)
      {
        consume(Token.COMMA, "Expected ','");
        if (curt == Token.RBRACKET) break;
        object key = readObj(null, null, false);
        consume(Token.COLON, "Expected ':'");
        object val = readObj(null, null, false);
        map[key] = val;
      }
      consume(Token.RBRACKET, "Expected ']'");

      // infer type if necessary
      if (mapType == null)
      {
        int size = map.Count;
        object[] keys = new object[map.Count];
        object[] vals = new object[map.Count];
        IDictionaryEnumerator en = map.GetEnumerator();
        int i = 0;
        while (en.MoveNext())
        {
          keys[i] = en.Key;
          vals[i] = en.Value;
          i++;
        }
        Type k = Type.common(keys, size);
        Type v = Type.common(vals, size);
        mapType = new MapType(k, v);
      }

      return new Map((MapType)mapType, map);
    }

    /// <summary>
    /// Figure out the type of the list:
    ///   1) if t was explicit then use it
    ///   2) if we have field typed as a list, then use its definition
    ///   3) if inferred is false, then drop back to list of Obj
    ///   4) If inferred is true then return null and we'll infer the common type
    /// </summary>
    private Type toListOfType(Type t, Field curField, bool infer)
    {
      if (t != null) return t;
      if (curField != null)
      {
        Type ft = curField.type().toNonNullable();
        if (ft is ListType) return ((ListType)ft).m_v;
      }
      if (infer) return null;
      return Sys.ObjType.toNullable();
    }

    /// <summary>
    /// Figure out the map type:
    ///   1) if t was explicit then use it (check that it was a map type)
    ///   2) if we have field typed as a map , then use its definition
    ///   3) if inferred is false, then drop back to Obj:Obj
    ///   4) If inferred is true then return null and we'll infer the common key/val types
    /// </summary>
    private MapType toMapType(Type t, Field curField, bool infer)
    {
      if (t != null)
      {
        try { return (MapType)t; }
        catch (System.InvalidCastException) { throw err("Invalid map type: " + t); }
      }

      if (curField != null)
      {
        Type ft = curField.type().toNonNullable();
        if (ft is MapType) return (MapType)ft;
      }

      if (infer) return null;
      return defaultMapType;
    }
    private static readonly MapType defaultMapType = new MapType(Sys.ObjType, Sys.ObjType.toNullable());

  //////////////////////////////////////////////////////////////////////////
  // Type
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// type    := listSig | mapSig1 | mapSig2 | qname
    /// listSig := type "[]"
    /// mapSig1 := type ":" type
    /// mapSig2 := "[" type ":" type "]"
    ///
    /// Note: the mapSig2 with brackets is handled by the
    /// method succinctly named readMapTypeOrCollection().
    /// </summary>
    private Type readType() { return readType(false); }
    private Type readType(bool lbracket)
    {
      Type t = readSimpleType();
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

    /// <summary>
    /// qname := [podName "::"] typeName
    /// </summary>
    private Type readSimpleType()
    {
      // parse identifier
      int line = tokenizer.m_line;
      string n = consumeId("Expected type signature");

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
      consume(Token.DOUBLE_COLON, "Expected :: in type qname");
      string typeName = consumeId("Expected type name");

      // resolve pod
      Pod pod = Pod.find(n, false);
      if (pod == null) throw err("Pod not found: " + n, line);

      // resolve type
      Type type = pod.type(typeName, false);
      if (type == null) throw err("Type not found: " + n+ "::" + typeName, line);
      return type;
    }

  //////////////////////////////////////////////////////////////////////////
  // Error Handling
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Create error reporting exception.
    /// </summary>
    internal static System.Exception err(string msg, int line) { return err(msg, line, null); }
    internal static System.Exception err(string msg, int line, System.Exception ex)
    {
      return IOErr.make(msg + " [Line " + line + "]", ex).val;
    }

    /// <summary>
    /// Create exception based on tokenizers current line.
    /// </summary>
    private System.Exception err(string msg)
    {
      return err(msg, tokenizer.m_line);
    }

  //////////////////////////////////////////////////////////////////////////
  // Tokens
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Consume the current token as a identifier.
    /// </summary>
    private string consumeId(string expected)
    {
      verify(Token.ID, expected);
      string id = (string)tokenizer.m_val;
      consume();
      return id;
    }

    /// <summary>
    /// Consume the current token as a string literal.
    /// </summary>
    private string consumeStr(string expected)
    {
      verify(Token.STR_LITERAL, expected);
      string id = (string)tokenizer.m_val;
      consume();
      return id;
    }

    /// <summary>
    /// Check that the current token matches the
    /// specified type, and then consume it.
    /// </summary>
    private void consume(int type, string expected)
    {
      verify(type, expected);
      consume();
    }

    /// <summary>
    /// Check that the current token matches the specified
    /// type, but do not consume it.
    /// </summary>
    private void verify(int type, string expected)
    {
      if (curt != type)
        throw err(expected + ", not '" + Token.toString(curt) + "'");
    }

    /// <summary>
    /// Consume the current token.
    /// </summary>
    private void consume()
    {
      curt = tokenizer.next();
    }

    /// <summary>
    /// Statements can be terminated with a semicolon, end of line or } end of block.
    /// </summary>
    private void endOfStmt(int lastLine)
    {
      if (curt == Token.EOF) return;
      if (curt == Token.SEMICOLON) { consume(); return; }
      if (lastLine < tokenizer.m_line) return;
      if (curt == Token.RBRACE) return;
      throw err("Expected end of statement: semicolon, newline, or end of block; not '" + Token.toString(curt) + "'");
    }

  //////////////////////////////////////////////////////////////////////////
  // Using
  //////////////////////////////////////////////////////////////////////////

    internal abstract class Using
    {
      internal abstract Type resolve(string name);
    }

    internal class UsingPod : Using
    {
      internal UsingPod(Pod p) { pod = p; }
      internal override Type resolve(string n) { return pod.type(n, false); }
      Pod pod;
    }

    internal class UsingType : Using
    {
      internal UsingType(Type t, string n) { type = t; name = n; }
      internal override Type resolve(string n) { return name == n ? type : null; }
      string name;
      Type type;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal Tokenizer tokenizer;    // tokenizer
    internal int curt;               // current token type
    internal Map options;            // decode option name/value pairs
    internal Using[] usings;         // using imports
    internal int numUsings = 0;      // number of using imports

  }
}