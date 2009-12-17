//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Jul 06  Andy Frank  Creation
//

**
** HtmlDocTest is used for used for testing HTML generation
** for the docCompiler pod.
**
abstract class HtmlDocTest
{

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  //
  // normal
  //

  Void method_public() {}
  protected Void method_protected() {}
  private Void method_private() {}
  internal Void method_internal() {}

  //
  // overridding
  //

  abstract Void method_abstract()
  virtual Void method_virtual() {}

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  //
  // normal
  //

  Int field_public
  protected Int field_protected
  private Int field_private
  internal Int field_internal

  //
  // setters
  //

  Int field_publicGet_protectedSet { protected set }
  Int field_publicGet_privateSet { private set }
  protected Int field_protectedGet_privateSet { private set }
  internal Int field_internalGet_privateSet { private set }

  //
  // readonly
  //

  readonly Int field_public_readonly
  protected readonly Int field_protected_readonly
  internal readonly Int field_internal_readonly

  //
  // const
  //
  const Int field_public_const
  protected const Int field_protected_const
  internal const Int field_internal_const
  private const Int field_private_const

}