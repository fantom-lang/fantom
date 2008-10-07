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

  public Pod pod() { return root.pod(); }
  public String name() { return root.name(); }
  public String qname() { return root.qname(); }
  public String signature() { return signature; }
  int flags() { return root.flags(); }

  public Type base() { return root.base(); }
  public List mixins() { return root.mixins(); }
  public List inheritance() { return root.inheritance(); }
  public boolean is(Type type) { return root.is(type); }

  public Boolean isNullable() { return true; }
  protected Type makeToNullable() { return this; }

  protected Type makeToListOf() { return new ListType(root).toNullable(); }

  public List fields() { return root.fields(); }
  public List methods() { return root.methods(); }
  public List slots() { return root.slots(); }
  public Slot slot(String name, boolean checked) { return root.slot(name, checked); }

  public Map facets(Boolean inherited) { return root.facets(inherited); }
  public Object facet(String name, Object def, Boolean inherited) { return root.facet(name, def, inherited); }

  public String doc() { return root.doc(); }

  public boolean javaRepr() { return root.javaRepr(); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final Type root;
  final String signature;
  private Type listOf;

}