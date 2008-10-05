//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 06  Brian Frank  Creation
//
package fanx.util;

import java.util.*;
import fan.sys.*;

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
public class TypeParser
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  /**
   * Parse the signature into a loaded type.
   */
  public static Type load(String sig, boolean checked, Pod loadingPod)
  {
    // if the last character isn't ] or |, then this a non-generic
    // type and we don't even need to allocate a parser
    int last = sig.length() > 1 ? sig.charAt(sig.length()-1) : 0;
    if (last != ']' && last != '|')
    {
      String podName, typeName;
      try
      {
        int colon = sig.indexOf(':');
        if (sig.charAt(colon+1) != ':') throw new Exception();
        podName  = sig.substring(0, colon);
        typeName = sig.substring(colon+2);
        if (podName.length() == 0 || typeName.length() == 0) throw new Exception();
      }
      catch (Exception e)
      {
        throw ArgErr.make("Invalid type signature '" + sig + "', use <pod>::<type>").val;
      }
      if (loadingPod != null && podName.equals(loadingPod.name().val))
        return loadingPod.findType(typeName, checked);
      else
        return Type.find(podName, typeName, checked);
    }

    // we got our work cut out for us - create parser
    try
    {
      return new TypeParser(sig, checked, loadingPod).loadTop();
    }
    catch (Err.Val e)
    {
      throw e;
    }
    catch (Exception e)
    {
      throw err(sig).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  private TypeParser(String sig, boolean checked, Pod loadingPod)
  {
    this.sig        = sig;
    this.len        = sig.length();
    this.pos        = 0;
    this.cur        = sig.charAt(pos);
    this.peek       = sig.charAt(pos+1);
    this.checked    = checked;
    this.loadingPod = loadingPod;
  }

//////////////////////////////////////////////////////////////////////////
// Parse
//////////////////////////////////////////////////////////////////////////

  private Type loadTop()
  {
    Type type = load();
    if (cur != 0) throw err().val;
    return type;
  }

  private Type load()
  {
    Type type;

    // |...| is func
    if (cur == '|')
      type = loadFunc();

    // [...] is map
    else if (cur == '[')
      type = loadMap();

    // otherwise must be basic[]
    else
      type = loadBasic();

    // anything left must be []
    while (cur == '[')
    {
      consume('[');
      consume(']');
      type = type.toListOf();
    }

    return type;
  }

  private Type loadMap()
  {
    consume('[');
    Type key = load();
    consume(':');
    Type val = load();
    consume(']');
    return new MapType(key, val);
  }

  private Type loadFunc()
  {
    consume('|');
    ArrayList params = new ArrayList(8);
    if (cur != '-')
    {
      while (true)
      {
        params.add(load());
        if (cur == '-') break;
        consume(',');
      }
    }
    consume('-');
    consume('>');
    Type ret = load();
    consume('|');

    return new FuncType((Type[])params.toArray(new Type[params.size()]), ret);
  }

  private Type loadBasic()
  {
    String podName = consumeId();
    consume(':');
    consume(':');
    String typeName = consumeId();

    // check for generic parameter like sys::V
    if (typeName.length() == 1 && podName.equals("sys"))
    {
      Type type = Sys.genericParameterType(typeName);
      if (type != null) return type;
    }

    if (loadingPod != null && podName.equals(loadingPod.name().val))
      return loadingPod.findType(typeName, checked);
    else
      return Type.find(podName, typeName, checked);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private String consumeId()
  {
    int start = pos;
    while (isIdChar(cur)) consume();
    return sig.substring(start, pos);
  }

  public static boolean isIdChar(int ch)
  {
    return FanInt.isAlphaNum(ch) || ch == '_';
  }

  private void consume(int expected)
  {
    if (cur != expected) throw err().val;
    consume();
  }

  private void consume()
  {
    cur = peek;
    pos++;
    peek = pos+1 < len ? sig.charAt(pos+1) : 0;
  }

  private Err err() { return err(sig); }
  private static Err err(String sig)
  {
    return ArgErr.make("Invalid type signature '" + sig + "'");
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private String sig;          // signature being parsed
  private int len;             // length of sig
  private int pos;             // index of cur in sig
  private int cur;             // cur character; sig[pos]
  private int peek;            // next character; sig[pos+1]
  private boolean checked;     // pass thru checked flag
  private Pod loadingPod;      // used to map types within a loading pod

}
