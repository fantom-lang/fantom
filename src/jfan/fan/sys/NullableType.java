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
    super(root.pod, root.name, root.flags, root.facets);
    this.signature = root.signature() + "?";
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public Type base() { return root.base(); }

  public List mixins() { return root.mixins(); }

  public String signature() { return signature; }

  public List inheritance() { return root.inheritance; }

  public boolean is(Type type) { return root.is(type); }

  public Boolean isNullable() { return true; }

  public Type toNullable() { return this; }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Type root;
  private String signature;

}