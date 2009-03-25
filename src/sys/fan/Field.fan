//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Jan 06  Brian Frank  Creation
//

**
** Field is a slot which models the ability to get and set a value.
**
const class Field : Slot
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Private constructor.
  **
  private new privateMake()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Type stored by the field.
  **
  Type of()

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the field for the specified instance.  If the field is
  ** static, then the instance parameter is ignored.  If the getter
  ** is non-null, then it is used to get the field.
  **
  virtual Obj? get(Obj? instance := null)

  **
  ** Set the field for the specified instance.  If the field is
  ** static, then the instance parameter is ignored.  If the setter
  ** is non-null, then it is used to set the field.
  **
  virtual Void set(Obj? instance, Obj? value)

}