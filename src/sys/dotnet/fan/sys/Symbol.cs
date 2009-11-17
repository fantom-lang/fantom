//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 09  Brian Frank  Creation (Java)
//   19 Jul 09  Brian Frank  Port to C#
//

using System;
using Fanx.Fcode;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// Symbol is a qualified name/value pair.
  /// </summary>
  public sealed class Symbol : FanObj, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Find
  //////////////////////////////////////////////////////////////////////////

    public static Symbol find(string qname) { return find(qname, true); }
    public static Symbol find(string qname, bool check)
    {
      string podName, name;
      try
      {
        int colon = qname.IndexOf(':');
        if (qname[colon+1] != ':') throw new Exception();
        podName = qname.Substring(0, colon);
        name = qname.Substring(colon+2);
      }
      catch (Exception)
      {
        throw Err.make("Invalid symbol qname \"" + qname + "\", use <pod>::<name>").val;
      }
      Pod pod = Pod.find(podName, check);
      if (pod == null) return null;
      return pod.symbol(name, check);
    }

  //////////////////////////////////////////////////////////////////////////
  // Java Constructor
  //////////////////////////////////////////////////////////////////////////

    public Symbol(Pod pod, FSymbol fsymbol)
    {
      this.m_pod    = pod;
      this.m_name   = pod.fpod.name(fsymbol.name);
      this.m_qname  = pod.name() + "::" + m_name;
      this.m_of     = pod.findType(fsymbol.of);
      this.m_flags  = fsymbol.flags;
      this.m_defVal = initVal(fsymbol.val);
    }

  //////////////////////////////////////////////////////////////////////////
  // Symbol Methods
  //////////////////////////////////////////////////////////////////////////

    public Pod pod() { return m_pod; }

    public string qname() { return m_qname; }

    public string name() { return m_name; }

    public Type of() { return m_of; }

    public bool isVirtual() { return (m_flags & FConst.Virtual) != 0; }

    public override long hash()  { return m_qname.GetHashCode(); }

    public override int GetHashCode() { return m_qname.GetHashCode(); }

    public override bool Equals(object that)  { return this == that; }

    public override string toStr()  { return "@" + m_qname;  }

    public override Type type()  { return Sys.SymbolType;  }

  //////////////////////////////////////////////////////////////////////////
  // Value Management
  //////////////////////////////////////////////////////////////////////////

    public object val() { return defVal(); }

    public object defVal()
    {
      // if already decoded return it
      if (!(m_defVal is EncodedVal)) return m_defVal;

      // decode value
      object result = decodeVal((EncodedVal)m_defVal);

      // if immutable we can cache it
      if (FanObj.isImmutable(result)) m_defVal = result;

      return result;
    }

    /**
     * Convert fcode utf string into a symbol or facet value.
     * objects which are easy to detect as immutable we immediately
     * decode, others are stored via an EncodedVal wrapper.
     */
    public static object initVal(string str)
    {
      try
      {
        int ch = str[0];
        if (ch == '"' || ch == '`' || '0' <= ch && ch <= '9')
          return ObjDecoder.decode(str);
      }
      catch (Exception e)
      {
        System.Console.WriteLine("Symbol.initVal: " + str);
        Err.dumpStack(e);
      }
      return new EncodedVal(str);
    }

    /**
     * Given an immutable object or EncodedVal object return
     * its Fantom object value.  If the value is immutable then it
     * should be cached for future use.
     */
    public static object decodeVal(EncodedVal encodedVal)
    {
      // decode into an object
      object obj = ObjDecoder.decode(encodedVal.str);

      // if list or map try to make it immutable for caching
      try
      {
        if (obj is List) obj = ((List)obj).toImmutable();
        else if (obj is Map) obj = ((Map)obj).toImmutable();
      }
      catch (NotImmutableErr.Val) {}

      // this object is not safe for caching
      return obj;
    }

    public class EncodedVal
    {
      public EncodedVal(string str) { this.str = str; }
      public override string ToString() { return str; }
      public string str;
    }

  //////////////////////////////////////////////////////////////////////////
  // Documentation
  //////////////////////////////////////////////////////////////////////////

    public string doc()
    {
      m_pod.doc();  // ensure parent pod has loaded documentation
      return m_doc;
    }

  //////////////////////////////////////////////////////////////////////////
  // Literal
  //////////////////////////////////////////////////////////////////////////

    public void encode(ObjEncoder @out)
    {
      @out.w("@").w(m_qname);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    Pod m_pod;
    string m_name;
    string m_qname;
    Type m_of;
    int m_flags;
    object m_defVal;  // immutable object or EncodedVal
    public string m_doc;

  }
}