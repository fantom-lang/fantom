//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Oct 08  Andy Frank  Creation
//

using System.Runtime.CompilerServices;

namespace Fan.Sys
{
  /// <summary>
  /// NullableType wraps a type as nullable with trailing "?".
  /// </summary>
  public class NullableType : Type
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    internal NullableType(Type root)
    {
      m_root = root;
      m_signature = root.signature() + "?";
    }

  //////////////////////////////////////////////////////////////////////////
  // Type
  //////////////////////////////////////////////////////////////////////////

    public override Pod pod() { return m_root.pod(); }
    public override string name() { return m_root.name(); }
    public override string qname() { return m_root.qname(); }
    public override string signature() { return m_signature; }
    internal override int flags() { return m_root.flags(); }

    public override Type @base() { return m_root.@base(); }
    public override List mixins() { return m_root.mixins(); }
    public override List inheritance() { return m_root.inheritance(); }
    public override bool @is(Type type) { return m_root.@is(type); }

    public override Boolean isNullable() { return Boolean.True; }
    public override Type toNullable() { return this; }
    public override Type toNonNullable() { return m_root; }

    public override bool isGenericType() { return m_root.isGenericType(); }
    public override bool isGenericInstance() { return m_root.isGenericInstance(); }
    public override bool isGenericParameter() { return m_root.isGenericParameter(); }
    public override Type getRawType() { return m_root.getRawType(); }
    public override Map @params() { return m_root.@params(); }
    public override Type parameterize(Map pars) { return m_root.parameterize(pars).toNullable(); }

    public override Boolean isDynamic() { return Boolean.False; }

    public override List fields() { return m_root.fields(); }
    public override List methods() { return m_root.methods(); }
    public override List slots() { return m_root.slots(); }
    public override Slot slot(string name, bool check) { return m_root.slot(name, check); }

    public override Map facets(Boolean inherited) { return m_root.facets(inherited); }
    public override object facet(string name, object def, Boolean inherited) { return m_root.facet(name, def, inherited); }

    public override string doc() { return m_root.doc(); }

    public override bool netRepr() { return m_root.netRepr(); }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal readonly Type m_root;
    internal readonly string m_signature;

  }
}