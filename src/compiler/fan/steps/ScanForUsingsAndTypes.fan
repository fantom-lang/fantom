//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 06  Brian Frank  Creation
//

**
** ScanForUsingsAndTypes is the first phase in a two pass parser.  Here
** we scan thru the tokens to parse using declarations and type definitions
** so that we can fully define the namespace of types.  The result of this
** step is to populate each CompilationUnit's using and types, and the
** PodDef.typeDefs map.
**
class ScanForUsingsAndTypes : CompilerStep
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
  override Void run()
  {
    log.debug("ScanForUsingsAndTypes")

    allTypes := Str:TypeDef[:]

    units.each |CompilationUnit unit|
    {
      UsingAndTypeScanner.make(compiler, unit, allTypes).parse
    }
    bombIfErr

    compiler.pod.typeDefs = allTypes
  }

}

**************************************************************************
** UsingAndTypeScanner
**************************************************************************

class UsingAndTypeScanner : CompilerSupport
{
  new make(Compiler compiler, CompilationUnit unit, Str:TypeDef allTypes)
    : super(compiler)
  {
    this.unit     = unit
    this.tokens   = unit.tokens
    this.pos      = 0
    this.allTypes = allTypes
    this.isSys    = compiler.isSys
  }

  Void parse()
  {
    // sys is imported implicitly (unless this is sys itself)
    if (!isSys)
      unit.usings.add(Using.make(unit.location, "sys"))

    // scan tokens quickly looking for keywords
    inClassHeader := false
    while (true)
    {
      tok := consume
      if (tok.kind === Token.eof) break
      switch (tok.kind)
      {
        case Token.usingKeyword:
          parseUsing(tok)
        case Token.lbrace:
          inClassHeader = false
        case Token.classKeyword:
        case Token.mixinKeyword:
        case Token.enumKeyword:
          if (!inClassHeader)
          {
            inClassHeader = true;
            parseType(tok);
          }
      }
    }
  }

  private Void parseUsing(TokenVal tok)
  {
    imp := Using.make(tok, consumeId)
    if (curt === Token.doubleColon)
    {
      consume
      imp.typeName = consumeId
      if (curt === Token.asKeyword)
      {
        consume
        imp.asName = consumeId
      }
    }
    unit.usings.add(imp)
  }

  private Void parseType(TokenVal tok)
  {
    name := consumeId
    typeDef := TypeDef.make(ns, tok, unit, name)
    unit.types.add(typeDef)

    // set enum/mixin flag to use by Parser
    if (tok.kind === Token.mixinKeyword)
      typeDef.flags |= FConst.Mixin
    else if (tok.kind === Token.enumKeyword)
      typeDef.flags |= FConst.Enum

    // check for duplicate type names
    if (allTypes.containsKey(name))
      err("Duplicate type name '$name'", typeDef.location)
    else
      allTypes[name] = typeDef
  }

  private Str consumeId()
  {
    id := consume
    if (id.kind != Token.identifier)
    {
      err("Expected identifier", id)
      return ""
    }
    return (Str)id.val
  }

  private TokenVal consume()
  {
    return tokens[pos++]
  }

  private Token curt()
  {
    return tokens[pos].kind
  }

  private CompilationUnit unit
  private TokenVal[] tokens
  private Int pos
  private Bool isSys := false
  private Str:TypeDef allTypes

}