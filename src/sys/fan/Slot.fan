//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//

**
** Slot represents a member field or method on a Type.
**
abstract const class Slot
{

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  **
  ** Find a Slot by it's qualified name "pod::Type.slot".  If the slot
  ** doesn't exist and checked is false then return null, otherwise
  ** throw UnknownSlotErr.
  **
  static Slot? find(Str qname, Bool checked := true)

  **
  ** Convenience for '(Method)find(qname, checked)'
  **
  static Method? findMethod(Str qname, Bool checked := true)

  **
  ** Convenience for '(Field)find(qname, checked)'
  **
  static Field? findField(Str qname, Bool checked := true)

  **
  ** Convenience for 'findMethod(qname, checked).func'
  **
  static Func? findFunc(Str qname, Bool checked := true)

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Internal constructor.
  **
  internal new make()

//////////////////////////////////////////////////////////////////////////
// Naming
//////////////////////////////////////////////////////////////////////////

  **
  ** Parent type which defines this slot.
  **
  Type parent()

  **
  ** Simple name of the slot such as "size".
  **
  Str name()

  **
  ** Qualified name such as "sys:Str.size".
  **
  Str qname()

  **
  ** Return true if this is an instance of Field.
  **
  Bool isField()

  **
  ** Return true if this is an instance of Method.
  **
  Bool isMethod()

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if slot is abstract (no implementation provided).
  **
  Bool isAbstract()

  **
  ** Return if slot is constant and thread safe.  A constant field
  ** is explicitly marked with the const modifier and guaranteed
  ** to always reference the same immutable object for the life of
  ** the VM.  A const method is guaranteed to not capture any
  ** state from its thread, and is safe to execute on other threads.
  ** The compiler marks methods as const based on the following
  ** analysis:
  **   - static methods are always automatically const
  **   - instance methods are never const
  **   - closures which don't capture any variables from their
  **     scope are automatically const
  **   - partional apply methods which only capture const variables
  **     from their scope are automatically const
  **
  Bool isConst()

  **
  ** Return if slot is constructor method.
  **
  Bool isCtor()

  **
  ** Return if slot has internal protection scope.
  **
  Bool isInternal()

  **
  ** Return if slot is native.
  **
  Bool isNative()

  **
  ** Return if slot is an override (of parent's virtual method).
  **
  Bool isOverride()

  **
  ** Return if slot has private protection scope.
  **
  Bool isPrivate()

  **
  ** Return if slot has protected protection scope.
  **
  Bool isProtected()

  **
  ** Return if slot has public protection scope.
  **
  Bool isPublic()

  **
  ** Return if slot is static (class based, rather than instance).
  **
  Bool isStatic()

  **
  ** Return if this slot was generated by the compiler.
  **
  Bool isSynthetic()

  **
  ** Return if slot is virtual (may be overridden in subclasses).
  **
  Bool isVirtual()

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  **
  ** Return all the facets defined for this slot or an empty map
  ** if no facets are defined.  If looking up a facet by name, then
  ** use the `facet` method which will provide better performance.
  ** See the [Facets Doc]`docLang::Facets` for details.
  **
  Str:Obj facets()

  **
  ** Get a facet by symbol key, or return the 'def' is the facet is not
  ** defined. See the [Facets Doc]`docLang::Facets` for details.
  **
  Obj? facet(Symbol key, Obj? def := null)

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the raw fandoc for this slot or null if not available.
  ** If there is additional documentation meta-data available it is
  ** included an the start of the string as a series of "@name=value"
  ** lines.
  **
  Str? doc()

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  **
  ** Always return qname().
  **
  override Str toStr()

  **
  ** Return a string representation of the Fan code signature.
  **
  virtual Str signature()

}