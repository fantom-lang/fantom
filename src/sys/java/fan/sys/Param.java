//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

/**
 * Param represents one parameter definition of a Func (or Method).
 */
public class Param
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public Param(String name, Type type, int mask)
  {
    this.name = name;
    this.type = type;
    this.mask = mask;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.ParamType; }

  public String name()  { return name; }
  public Type type()   { return type; }
  public boolean hasDefault() { return (mask & HAS_DEFAULT) != 0; }

  public String toStr() { return type + " " + name; }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final int HAS_DEFAULT   = 0x01;  // is a default value provided

  final String name;
  final Type type;
  final int mask;

}