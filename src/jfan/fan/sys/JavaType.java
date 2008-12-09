//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Nov 08  Brian Frank  Creation
//
package fan.sys;

/**
 * JavaType wraps a Java class as a Fan type for FFI reflection.
 */
public class JavaType
  extends Type
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public JavaType(String podName, String typeName)
  {
    this.podName = podName;
    this.typeName = typeName;
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public Pod pod() { return null; }
  public String name() { return typeName; }
  public String qname() { return podName + "::" + typeName; }
  public String signature() { return qname(); }
  int flags() { throw unsupported(); }

  public Type base() { throw unsupported(); }
  public List mixins() { throw unsupported(); }
  public List inheritance() { throw unsupported(); }
  public boolean is(Type type) { throw unsupported(); }

  public boolean isValue() { return false; }

  public final boolean isNullable() { return false; }
  public final synchronized Type toNullable()
  {
    if (nullable == null) nullable = new NullableType(this);
    return nullable;
  }

  public List fields() { throw unsupported(); }
  public List methods() { throw unsupported(); }
  public List slots() { throw unsupported(); }
  public Slot slot(String name, boolean checked) { throw unsupported(); }

  public Map facets(boolean inherited) { return Facets.empty().map(); }
  public Object facet(String name, Object def, boolean inherited) { return Facets.empty().get(name, def); }

  public String doc() { return null; }

  public boolean javaRepr() { return true; }

  private RuntimeException unsupported() { return new UnsupportedOperationException(); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private String podName;
  private String typeName;
  private Type nullable;

}