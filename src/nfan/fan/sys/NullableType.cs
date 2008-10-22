//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Oct 08  Andy Frank  Creation
//

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
      : base(root.m_pod, root.m_name, root.m_flags, root.m_facets)
    {
      m_signature = root.signature() + "?";
    }

  //////////////////////////////////////////////////////////////////////////
  // Type
  //////////////////////////////////////////////////////////////////////////

    public override Type @base() { return m_root.@base(); }

    public override List mixins() { return m_root.mixins(); }

    public override string signature() { return m_signature; }

    public override List inheritance() { return m_root.m_inheritance; }

    public override bool @is(Type type) { return m_root.@is(type); }

    public override Boolean isNullable() { return Boolean.True; }

    public override Type toNullable() { return this; }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Type m_root = null;
    private string m_signature;

  }
}