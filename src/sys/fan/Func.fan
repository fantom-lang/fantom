//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 07  Brian Frank  Split from Method
//

**
** Func models an executable subroutine.  Functions are typed by a
** formal parameter list and return value (or Void if no return).
** Functions are typically defined as method slots on a type, but
** may also be defined via functional programming constructs such
** closures and the '&' operator.
**
** An immutable function is guaranteed to not capture any
** state from its thread, and is safe to execute on other threads.
** The compiler marks functions as immutable based on the following
** analysis:
**   - static methods are always automatically immutable
**   - instance methods on a const class are immutable
**   - instance methods on a non-const class are never immutable
**   - closures which don't capture any variables from their
**     scope are automatically immutable
**   - curried functions which only capture const variables
**     from their scope are automatically immutable
**
** See `docLang::Functions` for details.
**
final class Func
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Private constructor.
  **
  private new make()

//////////////////////////////////////////////////////////////////////////
// Signature
//////////////////////////////////////////////////////////////////////////

  **
  ** Type returned by the function or sys::Void if no return value.
  **
  Type returns()

  **
  ** Get the formal parameters of the function.
  **
  Param[] params()

  **
  ** Return the associated method if this function implements a
  ** method slot.  If this function a is curried method using the
  ** "&" operator method call syntax, it will return the associated
  ** method.  Otherwise return 'null'.
  **
  ** Examples:
  **   f := Int#plus.func
  **   f.method           =>  sys::Int.plus
  **   (&10.plus).method  =>  sys::Int.plus
  **   (&f(10)).method    =>  null
  **
  Method? method()

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  **
  ** Dynamically invoke this function with the specified arguments and return
  ** the result.  If the function has Void return type, then null is returned.
  ** The argument list must match the number and type of required parameters.
  ** If this function represents an instance method (not static and not a
  ** constructor) then the first argument must be the target object.  If the
  ** function supports default parameters, omit arguments to use the defaults.
  ** It is permissible to pass more arguments then the number of method
  ** parameters - the additional arguments are ignored.  If no arguments are
  ** required, you may pass null for args.
  **
  virtual R call(Obj?[]? args)

  **
  ** Convenience for dynamically invoking an instance method with
  ** specified target and arguments.  If this method maps to an
  ** instance method, then it is semantically equivalent to
  ** 'call([target, args[0], args[1] ...])'.  Throw UnsupportedErr
  ** if called on a function which is not an instance method.
  **
  virtual R callOn(Obj? target, Obj?[]? args)

  **
  ** Optimized convenience for call([,]).
  **
  virtual R call0()

  **
  ** Optimized convenience for call([a]).
  **
  virtual R call1(A a)

  **
  ** Optimized convenience for call([a, b]).
  **
  virtual R call2(A a, B b)

  **
  ** Optimized convenience for call([a, b, c]).
  **
  virtual R call3(A a, B b, C c)

  **
  ** Optimized convenience for call([a, b, c, d]).
  **
  virtual R call4(A a, B b, C c, D d)

  **
  ** Optimized convenience for call([a, b, c, d, e]).
  **
  virtual R call5(A a, B b, C c, D d, E e)

  **
  ** Optimized convenience for call([a, b, c, d, e, f]).
  **
  virtual R call6(A a, B b, C c, D d, E e, F f)

  **
  ** Optimized convenience for call([a, b, c, d, e, f, g]).
  **
  virtual R call7(A a, B b, C c, D d, E e, F f, G g)

  **
  ** Optimized convenience for call([a, b, c, d, e, f, g, h]).
  **
  virtual R call8(A a, B b, C c, D d, E e, F f, G g, H h)

  **
  ** Perform a functional curry by binding the specified
  ** arguments to this function's parameters.  Return a new
  ** function which takes the remaining unbound parameters.
  ** The '&' operator is used as a shortcut for currying.
  **
  Func curry(Obj?[] args)

  **
  ** If this function is immutable then return this,
  ** otherwise throw NotImmutableErr.
  **
  Func toImmutable()

}