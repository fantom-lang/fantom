//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// ListType is the GenericType for Lists: Foo[] -> V = Foo
  /// </summary>
  public class ListType : GenericType
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    internal ListType(Type v) : base(Sys.ListType)
    {
      this.m_v = v;
    }

  //////////////////////////////////////////////////////////////////////////
  // Type
  //////////////////////////////////////////////////////////////////////////

    public override int GetHashCode() { return (int)hash(); }

    public override long hash() { return FanStr.hash(signature()); }

    public override bool Equals(object obj)
    {
      if (obj is ListType)
      {
        return m_v.Equals(((ListType)obj).m_v);
      }
      return false;
    }

    public override string signature()
    {
      if (m_sig == null)
      {
        m_sig = m_v.signature() + "[]";
      }
      return m_sig;
    }

    public override bool @is(Type type)
    {
      if (type is ListType)
      {
        ListType t = (ListType)type;
        return m_v.@is(t.m_v);
      }
      return base.@is(type);
    }

    internal override Map makeParams()
    {
      return new Map(Sys.StrType, Sys.TypeType)
        .set("V", m_v)
        .set("L", this).ro();
    }

  //////////////////////////////////////////////////////////////////////////
  // GenericType
  //////////////////////////////////////////////////////////////////////////

    public override Type getRawType()
    {
      return Sys.ListType;
    }

    public override bool isGenericParameter()
    {
      return m_v.isGenericParameter();
    }

    protected override Type doParameterize(Type t)
    {
      if (t == Sys.VType) return m_v;
      if (t == Sys.LType) return this;
      throw new System.InvalidOperationException(t.ToString());
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public readonly Type m_v;
    private string m_sig;

  }
}