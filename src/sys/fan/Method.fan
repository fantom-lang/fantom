//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Jan 06  Brian Frank  Creation
//

**
** Method models a function with a formal parameter list and
** return value (or Void if no return).
**
const class Method : Slot
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Dynamic slot constructor.  Dynamic methods take an implementation
  ** function which defines the return type and parameters of the method.
  **
  public new make(Str name, Func func, Str:Obj facets := null)

//////////////////////////////////////////////////////////////////////////
// Signature
//////////////////////////////////////////////////////////////////////////

  **
  ** Type returned by the method or sys::Void if no return value.
  ** Convenience for 'func.returns'.
  **
  Type returns()

  **
  ** Get the parameters of the method.
  ** Convenience for 'func.params'.
  **
  Param[] params()

  **
  ** Get the function body of this method.
  **
  Func func()

//////////////////////////////////////////////////////////////////////////
// Call Conveniences
//////////////////////////////////////////////////////////////////////////

  ** Convenience for 'func.call'
  Obj call(Obj[] args)

  ** Convenience for 'func.callOn'
  Obj callOn(Obj target, Obj[] args)

  ** Convenience for 'func.call0'
  Obj call0()

  ** Convenience for 'func.call1'
  Obj call1(Obj a)

  ** Convenience for 'func.call2'
  Obj call2(Obj a, Obj b)

  ** Convenience for 'func.call3'
  Obj call3(Obj a, Obj b, Obj c)

  ** Convenience for 'func.call4'
  Obj call4(Obj a, Obj b, Obj c, Obj d)

  ** Convenience for 'func.call5'
  Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e)

  ** Convenience for 'func.call6'
  Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f)

  ** Convenience for 'func.call7'
  Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g)

  ** Convenience for 'func.call8'
  Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h)

}