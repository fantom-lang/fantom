//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//    2 Jun 06  Brian Frank  Ported from Java to Fan
//

**
** VisitStep represents one discrete task run during the compiler
** pipeline.  The implementations are found under steps.
**
abstract class CompilerStep : CompilerSupport, Visitor
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor takes the associated Compiler
  **
  new make(Compiler compiler)
    : super(compiler)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Run the step
  **
  abstract Void run()

//////////////////////////////////////////////////////////////////////////
// Visitor
//////////////////////////////////////////////////////////////////////////

  Bool inStatic()
  {
    return curMethod == null || curMethod.isStatic
  }

  CompilationUnit? curUnit()
  {
    if (curType != null) return curType.unit
    if (curSymbol != null) return curSymbol.unit
    return null
  }

  override Void enterSymbolDef(SymbolDef def)
  {
    curSymbol = def
  }

  override Void exitSymbolDef(SymbolDef def)
  {
    curSymbol = null
  }

  override Void enterTypeDef(TypeDef def)
  {
    curType = def
  }

  override Void exitTypeDef(TypeDef def)
  {
    curType = null
  }

  override Void enterMethodDef(MethodDef def)
  {
    curMethod = def
  }

  override Void exitMethodDef(MethodDef def)
  {
    curMethod = null
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  TypeDef? curType
  MethodDef? curMethod
  SymbolDef? curSymbol
}