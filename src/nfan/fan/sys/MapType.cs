//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 06  Andy Frank  Creation
//

using System;
using System.Collections;

namespace Fan.Sys
{
  /// <summary>
  /// MapType is the GenericType for Maps: Foo:Bar -> K = Foo, V = Bar.
  /// </summary>
  public class MapType : GenericType
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public MapType(Type k, Type v) : base(Sys.MapType)
    {
      this.m_k = k;
      this.m_v = v;
    }

  //////////////////////////////////////////////////////////////////////////
  // Type
  //////////////////////////////////////////////////////////////////////////

    public override int GetHashCode() { return (int)hash(); }

    public override long hash() { return FanStr.hash(signature()); }

    public override bool Equals(object obj)
    {
      if (obj is MapType)
      {
        MapType x = (MapType)obj;
        return m_k.Equals(x.m_k) && m_v.Equals(x.m_v);
      }
      return false;
    }

    public override string signature()
    {
      if (m_sig == null)
      {
        m_sig = '[' + m_k.signature() + ':' + m_v.signature() + ']';
      }
      return m_sig;
    }

    public override bool @is(Type type)
    {
      if (type is MapType)
      {
        MapType t = (MapType)type;
        return m_k.@is(t.m_k) && m_v.@is(t.m_v);
      }
      return base.@is(type);
    }

    internal override Map makeParams()
    {
      return new Map(Sys.StrType, Sys.TypeType)
        .set("K", m_k)
        .set("V", m_v)
        .set("M", this).ro();
    }

  //////////////////////////////////////////////////////////////////////////
  // GenericType
  //////////////////////////////////////////////////////////////////////////

    public override Type getRawType()
    {
      return Sys.MapType;
    }

    public override bool isGenericParameter()
    {
      return m_v.isGenericParameter() && m_k.isGenericParameter();
    }

    protected override Type doParameterize(Type t)
    {
      if (t == Sys.KType) return m_k;
      if (t == Sys.VType) return m_v;
      if (t == Sys.MType) return this;
      throw new InvalidOperationException(t.ToString());
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public readonly Type m_k;
    public readonly Type m_v;
    private string m_sig;

  }
}