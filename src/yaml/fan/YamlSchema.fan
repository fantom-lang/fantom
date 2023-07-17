#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    6 Jul 2022  Kiera O'Flynn   Creation
//

**************************************************************************
** YamlSchema
**************************************************************************

**
** A class used to convert parsed YamlObjs to native Fantom objects,
** and vice versa.
**
** Different schemas can recognize different tags; for example, the
** failsafe schema only recognizes the str, seq, and map tags and
** ignores all the rest (thus only generating Strs, Lists, and Maps),
** while the JSON schema also recognizes integers, booleans, etc.
**
** See the [pod documentation]`yaml::pod-doc#schemas` for more information,
** especially about the specifics of each built-in schema.
**
abstract const class YamlSchema
{

//////////////////////////////////////////////////////////////////////////
// Get instances of built-in schemas
//////////////////////////////////////////////////////////////////////////

  ** A basic YamlSchema that only generates maps, lists, and strings.
  static const YamlSchema failsafe

  ** A YamlSchema that can parse all JSON tokens and errors when a plain
  ** token is not JSON-compliant.
  static const YamlSchema json

  ** The default YamlSchema.
  static const YamlSchema core

  static
  {
    failsafe = FailsafeSchema()
    json = JsonSchema()
    core = CoreSchema()
  }

//////////////////////////////////////////////////////////////////////////
// Encoding & decoding YamlObjs
//////////////////////////////////////////////////////////////////////////

  ** Recursively transforms the YAML object into a native Fantom
  ** object using this tag resolution schema.
  virtual Obj? decode(YamlObj node) { null }

  ** Transforms the native Fantom object into a YamlObj hierarchy
  ** that preserves as much information as possible. The object
  ** must be [serializable]`docLang::Serialization#serializable` or
  ** [simple]`docLang::Serialization#simple`. YamlObjs are encoded
  ** as themselves; no further processing is done.
  abstract YamlObj encode(Obj? obj)

//////////////////////////////////////////////////////////////////////////
// Helper methods
//////////////////////////////////////////////////////////////////////////

  ** Assigns a tag to an arbitrary node.
  ** This tag must be recognized by the schema.
  @NoDoc
  protected abstract Str assignTag(YamlObj node)

  ** Validate that the node's tag matches the node's type and content.
  ** Requires that the node's tag is recognized by the schema.
  @NoDoc
  protected virtual Void validate(YamlObj node) {}

  ** Returns true if the given tag is recognized by this schema.
  ** If a tag is not recognized, it will be treated as a "?" non-specific tag.
  @NoDoc
  protected virtual Bool isRecognized(Str tag) { false }

  ** Recursive helper for 'encode' implementations.
  @NoDoc
  protected YamlObj recEncode(Obj? obj, |Obj?->YamlObj| f)
  {
    // Check if serializable
    type := obj?.typeof
    Serializable? ser := type?.facet(Serializable#, false)
    if (ser == null && obj != null && !(obj is Str))
      throw IOErr("Object type not serializable: $type")

    // YamlObj
    if (obj is YamlObj)      return obj
    // Null/str
    else if (obj == null ||
             obj is Str)     return f(obj)
    // Simple - needs tag
    else if (ser.simple)     return YamlScalar(f(obj).val, "!fan/$type")
    // List
    else if (obj is List)    return YamlList(YamlObj[,].addAll((obj as List).map |v| { return recEncode(v, f) }))
    // Map
    else if (obj is Map)
    {
      map := obj as Map
      res := [YamlObj:YamlObj][:]
      map.each |v, k| { res.add(recEncode(k, f), recEncode(v, f)) }
      return YamlMap(res)
    }
    // Obj
    else
    {
      res := [YamlObj:YamlObj][:]

      // Add each non-transient field
      type.fields.each |field|
      {
        if (field.isStatic || field.hasFacet(Transient#)) return
        res.add(recEncode(field.name, f), recEncode(field.get(obj), f))
      }

      // Add each child object if this is a collection
      if (ser.collection)
      {
        eachList := [,]
        obj->each |child| { eachList.add(child) }
        res.add(recEncode("each", f), recEncode(eachList, f))
      }

      return YamlMap(res, "!fan/$type")
    }
  }

  ** Helper for encodings. Returns true if this string can be written in
  ** plain style and still be interpreted as the string itself.
  @NoDoc
  protected Bool worksAsPlain(Str s)
  {
    try
    {
      res := YamlReader(s.in).parse.decode(this)
      return res->get(0) == s
    }
    catch (Err e)
    {
      return false
    }
  }
}

**************************************************************************
** YamlTagErr
**************************************************************************

** YamlTagErr indicates that a YAML tag is set that does not match its node's content.
@NoDoc
const class YamlTagErr : Err
{
  ** Used when the given tag cannot be assigned to the given node type,
  ** e.g. attempting to assign a map tag to a [YamlList]`yaml::YamlList`.
  new makeType(Str tag, Type type)
  : super.make("The tag \"$tag\" cannot be assigned to the node type ${type.name}.") {}

  ** Used when the YamlObj's tag and content do not match, e.g. combining the tag
  ** 'tag:yaml.org,2002:int' with the content '"true"'.
  new makeContent(YamlObj obj)
  : super.make("The tag \"$obj.tag\" does not fit the content \"$obj.val\".") {}

  new makeStr(Str msg) : super.make(msg) {}
}

**************************************************************************
** FailsafeSchema
**************************************************************************

** A basic YamlSchema that only generates maps, lists, and strings.
@NoDoc
const class FailsafeSchema : YamlSchema
{

//////////////////////////////////////////////////////////////////////////
// Encoding & decoding YamlObjs
//////////////////////////////////////////////////////////////////////////

  override Obj? decode(YamlObj node)
  {
    tag := node.tag

    if (!isRecognized(tag)) tag = assignTag(node)  // Assign tag
    else validate(node)                            // Validate tag

    // Create object
    if (super.isRecognized(tag)) return super.decode(node)
    switch (tag)
    {
      case "tag:yaml.org,2002:str":
        return node.val

      case "tag:yaml.org,2002:seq":
        return (node.val as YamlObj[]).map |n| { decode(n) }

      case "tag:yaml.org,2002:map":
        res := [:]
        res.ordered = true
        map := node.val as [YamlObj:YamlObj]
        map.keys.each |k|
        {
          k2 := decode(k)
          if (k2 == null)
            throw NullErr("Maps in Fantom cannot contain null keys.")
          if (res.containsKey(k2))
            throw YamlTagErr("The key \"$k2\", generated by the current schema from \"$k.val\", is already present in this map.")
          res.add(decode(k).toImmutable, decode(map[k]))
        }
        return res

      default:
        throw Err("Internal error - all tags should have been covered.")
    }
  }

  override YamlObj encode(Obj? obj)
  {
    recEncode(obj) |v|
    {
      str := v == null ? "null" : v.toStr
      return YamlScalar(str, worksAsPlain(str) ? "?" : "!")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Inherited helper methods
//////////////////////////////////////////////////////////////////////////

  override Str assignTag(YamlObj node)
  {
    switch (node.typeof)
    {
      case YamlScalar#: return "tag:yaml.org,2002:str"
      case YamlList#:   return "tag:yaml.org,2002:seq"
      case YamlMap#:    return "tag:yaml.org,2002:map"
      default:          throw Err("The YAML node type $node.typeof is not supported by the current schema.")
    }
  }

  override Void validate(YamlObj node)
  {
    if (super.isRecognized(node.tag)) super.validate(node)
    else switch (node.tag)
    {
      case "tag:yaml.org,2002:str":
        if (node.typeof != YamlScalar#)
          throw YamlTagErr(node.tag, YamlScalar#)

      case "tag:yaml.org,2002:seq":
        if (node.typeof != YamlList#)
          throw YamlTagErr(node.tag, YamlList#)

      case "tag:yaml.org,2002:map":
        if (node.typeof != YamlMap#)
          throw YamlTagErr(node.tag, YamlMap#)
    }
  }

  override Bool isRecognized(Str tag)
  {
    super.isRecognized(tag) ||
    ["str", "seq", "map"].map |s| { "tag:yaml.org,2002:$s" }.contains(tag)
  }
}

**************************************************************************
** JsonSchema
**************************************************************************

** A YamlSchema that can parse all JSON tokens and errors when a plain
** token is not JSON-compliant.
@NoDoc
const class JsonSchema : FailsafeSchema
{

//////////////////////////////////////////////////////////////////////////
// Encoding & decoding YamlObjs
//////////////////////////////////////////////////////////////////////////

  override Obj? decode(YamlObj node)
  {
    tag := node.tag

    if (!isRecognized(tag)) tag = assignTag(node)  // Assign tag
    else validate(node)                            // Validate tag

    // Create object
    if (super.isRecognized(tag)) return super.decode(node)
    switch (tag)
    {
      case "tag:yaml.org,2002:null":
        return null

      case "tag:yaml.org,2002:bool":
        return node.val == "true"

      case "tag:yaml.org,2002:int":
        return Int(node.val)

      case "tag:yaml.org,2002:float":
        return Float(node.val)

      default:
        throw Err("Internal error - all tags should have been covered.")
    }
  }

  override YamlObj encode(Obj? obj)
  {
    recEncode(obj) |v|
    {
      if (v == null ||
          v is Bool ||
          v is Int  ||
          (v is Float &&
           !v->isNaN &&
           v != Float.posInf &&
           v != Float.negInf))
        return YamlScalar(v == null ? "null" : v.toStr)
      else return YamlScalar(v.toStr, "!")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Inherited helper methods
//////////////////////////////////////////////////////////////////////////

  override Str assignTag(YamlObj node)
  {
    if (node.typeof != YamlScalar#)
      return super.assignTag(node)

    if (matchNull.matches(node.val))  return "tag:yaml.org,2002:null"
    if (matchBool.matches(node.val))  return "tag:yaml.org,2002:bool"
    if (matchInt.matches(node.val))   return "tag:yaml.org,2002:int"
    if (matchFloat.matches(node.val)) return "tag:yaml.org,2002:float"

    throw YamlTagErr("The plain content \"$node.val\" does not match any valid JSON type.")
  }

  override Void validate(YamlObj node)
  {
    if (super.isRecognized(node.tag)) super.validate(node)
    else
    {
      if (node.typeof != YamlScalar#)
        throw YamlTagErr(node.tag, YamlScalar#)

      switch (node.tag)
      {
        case "tag:yaml.org,2002:null":
          if (!matchNull.matches(node.val))
            throw YamlTagErr(node)

        case "tag:yaml.org,2002:bool":
          if (!matchBool.matches(node.val))
            throw YamlTagErr(node)

        case "tag:yaml.org,2002:int":
          if (!matchInt.matches(node.val))
            throw YamlTagErr(node)

        case "tag:yaml.org,2002:float":
          if (!matchFloat.matches(node.val))
            throw YamlTagErr(node)
      }
    }
  }

  override Bool isRecognized(Str tag)
  {
    super.isRecognized(tag) ||
    ["null", "bool", "int", "float"].map |s| { "tag:yaml.org,2002:$s" }.contains(tag)
  }

  private const Regex matchNull  := Regex("null")
  private const Regex matchBool  := Regex("true|false")
  private const Regex matchInt   := Regex("-?(0|[1-9][0-9]*)")
  private const Regex matchFloat := Regex("-?(0|[1-9][0-9]*)(\\.[0-9]*)?([eE][-+]?[0-9]+)?")
}

**************************************************************************
** CoreSchema
**************************************************************************

** The default YamlSchema.
@NoDoc
const class CoreSchema : FailsafeSchema
{

//////////////////////////////////////////////////////////////////////////
// Encoding & decoding YamlObjs
//////////////////////////////////////////////////////////////////////////

  override Obj? decode(YamlObj node)
  {
    tag := node.tag

    if (!isRecognized(tag)) tag = assignTag(node)  // Assign tag
    else validate(node)                            // Validate tag

    // Create object
    if (super.isRecognized(tag)) return super.decode(node)

    cont := node.val as Str
    switch (tag)
    {
      case "tag:yaml.org,2002:null":
        return null

      case "tag:yaml.org,2002:bool":
        return cont.lower == "true"

      case "tag:yaml.org,2002:int":
        if (cont.size > 2 && cont[0..1] == "0o")
          return Int(cont[2..-1], 8)
        if (cont.size > 2 && cont[0..1] == "0x")
          return Int(cont[2..-1], 16)
        return Int(cont)

      case "tag:yaml.org,2002:float":
        if (cont.size > 3 && cont[-3..-1].lower == "inf")
          return cont[0] == '-' ? Float.negInf : Float.posInf
        if (cont.size > 3 && cont[-3..-1].lower == "nan")
          return Float.nan
        return Float(cont)

      default:
        throw Err("Internal error - all tags should have been covered.")
    }
  }

  override YamlObj encode(Obj? obj)
  {
    recEncode(obj) |v|
    {
      if      (v == Float.posInf) return YamlScalar(".Inf")
      else if (v == Float.negInf) return YamlScalar("-.Inf")
      else if (v is Float && v->isNaN) return YamlScalar(".NaN")
      else if (v == null ||
               v is Bool ||
               v is Int  ||
               v is Float)
        return YamlScalar(v == null ? "null" : v.toStr)
      else return YamlScalar(v.toStr, worksAsPlain(v.toStr) ? "?" : "!")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Inherited helper methods
//////////////////////////////////////////////////////////////////////////

  override Str assignTag(YamlObj node)
  {
    if (node.typeof != YamlScalar#)
      return super.assignTag(node)

    if (matchNull.matches(node.val))  return "tag:yaml.org,2002:null"
    if (matchBool.matches(node.val))  return "tag:yaml.org,2002:bool"
    if (matchInt.matches(node.val))   return "tag:yaml.org,2002:int"
    if (matchFloat.matches(node.val)) return "tag:yaml.org,2002:float"
    return "tag:yaml.org,2002:str"
  }

  override Void validate(YamlObj node)
  {
    if (super.isRecognized(node.tag)) super.validate(node)
    else
    {
      if (node.typeof != YamlScalar#)
        throw YamlTagErr(node.tag, YamlScalar#)

      switch (node.tag)
      {
        case "tag:yaml.org,2002:null":
          if (!matchNull.matches(node.val))
            throw YamlTagErr(node)

        case "tag:yaml.org,2002:bool":
          if (!matchBool.matches(node.val))
            throw YamlTagErr(node)

        case "tag:yaml.org,2002:int":
          if (!matchInt.matches(node.val))
            throw YamlTagErr(node)

        case "tag:yaml.org,2002:float":
          if (!matchFloat.matches(node.val))
            throw YamlTagErr(node)
      }
    }
  }

  override Bool isRecognized(Str tag)
  {
    super.isRecognized(tag) ||
    ["null", "bool", "int", "float"].map |s| { "tag:yaml.org,2002:$s" }.contains(tag)
  }

  private const Regex matchNull  := Regex("null|Null|NULL|~|(^\$)")
  private const Regex matchBool  := Regex("true|True|TRUE|false|False|FALSE")
  private const Regex matchInt   := Regex("([-+]?[0-9]+)|"  + // Base 10
                                          "(0o[0-7]+)|"     + // Base 8
                                          "(0x[0-9a-fA-F]+)") // Base 16
  private const Regex matchFloat := Regex("([-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?)|" + // Number
                                          "([-+]?(\\.inf|\\.Inf|\\.INF))|" +                           // Infinity
                                          "(\\.nan|\\.NaN|\\.NAN)")                                    // NaN
}