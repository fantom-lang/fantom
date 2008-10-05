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

  public Param(Str name, Type of, int mask)
  {
    this.name = name;
    this.of   = of;
    this.mask = mask;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.ParamType; }

  public Str name()  { return name; }
  public Type of()   { return of; }
  public Boolean hasDefault() { return (mask & HAS_DEFAULT) != 0; }

  public Str toStr() { return Str.make(of + " " + name); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final int HAS_DEFAULT   = 0x01;  // is a default value provided

  final Str name;
  final Type of;
  final int mask;

}