//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 09  Andy Frank  Creation
//

/**
 * TypeParser is used to parser formal type signatures which are
 * used in Sys.type() and in fcode for typeRefs.def.  Signatures
 * are formated as (with arbitrary nesting):
 *
 *   x::N
 *   x::V[]
 *   x::V[x::K]
 *   |x::A, ... -> x::R|
 */
var fanx_TypeParser = Class.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function(sig, checked)
  {
    this.sig        = sig;
    this.len        = sig.length;
    this.pos        = 0;
    this.cur        = sig.charAt(this.pos);
    this.peek       = sig.charAt(this.pos+1);
    this.checked    = checked;
  },

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  loadTop: function()
  {
    var type = this.load();
    if (this.cur != 0) throw this.err();
    return type;
  },

  load: function()
  {
    var type;

    // |...| is func
    if (this.cur == '|')
      type = this.loadFunc();

    // [java] is java FFI
    else if (this.cur == '[' && this.sig.indexOf("[java]") != -1) //sig.regionMatches(pos, "[java]", 0, 6))
      //type = loadFFI();
      throw sys_ArgErr.make("Java types not allowed '" + this.sig + "'");

    // [...] is map
    else if (this.cur == '[')
      type = this.loadMap();

    // otherwise must be basic[]
    else
      type = this.loadBasic();

    // nullable
    if (this.cur == '?')
    {
      this.consume('?');
      type = type.toNullable();
    }

    // anything left must be []
    while (this.cur == '[')
    {
      this.consume('[');
      this.consume(']');
      type = type.toListOf();
    }

    // nullable
    if (this.cur == '?')
    {
      this.consume('?');
      type = type.toNullable();
    }

    return type;
  },

  loadMap: function()
  {
    this.consume('[');
    var key = this.load();
    this.consume(':');
    var val = this.load();
    this.consume(']');
    return new sys_MapType(key, val);
  },

  loadFunc: function()
  {
    this.consume('|');
    var params = [];
    if (this.cur != '-')
    {
      while (true)
      {
        params.push(this.load());
        if (this.cur == '-') break;
        this.consume(',');
      }
    }
    this.consume('-');
    this.consume('>');
    var ret = this.load();
    this.consume('|');

    return new sys_FuncType(params, ret);
  },

  loadBasic: function()
  {
    var podName = this.consumeId();
    this.consume(':');
    this.consume(':');
    var typeName = this.consumeId();

    // check for generic parameter like sys::V
    if (typeName.length == 1 && podName == "sys")
    {
      //var type = Sys.genericParameterType(typeName);
      //if (type != null) return type;
throw sys_Err.make("TODO - generic paramaters");
    }

    return fanx_TypeParser.find(podName, typeName, this.checked);
  },

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  consumeId: function()
  {
    var start = this.pos;
    while (this.isIdChar(this.cur)) this.consume();
    return this.sig.substring(start, this.pos);
  },

  isIdChar: function(ch)
  {
    return sys_Int.isAlphaNum(ch.charCodeAt(0)) || ch == '_';
  },

  consume: function(expected)
  {
    if (this.cur != expected) throw this.err();
    this.consume();
  },

  consume: function()
  {
    this.cur = this.peek;
    this.pos++;
    this.peek = this.pos+1 < this.len ? this.sig.charAt(this.pos+1) : 0;
  },

  err: function(sig)
  {
    if (sig == undefined) sig = this.sig;
    return sys_ArgErr.make("Invalid type signature '" + sig + "'");
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  sig: null,       // signature being parsed
  len: 0,          // length of sig
  pos: 0,          // index of cur in sig
  cur: 0,          // cur character; sig[pos]
  peek: 0,         // next character; sig[pos+1]
  checked: true    // pass thru checked flag

});

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

/**
 * Parse the signature into a loaded type.
 */
fanx_TypeParser.load = function(sig, checked)
{
  // if last character is ?, then parse a nullable
  var len = sig.length;
  var last = len > 1 ? sig.charAt(len-1) : 0;
  if (last == '?')
    return fanx_TypeParser.load(sig.substring(0, len-1), checked).toNullable();

  // if the last character isn't ] or |, then this a non-generic
  // type and we don't even need to allocate a parser
  if (last != ']' && last != '|')
  {
    var podName;
    var typeName;
    try
    {
      var colon = sig.indexOf(":");
      if (sig.charAt(colon+1) != ':') throw new Exception();
      podName  = sig.substring(0, colon);
      typeName = sig.substring(colon+2);
      if (podName.length == 0 || typeName.length == 0) throw sys_Err.make("");
    }
    catch (err)
    {
      throw sys_ArgErr.make("Invalid type signature '" + sig + "', use <pod>::<type>");
    }

    // if podName starts with [java] this is a direct Java type
    if (podName.charAt(0) == '[')
      throw sys_ArgErr.make("Java types not allowed '" + sig + "'");

    // do a straight lookup
    return fanx_TypeParser.find(podName, typeName, checked);
  }

  // we got our work cut out for us - create parser
  try
  {
    return new fanx_TypeParser(sig, checked).loadTop();
  }
  catch (err)
  {
//println(err);
    throw sys_Err.make(err);
  }
}

fanx_TypeParser.find = function(podName, typeName, checked)
{
  var pod = sys_Pod.find(podName, checked);
  if (pod == null) return null;
  return pod.findType(typeName, checked);
}

