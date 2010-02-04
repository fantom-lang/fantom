//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Oct 08  Brian Frank  Creation
//
package fan.sys;

/**
 * NullableType wraps a type as nullable with trailing "?".
 */
public class NullableType
  extends Type
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  NullableType(Type root)
  {
    this.root = root;
    this.signature = root.signature() + "?";
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public long hash() { return root.hash() ^ 0x614a9739b1bf9de5L; }

  public boolean equals(Object obj)
  {
    if (obj instanceof NullableType)
    {
      NullableType x = (NullableType)obj;
      return root.equals(x.root);
    }
    return false;
  }

  public Pod pod() { return root.pod(); }
  public String name() { return root.name(); }
  public String qname() { return root.qname(); }
  public String signature() { return signature; }
  int flags() { return root.flags(); }

  public Type base() { return root.base(); }
  public List mixins() { return root.mixins(); }
  public List inheritance() { return root.inheritance(); }
  public boolean is(Type type) { return root.is(type); }

  public boolean isVal() { return root.isVal(); }

  public boolean isNullable() { return true; }
  public Type toNullable() { return this; }
  public Type toNonNullable() { return root; }

  public boolean isGenericType() { return root.isGenericType(); }
  public boolean isGenericInstance() { return root.isGenericInstance(); }
  public boolean isGenericParameter() { return root.isGenericParameter(); }
  public Type getRawType() { return root.getRawType(); }
  public Map params() { return root.params(); }
  public Type parameterize(Map params) { return root.parameterize(params).toNullable(); }

  public List fields() { return root.fields(); }
  public List methods() { return root.methods(); }
  public List slots() { return root.slots(); }
  public Slot slot(String name, boolean checked) { return root.slot(name, checked); }

  public List facets() { return root.facets(); }
  public Facet facet(Type t, boolean c) { return root.facet(t, c); }

  public String doc() { return root.doc(); }

  public boolean javaRepr() { return root.javaRepr(); }
  public Class toClass() { return root.toClass(); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final Type root;
  final String signature;
  private Type listOf;

}