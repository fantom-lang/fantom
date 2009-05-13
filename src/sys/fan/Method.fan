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
  ** Private constructor.
  **
  private new privateMake()

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

  ** Convenience for 'func.callList'
  Obj? callList(Obj?[]? args)

  ** Convenience for 'func.callOn'
  Obj? callOn(Obj? target, Obj[]? args)

  ** Convenience for 'func.call'
  Obj? call(Obj? a := null, Obj? b := null, Obj? c := null, Obj? d := null,
            Obj? e := null, Obj? f := null, Obj? g := null, Obj? h := null)

** TODO
Obj? call0()
Obj? call1(Obj? a)
Obj? call2(Obj? a, Obj? b)
Obj? call3(Obj? a, Obj? b, Obj? c)
Obj? call4(Obj? a, Obj? b, Obj? c, Obj? d)
Obj? call5(Obj? a, Obj? b, Obj? c, Obj? d, Obj? e)
Obj? call6(Obj? a, Obj? b, Obj? c, Obj? d, Obj? e, Obj? f)
Obj? call7(Obj? a, Obj? b, Obj? c, Obj? d, Obj? e, Obj? f, Obj? g)

}