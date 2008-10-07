//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//    6 Jun 06  Brian Frank  Ported from Java to Fan
//

**
** Parser is responsible for parsing a list of tokens into the
** abstract syntax tree.  At this point the CompilationUnit, Usings,
** and TypeDefs are already populated by the ScanForUsingAndTypes
** step.
**
public class Parser : CompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct the parser for the specified compilation unit.
  **
  new make(Compiler compiler, CompilationUnit unit, ClosureExpr[] closures)
    : super(compiler)
  {
    this.unit        = unit
    this.tokens      = unit.tokens
    this.numTokens   = unit.tokens.size
    this.closures    = closures
    if (compiler != null) this.isSys = compiler.isSys
    reset(0)
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Top level parse a compilation unit:
  **
  **   <compilationUnit>  :=  [<usings>] <typeDef>*
  **
  Void parse()
  {
    usings
    while (curt !== Token.eof) typeDef
  }

//////////////////////////////////////////////////////////////////////////
// Usings
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse <using>* - note that we are just skipping them because
  ** they are already parsed by ScanForUsingsAndTypes.
  **
  **   <using>     :=  <usingPod> | <usingType> | <usingAs>
  **   <usingPod>  :=  "using" <id> <eos>
  **   <usingType> :=  "using" <id> "::" <id> <eos>
  **   <usingAs>   :=  "using" <id> "::" <id> "as" <id> <eos>
  **
  private Void usings()
  {
    while (curt == Token.usingKeyword)
    {
      consume
      consumeId
      if (curt === Token.doubleColon)
      {
        consume
        consumeId
        if (curt === Token.asKeyword)
        {
          consume
          consumeId
        }
      }
      endOfStmt
    }
  }

//////////////////////////////////////////////////////////////////////////
// TypeDef
//////////////////////////////////////////////////////////////////////////

  **
  ** TypeDef:
  **   <typeDef>      :=  <classDef> | <mixinDef> | <enumDef>
  **
  **   <classDef>     :=  <classHeader> <classBody>
  **   <classHeader>  :=  [<doc>] <facets> <typeFlags> "class" [<inheritance>]
  **   <classFlags>   :=  [<protection>] ["abstract"] ["final"]
  **   <classBody>    :=  "{" <slotDefs> "}"
  **
  **   <enumDef>      :=  <enumHeader> <enumBody>
  **   <enumHeader>   :=  [<doc>] <facets> <protection> "enum" [<inheritance>]
  **   <enumBody>     :=  "{" <enumDefs> <slotDefs> "}"
  **
  **   <mixinDef>     :=  <enumHeader> <enumBody>
  **   <mixinHeader>  :=  [<doc>] <facets> <protection> "mixin" [<inheritance>]
  **   <mixinBody>    :=  "{" <slotDefs> "}"
  **
  **   <protection>   :=  "public" | "protected" | "private" | "internal"
  **   <inheritance>  :=  ":" <typeList>
  **
  Void typeDef()
  {
    // [<doc>]
    doc := doc()
    if (curt === Token.eof) return

    // <facets>
    facets := facets()

    // <flags>
    flags := flags(false)
    if (flags & ~ProtectionMask == 0) flags |= FConst.Public

    // local working variables
    loc     := cur
    isMixin := false
    isEnum  := false

    // mixin, enum, or class
    if (curt === Token.mixinKeyword)
    {
      if (flags & FConst.Abstract != 0) err("The 'abstract' modifier is implied on mixin", loc)
      if (flags & FConst.Const != 0) err("Cannot use 'const' modifier on mixin", loc)
      if (flags & FConst.Final != 0) err("Cannot use 'final' modifier on mixin", loc)
      flags |= FConst.Mixin | FConst.Abstract
      isMixin = true
      consume
    }
    else if (curt === Token.enumKeyword)
    {
      if (flags & FConst.Const != 0) err("The 'const' modifier is implied on enum", loc)
      if (flags & FConst.Final != 0) err("The 'final' modifier is implied on enum", loc)
      if (flags & FConst.Abstract != 0) err("Cannot use 'abstract' modifier on enum", loc)
      flags |= FConst.Enum | FConst.Const | FConst.Final
      isEnum = true
      consume
    }
    else
    {
      consume(Token.classKeyword)
    }

    // name
    name := consumeId
    // lookup TypeDef
    def := unit.types.find |TypeDef def->Bool| { return def.name == name }
    if (def == null) throw err("Invalid class definition", cur)

    // populate it's doc, facets, and flags
    def.doc    = doc
    def.facets = facets
    def.flags  = flags

    // inheritance
    if (curt === Token.colon)
    {
      // first inheritance type can be extends or mixin
      consume
      first := typeRef
      if (!first.isMixin)
        def.base = first
      else
        def.mixins.add(first)

      // additional mixins
      while (curt === Token.comma)
      {
        consume
        def.mixins.add(typeRef)
      }
    }

    // if no inheritance specified then apply default base class
    if (def.base == null)
    {
      def.baseSpecified = false
      if (isEnum)
        def.base = ns.enumType
      else if (def.qname != "sys::Obj")
        def.base = ns.objType
    }

    // start class body
    consume(Token.lbrace)

    // if enum, parse values
    if (isEnum) enumDefs(def)

    // slots
    curType = def
    closureCount = 0
    while (true)
    {
      doc = this.doc
      if (curt === Token.rbrace) break
      slot := slotDef(def, doc)

      // do duplicate name error checking here
      if (def.hasSlotDef(slot.name))
      {
        err("Duplicate slot name '$slot.name'", slot.location)
      }
      else
      {
        def.addSlot(slot)
      }
    }
    closureCount = null
    curType = null

    // end of class body
    consume(Token.rbrace)
  }

  private Void mixins(TypeDef def)
  {
    consume  // extends or mixin
    def.mixins.add(typeRef)
    while (curt === Token.comma)
    {
      consume
      def.mixins.add(typeRef)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse any list of flags in any order, we will check invalid
  ** combinations in the CheckErrors step.
  **
  private Int flags(Bool normalize := true)
  {
    loc := cur
    flags := 0
    protection := false
    for (done := false; !done; )
    {
      oldFlags := flags
      switch (curt)
      {
        case Token.abstractKeyword:  flags |= FConst.Abstract
        case Token.constKeyword:     flags |= FConst.Const
        case Token.finalKeyword:     flags |= FConst.Final
        case Token.internalKeyword:  flags |= FConst.Internal;  protection = true
        case Token.nativeKeyword:    flags |= FConst.Native
        case Token.newKeyword:       flags |= FConst.Ctor
        case Token.onceKeyword:      flags |= Once // Parser only flag
        case Token.overrideKeyword:  flags |= FConst.Override
        case Token.privateKeyword:   flags |= FConst.Private;   protection = true
        case Token.protectedKeyword: flags |= FConst.Protected; protection = true
        case Token.publicKeyword:    flags |= FConst.Public;    protection = true
        case Token.readonlyKeyword:  flags |= Readonly // Parser only flag
        case Token.staticKeyword:    flags |= FConst.Static
        case Token.virtualKeyword:   flags |= FConst.Virtual
        default:                     done = true
      }
      if (done) break
      if (oldFlags == flags) err("Repeated modifier")
      oldFlags = flags
      consume
    }

    if ((flags & FConst.Abstract !== 0) && (flags & FConst.Virtual !== 0))
      err("Abstract implies virtual", loc)
    if ((flags & FConst.Override !== 0) && (flags & FConst.Virtual !== 0))
      err("Override implies virtual", loc)

    if (normalize)
    {
      if (!protection) flags |= FConst.Public
      if (flags & FConst.Abstract !== 0) flags |= FConst.Virtual
      if (flags & FConst.Override !== 0)
      {
        if (flags & FConst.Final !== 0)
          flags &= ~FConst.Final
        else
          flags |= FConst.Virtual
      }
    }

    return flags
  }

//////////////////////////////////////////////////////////////////////////
// Enum
//////////////////////////////////////////////////////////////////////////

  **
  ** Enum definition list:
  **   <enumDefs>  :=  <enumDef> ("," <enumDef>)* <eos>
  **
  private Void enumDefs(TypeDef def)
  {
    ordinal := 0
    def.enumDefs.add(enumDef(ordinal++))
    while (curt === Token.comma)
    {
      consume
      def.enumDefs.add(enumDef(ordinal++))
    }
    endOfStmt
  }

  **
  ** Enum definition:
  **   <enumDef>  :=  <id> ["(" <args> ")"]
  **
  private EnumDef enumDef(Int ordinal)
  {
    doc := doc()

    def := EnumDef.make(cur)
    def.doc = doc
    def.ordinal = ordinal
    def.name = consumeId

    // optional ctor args
    if (curt === Token.lparen)
    {
      consume(Token.lparen)
      if (curt != Token.rparen)
      {
        while (true)
        {
          def.ctorArgs.add( expr )
          if (curt === Token.rparen) break
          consume(Token.comma);
        }
      }
      consume(Token.rparen)
    }

    return def
  }

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  **
  ** Slot definition:
  **   <slotDef> :=  <fieldDef> | <methodDef> | <ctorDef>
  **
  private SlotDef slotDef(TypeDef parent, Str[] doc)
  {
    // check for static {} class initialization
    if (curt === Token.staticKeyword && peekt === Token.lbrace)
    {
      location := cur
      consume
      curMethod = MethodDef.makeStaticInit(location, parent, null)
      curMethod.code = block(true)
      return curMethod
    }

    // all members start with facets, flags
    loc := cur
    facets := facets()
    flags := flags()

    // check if this is a Java style constructor, log error and parse like Fan sytle ctor
    if (curt === Token.identifier && cur.val == parent.name && peekt == Token.lparen)
    {
      err("Invalid constructor syntax - use new keyword")
      return methodDef(loc, parent, doc, facets, flags|FConst.Ctor, TypeRef.make(loc, ns.voidType), consumeId)
    }

    // check for inferred typed field
    // if = used rather than := then fieldDef() will log error
    if (curt === Token.identifier && (peekt === Token.defAssign || peekt === Token.assign))
    {
      name := consumeId
      return fieldDef(loc, parent, doc, facets, flags, null, name)
    }

    // check for constructor
    if (flags & FConst.Ctor !== 0)
    {
      name := consumeId
      return methodDef(loc, parent, doc, facets, flags, TypeRef.make(loc, ns.voidType), name)
    }

    // otherwise must be field or method
    type := typeRef
    name := consumeId
    if (curt === Token.lparen)
    {
      return methodDef(loc, parent, doc, facets, flags, type, name)
    }
    else
    {
      return fieldDef(loc, parent, doc, facets, flags, type, name)
    }
  }

//////////////////////////////////////////////////////////////////////////
// FieldDef
//////////////////////////////////////////////////////////////////////////

  **
  ** Field definition:
  **   <fieldDef>     :=  <facets> <fieldFlags> [<type>] <id> [":=" <expr>]
  **                      [ "{" [<fieldGetter>] [<fieldSetter>] "}" ] <eos>
  **   <fieldFlags>   :=  [<protection>] ["readonly"] ["static"]
  **   <fieldGetter>  :=  "get" (<eos> | <block>)
  **   <fieldSetter>  :=  <protection> "set" (<eos> | <block>)
  **
  private FieldDef fieldDef(Location loc, TypeDef parent, Str[] doc, Str:FacetDef facets, Int flags, TypeRef type, Str name)
  {
    // define field itself
    field := FieldDef.make(loc, parent)
    field.doc       = doc
    field.facets    = facets
    field.flags     = flags & ~ParserFlagsMask
    field.fieldType = type
    field.name      = name

    // const always has storage, otherwise assume no storage
    // until proved otherwise in ResolveExpr step or we
    // auto-generate getters/setters
    if (field.isConst)
      field.flags |= FConst.Storage

    // field initializer
    if (curt === Token.defAssign || curt === Token.assign)
    {
      if (curt === Token.assign) err("Must use := for field initialization")
      consume
      inFieldInit = true
      field.init = field.initDoc = expr
      inFieldInit = false
    }

    // disable type inference for now - doing inference for literals is
    // pretty trivial, but other types is tricky;  I'm not sure it is such
    // a hot idea anyways so it may just stay disabled forever
    if (type == null)
      err("Type inference not supported for fields", loc)

    // if not const, define getter/setter methods
    if (!field.isConst) defGetAndSet(field)

    // explicit getter or setter
    if (curt === Token.lbrace)
    {
      consume(Token.lbrace)
      getOrSet(field)
      getOrSet(field)
      consume(Token.rbrace)
    }

    // generate synthetic getter or setter code if necessary
    if (!field.isConst)
    {
      if (field.get.code == null) genSyntheticGet(field)
      if (field.set.code == null) genSyntheticSet(field)
    }

    // readonly is syntatic sugar for { private set }
    if (flags & Readonly !== 0)
    {
      field.set.flags = (field.set.flags & ProtectionMask) | FConst.Private
    }

    endOfStmt
    return field
  }

  private Void defGetAndSet(FieldDef f)
  {
    loc := f.location

    // getter MethodDef
    get := MethodDef.make(loc, f.parentDef)
    get.accessorFor = f
    get.flags = f.flags | FConst.Getter
    get.name  = f.name
    get.ret   = f.fieldType
    f.get = get

    // setter MethodDef
    set := MethodDef.make(loc, f.parentDef)
    set.accessorFor = f
    set.flags = f.flags | FConst.Setter
    set.name  = f.name
    set.ret   = ns.voidType
    set.params.add(ParamDef.make(loc, f.fieldType, "val"))
    f.set = set
  }

  private Void genSyntheticGet(FieldDef f)
  {
    loc := f.location
    f.get.flags |= FConst.Synthetic
    if (!f.isAbstract && !f.isNative)
    {
      f.flags |= FConst.Storage
      f.get.code = Block.make(loc)
      f.get.code.add(ReturnStmt.make(loc, f.makeAccessorExpr(loc, false)))
    }
  }

  private Void genSyntheticSet(FieldDef f)
  {
    loc := f.location
    f.set.flags |= FConst.Synthetic
    if (!f.isAbstract && !f.isNative)
    {
      f.flags |= FConst.Storage
      lhs := f.makeAccessorExpr(loc, false)
      rhs := UnknownVarExpr.make(loc, null, "val")
      f.set.code = Block.make(loc)
      f.set.code.add(BinaryExpr.makeAssign(lhs, rhs).toStmt)
      f.set.code.add(ReturnStmt.make(loc))
    }
  }

  private Void getOrSet(FieldDef f)
  {
    loc := cur
    accessorFlags := flags(false)
    if (curt === Token.identifier)
    {
      // get or set
      idLoc := cur
      id := consumeId

      if (id == "get")
        curMethod = f.get
      else
        curMethod = f.set

      // { ...block... }
      Block block := null
      if (curt === Token.lbrace)
        block = this.block(id != "get")
      else
        endOfStmt

      // const field cannot have getter/setter
      if (f.isConst)
      {
        err("Const field '$f.name' cannot have ${id}ter", idLoc)
        return
      }

      // map to get or set on FieldDef
      if (id == "get")
      {
        if (accessorFlags != 0) err("Cannot use modifiers on field getter", loc)
        f.get.code  = block
      }
      else if (id.equals("set"))
      {
        if (accessorFlags != 0)
        {
          if (accessorFlags & ProtectionMask != 0)
            err("Cannot use modifiers on field setter except to narrow protection", loc)
          f.set.flags = (f.set.flags & ProtectionMask) | accessorFlags
        }
        f.set.code = block
      }
      else
      {
        err("Expected 'get' or 'set', not '$id'", idLoc)
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// MethodDef
//////////////////////////////////////////////////////////////////////////

  **
  ** Method definition:
  **   <methodDef>      :=  <facets> <methodFlags> <type> <id> "(" <params> ")" <methodBody>
  **   <methodFlags>    :=  [<protection>] ["virtual"] ["override"] ["abstract"] ["static"]
  **   <params>         :=  [<param> ("," <param>)*]
  **   <param>          :=  <type> <id> [":=" <expr>]
  **   <methodBody>     :=  <eos> | ( "{" <stmts> "}" )
  **
  private MethodDef methodDef(Location loc, TypeDef parent, Str[] doc, Str:FacetDef facets, Int flags, TypeRef ret, Str name)
  {
    method := MethodDef.make(loc, parent)
    method.doc    = doc
    method.facets = facets
    method.flags  = flags
    method.ret    = ret
    method.name   = name

    // if This is returned, then we configure inheritedRet
    // right off the bat (this is actual signature we will use)
    if (ret.isThis) method.inheritedRet = parent

    // enter scope
    curMethod = method

    // parameters
    consume(Token.lparen)
    if (curt !== Token.rparen)
    {
      while (true)
      {
        method.params.add(paramDef)
        if (curt === Token.rparen) break
        consume(Token.comma)
      }
    }
    consume(Token.rparen)

    // if no body expected
    if (isSys) flags |= FConst.Native
    if (flags & FConst.Abstract !== 0 || flags & FConst.Native !== 0)
    {
      if (curt === Token.lbrace)
      {
        err("Abstract and native methods cannot have method body")
        block(ret.isVoid)  // keep parsing
      }
      else
      {
        endOfStmt
      }
      return method
    }

    // ctor chain
    if ((flags & FConst.Ctor !== 0) && (curt === Token.colon))
      method.ctorChain = ctorChain(method);

    // body
    if (curt != Token.lbrace)
      err("Expecting method body")
    else
      method.code = block(ret.isVoid)

    // exit scope
    curMethod = null

    return method
  }

  private ParamDef paramDef()
  {
    param := ParamDef.make(cur)
    param.paramType = typeRef
    param.name = consumeId
    if (curt === Token.defAssign || curt === Token.assign)
    {
      if (curt === Token.assign) err("Must use := for parameter default");
      consume
      param.def = expr
    }
    return param
  }

  private CallExpr ctorChain(MethodDef method)
  {
    consume(Token.colon)
    loc := cur

    call := CallExpr.make(loc)
    call.isCtorChain = true
    switch (curt)
    {
      case Token.superKeyword: consume; call.target = SuperExpr.make(loc)
      case Token.thisKeyword:  consume; call.target = ThisExpr.make(loc)
      default: throw err("Expecting this or super for constructor chaining", loc);
    }

    // we can omit name if super
    if (call.target.id === ExprId.superExpr && curt != Token.dot)
    {
      call.name = method.name
    }
    else
    {
      consume(Token.dot)
      call.name = consumeId
    }

    // TODO: omit args if pass thru?
    callArgs(call)
    return call
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  private Str:FacetDef facets()
  {
    if (curt !== Token.at) return null

    facets := Str:FacetDef[:]
    while (curt === Token.at)
    {
      consume
      loc := cur
      name := consumeId
      Expr val
      if (curt === Token.assign)
      {
        consume()
        val = expr
      }
      else
      {
        val = LiteralExpr.make(loc, ExprId.trueLiteral, ns.boolType, true)
      }
      if (facets[name] != null) err("Duplicate facet '$name'", loc)
      facets[name] = FacetDef.make(loc, name, val)
    }
    return facets
  }

//////////////////////////////////////////////////////////////////////////
// Block
//////////////////////////////////////////////////////////////////////////

  **
  ** Top level for blocks which must be surrounded by braces
  **
  private Block block(Bool inVoid)
  {
    this.inVoid = inVoid
    verify(Token.lbrace)
    return stmtOrBlock
  }

  **
  ** <block>  :=  <stmt> | ( "{" <stmts> "}" )
  ** <stmts>  :=  <stmt>*
  **
  private Block stmtOrBlock()
  {
    block := Block.make(cur)

    if (curt !== Token.lbrace)
    {
      block.stmts.add( stmt )
    }
    else
    {
      consume(Token.lbrace)
      while (curt != Token.rbrace)
        block.stmts.add( stmt )
      consume(Token.rbrace)
    }

    return block
  }

//////////////////////////////////////////////////////////////////////////
// Statements
//////////////////////////////////////////////////////////////////////////

  **
  ** Statement:
  **   <stmt>  :=  <break> | <continue> | <for> | <if> | <return> | <switch> |
  **               <throw> | <while> | <try> | <exprStmt> | <localDef>
  **
  private Stmt stmt()
  {
    // check for statement keywords
    switch (curt)
    {
      case Token.breakKeyword:    return breakStmt
      case Token.continueKeyword: return continueStmt
      case Token.forKeyword:      return forStmt
      case Token.ifKeyword:       return ifStmt
      case Token.returnKeyword:   return returnStmt
      case Token.switchKeyword:   return switchStmt
      case Token.throwKeyword:    return throwStmt
      case Token.tryKeyword:      return tryStmt
      case Token.whileKeyword:    return whileStmt
    }

    // at this point we either have an expr or local var declaration
    return exprOrLocalDefStmt(true)
  }

  **
  ** Expression or local variable declaration:
  **   <exprStmt>  :=  <expr> <eos>
  **   <localDef>  :=  [<type>] <id> [":=" <expr>] <eos>
  **
  private Stmt exprOrLocalDefStmt(Bool isEndOfStmt)
  {
    // see if this statement begins with a type literal
    loc := cur
    mark := pos
    localType := tryType

    // type followed by identifier must be local variable declaration
    if (localType != null && curt === Token.identifier)
    {
      return localDefStmt(loc, localType, isEndOfStmt)
    }
    reset(mark)

    // identifier followed by def assign is inferred typed local var declaration
    if (curt === Token.identifier && peekt === Token.defAssign)
    {
      return localDefStmt(loc, null, isEndOfStmt)
    }

    // if current is an identifer, save for special error handling
    Str id := (curt === Token.identifier) ? (Str)cur.val : null

    // otherwise assume it's a stand alone expression statement
    stmt := ExprStmt.make(expr)
    if (!isEndOfStmt) return stmt
    if (endOfStmt(null)) return stmt

    // report error
    if (id != null && curt === Token.identifier && (peekt === Token.defAssign || peekt === Token.assign))
      throw err("Unknown type '$id' for local declaration", loc)
    else
      throw err("Expected expression statement", loc)
  }

  **
  ** Parse local variable declaration, the current token must be
  ** the identifier of the local variable.
  **
  private LocalDefStmt localDefStmt(Location loc, CType localType, Bool isEndOfStmt)
  {
    stmt := LocalDefStmt.make(loc)
    stmt.ctype = localType
    stmt.name  = consumeId

    if (curt === Token.defAssign || curt === Token.assign)
    {
      if (curt === Token.assign) err("Must use := for declaration assignments")
      consume
      stmt.init = expr
    }

    if (isEndOfStmt) endOfStmt
    return stmt
  }

  **
  ** If/else statement:
  **   <if>  :=  "if" "(" <expr> ")" <block> [ "else" <block> ]
  **
  private IfStmt ifStmt()
  {
    stmt := IfStmt.make(cur)
    consume(Token.ifKeyword)
    consume(Token.lparen)
    stmt.condition = expr
    consume(Token.rparen)
    stmt.trueBlock = stmtOrBlock
    if (curt === Token.elseKeyword)
    {
      consume(Token.elseKeyword)
      stmt.falseBlock = stmtOrBlock
    }
    return stmt
  }

  **
  ** Return statement:
  **   <return>  :=  "return" [<expr>] <eos>
  **
  private ReturnStmt returnStmt()
  {
    stmt := ReturnStmt.make(cur)
    consume(Token.returnKeyword)
    if (inVoid)
    {
      endOfStmt("Expected end of statement after return in Void method")
    }
    else
    {
      stmt.expr = expr
      endOfStmt
    }
    return stmt
  }

  **
  ** Throw statement:
  **   <throw>  :=  "throw" <expr> <eos>
  **
  private ThrowStmt throwStmt()
  {
    stmt := ThrowStmt.make(cur)
    consume(Token.throwKeyword)
    stmt.exception = expr
    endOfStmt
    return stmt
  }

  **
  ** While statement:
  **   <while>  :=  "while" "(" <expr> ")" <block>
  **
  private WhileStmt whileStmt()
  {
    stmt := WhileStmt.make(cur)
    consume(Token.whileKeyword)
    consume(Token.lparen)
    stmt.condition = expr
    consume(Token.rparen)
    stmt.block = stmtOrBlock
    return stmt
  }

  **
  ** For statement:
  **   <for>      :=  "for" "(" [<forInit>] ";" <expr> ";" <expr> ")" <block>
  **   <forInit>  :=  <expr> | <localDef>
  **
  private ForStmt forStmt()
  {
    stmt := ForStmt.make(cur)
    consume(Token.forKeyword)
    consume(Token.lparen)

    if (curt !== Token.semicolon) stmt.init = exprOrLocalDefStmt(false)
    consume(Token.semicolon)

    if (curt != Token.semicolon) stmt.condition = expr
    consume(Token.semicolon)

    if (curt != Token.rparen) stmt.update = expr
    consume(Token.rparen)

    stmt.block = stmtOrBlock
    return stmt
  }

  **
  ** Break statement:
  **   <break>  :=  "break" <eos>
  **
  private BreakStmt breakStmt()
  {
    stmt := BreakStmt.make(cur)
    consume(Token.breakKeyword)
    endOfStmt
    return stmt
  }

  **
  ** Continue statement:
  **   <continue>  :=  "continue" <eos>
  **
  private ContinueStmt continueStmt()
  {
    stmt := ContinueStmt.make(cur)
    consume(Token.continueKeyword)
    endOfStmt
    return stmt
  }

  **
  ** Try-catch-finally statement:
  **   <try>       :=  "try" "{" <stmt>* "}" <catch>* [<finally>]
  **   <catch>     :=  "catch" [<catchDef>] "{" <stmt>* "}"
  **   <catchDef>  :=  "(" <type> <id> ")"
  **   <finally>   :=  "finally" "{" <stmt>* "}"
  **
  private TryStmt tryStmt()
  {
    stmt := TryStmt.make(cur)
    consume(Token.tryKeyword)
    stmt.block = stmtOrBlock
    if (curt !== Token.catchKeyword && curt !== Token.finallyKeyword)
      throw err("Expecting catch or finally block")
    while (curt === Token.catchKeyword)
    {
      stmt.catches.add(tryCatch)
    }
    if (curt === Token.finallyKeyword)
    {
      consume
      stmt.finallyBlock = stmtOrBlock
    }
    return stmt
  }

  private Catch tryCatch()
  {
    c := Catch.make(cur)
    consume(Token.catchKeyword)

    if (curt === Token.lparen)
    {
      consume(Token.lparen)
      c.errType = typeRef
      c.errVariable = consumeId
      consume(Token.rparen)
    }

    c.block = stmtOrBlock

    // insert implicit local variable declaration
    if (c.errVariable != null)
      c.block.stmts.insert(0, LocalDefStmt.makeCatchVar(c))

    return c
  }

  **
  ** Switch statement:
  **   <switch>   :=  "switch" "(" <expr> ")" "{" <case>* [<default>] "}"
  **   <case>     :=  "case" <expr> ":" <stmts>
  **   <default>  :=  "default" ":" <stmts>
  **
  private SwitchStmt switchStmt()
  {
    stmt := SwitchStmt.make(cur)
    consume(Token.switchKeyword)
    consume(Token.lparen)
    stmt.condition = expr
    consume(Token.rparen)
    consume(Token.lbrace)
    while (curt != Token.rbrace)
    {
      if (curt === Token.caseKeyword)
      {
        c := Case.make(cur)
        while (curt === Token.caseKeyword)
        {
          consume
          c.cases.add(expr)
          consume(Token.colon)
        }
        if (curt !== Token.defaultKeyword) // optimize away case fall-thru to default
        {
          c.block = switchBlock
          stmt.cases.add(c)
        }
      }
      else if (curt === Token.defaultKeyword)
      {
        if (stmt.defaultBlock != null) err("Duplicate default blocks")
        consume
        consume(Token.colon)
        stmt.defaultBlock = switchBlock
      }
      else
      {
        throw err("Expected case or default statement")
      }
    }
    consume(Token.rbrace)
    endOfStmt
    return stmt
  }

  private Block switchBlock()
  {
    Block block := null
    while (curt !== Token.caseKeyword && curt != Token.defaultKeyword && curt !== Token.rbrace)
    {
      if (block == null) block = Block.make(cur)
      block.stmts.add(stmt)
    }
    return block;
  }

//////////////////////////////////////////////////////////////////////////
// Expr
//////////////////////////////////////////////////////////////////////////

  **
  ** Expression:
  **   <expr>  :=  <assignExpr>
  **
  private Expr expr()
  {
    return assignExpr
  }

  **
  ** Assignment expression:
  **   <assignExpr>  :=  <condOrExpr> [<assignOp> <assignExpr>]
  **   <assignOp>    :=  "=" | "*=" | "/=" | "%=" | "+=" | "-=" | "<<=" | ">>="  | "&=" | "^=" | "|="
  **
  private Expr assignExpr(Expr expr := null)
  {
    // this is tree if built to the right (others to the left)
    if (expr == null) expr = ternary
    if (curt.isAssign)
    {
      if (curt === Token.assign)
        return BinaryExpr.make(expr, consume.kind, assignExpr)
      else
        return ShortcutExpr.makeBinary(expr, consume.kind, assignExpr)
    }
    return expr
  }

  **
  ** Ternary expression:
  **   <ternaryExpr> :=  <elvisExpr> "?" <elvisExpr> ":" <elvisExpr>
  **
  private Expr ternary()
  {
    expr := condOrExpr
    if (curt === Token.question)
    {
      condition := expr
      consume(Token.question)
      trueExpr := condOrExpr
      consume(Token.colon)
      falseExpr := condOrExpr
      expr = TernaryExpr.make(condition, trueExpr, falseExpr)
    }
    return expr
  }

  **
  ** Conditional or expression:
  **   <condOrExpr>  :=  <condAndExpr>  ("||" <condAndExpr>)*
  **
  private Expr condOrExpr()
  {
    expr := condAndExpr
    if (curt === Token.doublePipe)
    {
      cond := CondExpr.make(expr, cur.kind)
      while (curt === Token.doublePipe)
      {
        consume
        cond.operands.add(condAndExpr)
      }
      expr = cond
    }
    return expr
  }

  **
  ** Conditional and expression:
  **   <condAndExpr>  :=  <equalityExpr> ("&&" <equalityExpr>)*
  **
  private Expr condAndExpr()
  {
    expr := equalityExpr
    if (curt === Token.doubleAmp)
    {
      cond := CondExpr.make(expr, cur.kind)
      while (curt === Token.doubleAmp)
      {
        consume
        cond.operands.add(equalityExpr)
      }
      expr = cond
    }
    return expr
  }

  **
  ** Equality expression:
  **   <equalityExpr>  :=  <relationalExpr> (("==" | "!=" | "===" | "!==") <relationalExpr>)*
  **
  private Expr equalityExpr()
  {
    expr := relationalExpr
    while (curt === Token.eq   || curt === Token.notEq ||
           curt === Token.same || curt === Token.notSame)
    {
      lhs := expr
      tok := consume.kind
      rhs := relationalExpr

      // optimize for null literal
      if (lhs.id === ExprId.nullLiteral || rhs.id === ExprId.nullLiteral)
      {
        id := (tok === Token.eq || tok === Token.same) ? ExprId.cmpNull : ExprId.cmpNotNull
        operand := (lhs.id === ExprId.nullLiteral) ? rhs : lhs
        expr = UnaryExpr.make(lhs.location, id, tok, operand)
      }
      else
      {
        if (tok === Token.same || tok === Token.notSame)
          expr = BinaryExpr.make(lhs, tok, rhs)
        else
          expr = ShortcutExpr.makeBinary(lhs, tok, rhs)
      }
    }
    return expr
  }

  **
  ** Relational expression:
  **   <relationalExpr> :=  <rangeExpr> (("is" | "as" | "<" | "<=" | ">" | ">=" | "<=>") <rangeExpr>)*
  **
  private Expr relationalExpr()
  {
    expr := elvisExpr
    while (curt === Token.isKeyword || curt === Token.isnotKeyword ||
           curt === Token.asKeyword ||
           curt === Token.lt || curt === Token.ltEq ||
           curt === Token.gt || curt === Token.gtEq ||
           curt === Token.cmp)
    {
      switch (curt)
      {
        case Token.isKeyword:
          consume
          expr = TypeCheckExpr.make(expr.location, ExprId.isExpr, expr, ctype)
        case Token.isnotKeyword:
          consume
          expr = TypeCheckExpr.make(expr.location, ExprId.isnotExpr, expr, ctype)
        case Token.asKeyword:
          consume
          expr = TypeCheckExpr.make(expr.location, ExprId.asExpr, expr, ctype)
        default:
          expr = ShortcutExpr.makeBinary(expr, consume.kind, elvisExpr)
      }
    }
    return expr
  }

  **
  ** Elvis expression:
  **   <elvisExpr> :=  <condOrExpr> "?:" <condOrExpr>
  **
  private Expr elvisExpr()
  {
    expr := rangeExpr
    while (curt === Token.elvis)
    {
      lhs := expr
      consume
      rhs := rangeExpr
      expr = BinaryExpr.make(lhs, Token.elvis, rhs)
    }
    return expr
  }

  **
  ** Range expression:
  **   <rangeExpr>  :=  <bitOrExpr> ((".." | "...") <bitOrExpr>)*
  **
  private Expr rangeExpr()
  {
    expr := bitOrExpr
    if (curt === Token.dotDot || curt === Token.dotDotDot)
    {
      range := RangeLiteralExpr.make(expr.location, ns.rangeType)
      range.start     = expr
      range.exclusive = consume.kind === Token.dotDotDot
      range.end       = bitOrExpr
      return range
    }
    return expr
  }

  **
  ** Bitwise or expression:
  **   <bitOrExpr>  :=  <bitAndExpr> (("^" | "|") <bitAndExpr>)*
  **
  private Expr bitOrExpr()
  {
    expr := bitAndExpr
    while (curt === Token.caret || curt === Token.pipe)
      expr = ShortcutExpr.makeBinary(expr, consume.kind, bitAndExpr)
    return expr
  }

  **
  ** Bitwise and expression:
  **   <bitAndExpr>  :=  <shiftExpr> (("&" <shiftExpr>)*
  **
  private Expr bitAndExpr()
  {
    expr := shiftExpr
    while (curt === Token.amp)
      expr = ShortcutExpr.makeBinary(expr, consume.kind, shiftExpr)
    return expr
  }

  **
  ** Bitwise shift expression:
  **   <shiftExpr>  :=  <addExpr> (("<<" | ">>") <addExpr>)*
  **
  private Expr shiftExpr()
  {
    expr := additiveExpr
    while (curt === Token.lshift || curt === Token.rshift)
      expr = ShortcutExpr.makeBinary(expr, consume.kind, additiveExpr)
    return expr
  }

  **
  ** Additive expression:
  **   <addExpr>  :=  <multExpr> (("+" | "-") <multExpr>)*
  **
  private Expr additiveExpr()
  {
    expr := multiplicativeExpr
    while (curt === Token.plus || curt === Token.minus)
      expr = ShortcutExpr.makeBinary(expr, consume.kind, multiplicativeExpr)
    return expr
  }

  **
  ** Multiplicative expression:
  **   <multExpr>  :=  <parenExpr> (("*" | "/" | "%") <parenExpr>)*
  **
  private Expr multiplicativeExpr()
  {
    expr := parenExpr
    while (curt === Token.star || curt === Token.slash || curt === Token.percent)
      expr = ShortcutExpr.makeBinary(expr, consume.kind, parenExpr)
    return expr
  }

  **
  ** Paren grouped expression:
  **   <parenExpr>    :=  <unaryExpr> | <castExpr> | <groupedExpr>
  **   <castExpr>     :=  "(" <type> ")" <parenExpr>
  **   <groupedExpr>  :=  "(" <expr> ")" <termChain>*
  **
  private Expr parenExpr()
  {
    if (curt != Token.lparen)
      return unaryExpr

    // consume opening paren
    loc := cur
    consume(Token.lparen)

    // In Fan just like C# and Java, a paren could mean
    // either a cast or a parenthesized expression
    mark := pos
    castType := tryType
    if (curt === Token.rparen)
    {
      consume
      return TypeCheckExpr.make(loc, ExprId.cast, parenExpr, castType)
    }
    reset(mark)

    // this is just a normal parenthesized expression
    expr := expr
    consume(Token.rparen)
    while (true)
    {
      chained := termChainExpr(expr)
      if (chained == null) break
      expr = chained
    }
    return expr
  }

  **
  ** Unary expression:
  **   <unaryExpr>    :=  <prefixExpr> | <termExpr> | <postfixExpr>
  **   <prefixExpr>   :=  ("!" | "+" | "-" | "~" | "++" | "--") <parenExpr>
  **   <postfixExpr>  :=  <termExpr> ("++" | "--")
  **
  private Expr unaryExpr()
  {
    loc := cur
    tok := cur
    tokt := curt

    if (tokt === Token.bang)
    {
      consume
      return UnaryExpr.make(loc, tokt.toExprId, tokt, parenExpr)
    }

    if (tokt === Token.amp)
    {
      consume
      return CurryExpr.make(loc, parenExpr)
    }

    if (tokt === Token.plus)
    {
      consume
      return parenExpr // optimize +expr to just expr
    }

    if (tokt === Token.tilde || tokt === Token.minus)
    {
      consume
      return ShortcutExpr.makeUnary(loc, tokt, parenExpr)
    }

    if (tokt === Token.increment || tokt === Token.decrement)
    {
      consume
      return ShortcutExpr.makeUnary(loc, tokt, parenExpr)
    }

    expr := termExpr

    tokt = curt
    if (tokt === Token.increment || tokt == Token.decrement)
    {
      consume
      shortcut := ShortcutExpr.makeUnary(loc, tokt, expr)
      shortcut.isPostfixLeave = true
      return shortcut
    }

    return expr
  }

//////////////////////////////////////////////////////////////////////////
// Term Expr
//////////////////////////////////////////////////////////////////////////

  **
  ** A term is a base terminal such as a variable, call, or literal,
  ** optionally followed by a chain of accessor expressions - such
  ** as "x.y[z](a, b)".
  **
  **   <termExpr>  :=  <termBase> <termChain>* [withBlock]
  **
  private Expr termExpr(Expr target := null)
  {
    if (target == null) target = termBaseExpr
    while (true)
    {
      chained := termChainExpr(target)
      if (chained == null) break
      target = chained
    }
    if (curt == Token.lbrace)
      return withBlock(target)
    return target
  }

  **
  ** Atomic base of a termExpr
  **
  **   <termBase>  :=  <literal> | <idExpr> | <closure>
  **   <literal>   :=  "null" | "this" | "super" | <bool> | <int> |
  **                   <float> | <str> | <duration> | <list> | <map> | <uri>
  **
  private Expr termBaseExpr()
  {
    loc := cur

    ctype := tryType
    if (ctype != null) return typeBaseExpr(loc, ctype)

    switch (curt)
    {
      case Token.at:              return idExpr(null, false, false)
      case Token.identifier:      return idExpr(null, false, false)
      case Token.intLiteral:      return LiteralExpr.make(loc, ExprId.intLiteral, ns.intType, consume.val)
      case Token.floatLiteral:    return LiteralExpr.make(loc, ExprId.floatLiteral, ns.floatType, consume.val)
      case Token.decimalLiteral:  return LiteralExpr.make(loc, ExprId.decimalLiteral, ns.decimalType, consume.val)
      case Token.strLiteral:      return LiteralExpr.make(loc, ExprId.strLiteral, ns.strType, consume.val)
      case Token.durationLiteral: return LiteralExpr.make(loc, ExprId.durationLiteral, ns.durationType, consume.val)
      case Token.uriLiteral:      return LiteralExpr.make(loc, ExprId.uriLiteral, ns.uriType, consume.val)
      case Token.lbracket:        return collectionLiteralExpr(loc, null)
      case Token.falseKeyword:    consume; return LiteralExpr.make(loc, ExprId.falseLiteral, ns.boolType, false)
      case Token.nullKeyword:     consume; return LiteralExpr.make(loc, ExprId.nullLiteral, ns.objType, null)
      case Token.superKeyword:    consume; return SuperExpr.make(loc)
      case Token.thisKeyword:     consume; return ThisExpr.make(loc)
      case Token.trueKeyword:     consume; return LiteralExpr.make(loc, ExprId.trueLiteral, ns.boolType, true)
      case Token.pound:           consume; return SlotLiteralExpr.make(loc, curType, consumeId)
    }
    throw err("Expected expression, not '" + cur + "'")
  }

  **
  ** Handle a term expression which begins with a type literal.
  **
  private Expr typeBaseExpr(Location loc, CType ctype)
  {
    // type or slot literal
    if (curt === Token.pound)
    {
      consume
      if (curt === Token.identifier && !cur.newline)
        return SlotLiteralExpr.make(loc, ctype, consumeId)
      else
        return LiteralExpr.make(loc, ExprId.typeLiteral, ns.typeType, ctype)
    }

    // dot is named super or static call chain
    if (curt == Token.dot)
    {
      consume
      if (curt === Token.superKeyword)
      {
        consume
        return SuperExpr.make(loc, ctype)
      }
      else
      {
        return idExpr(StaticTargetExpr.make(loc, ctype), false, false)
      }
    }

    // list/map literal with explicit type
    if (curt === Token.lbracket)
    {
      return collectionLiteralExpr(loc, ctype)
    }

    // closure
    if (curt == Token.lbrace && ctype is FuncType)
    {
      return closure(loc, (FuncType)ctype)
    }

    // simple literal type(arg)
    if (curt == Token.lparen)
    {
      construction := CallExpr.make(loc, StaticTargetExpr.make(loc, ctype), "?", ExprId.construction)
      callArgs(construction)
      return construction
    }

    // complex literal type {...}
    if (curt == Token.lbrace)
    {
      base := UnknownVarExpr.make(loc, StaticTargetExpr.make(loc, ctype), "make")
      return withBlock(base)
    }

    throw err("Unexpected type literal", loc)
  }

  **
  ** A chain expression is a piece of a term expression that may
  ** be chained together such as "call.var[x]".  If the specified
  ** target expression contains a chained access, then return the new
  ** expression, otherwise return null.
  **
  **   <termChain>      :=  <compiledCall> | <dynamicCall> | <indexExpr>
  **   <compiledCall>   :=  "." <idExpr>
  **   <dynamicCall>    :=  "->" <idExpr>
  **
  private Expr termChainExpr(Expr target)
  {
    loc := cur

    // handle various call operators: . -> ?. ?->
    switch (curt)
    {
      // if ".id" field access or ".id" call
      case Token.dot: consume;  return idExpr(target, false, false)

      // if "->id" dynamic call
      case Token.arrow: consume; return idExpr(target, true, false)

      // if "?.id" safe call
      case Token.safeDot: consume; return idExpr(target, false, true)

      // if "?->id" safe dynamic call
      case Token.safeArrow: consume; return idExpr(target, true, true)
    }

    // if target[...]
    if (cur.isIndexOpenBracket) return indexExpr(target)

    // if target(...)
    if (cur.isCallOpenParen) return callOp(target)

    // we treat a with base as a dot slot access
    if (target.id === ExprId.withBase) return idExpr(target, false, false)

    // otherwise the expression should be finished
    return null;
  }

  **
  ** A with block is a series of sub-expressions
  ** inside {} appended to the end of an expression.
  **
  private Expr withBlock(Expr base)
  {
    // field initializers look like a with block, but
    // we can safely peek to see if the next token is "get",
    // "set", or a keyword like "private"
    if (inFieldInit)
    {
      if (peek.kind.keyword) return base
      if (peekt == Token.identifier)
      {
        if (peek.val == "get" || peek.val == "set") return base
      }
    }

    withBlock := WithBlockExpr.make(base)
    consume(Token.lbrace)
    while (curt !== Token.rbrace)
    {
      withBase := WithBaseExpr.make(withBlock)
      sub := withSub(withBase)
      withSub := WithSubExpr.make(withBlock, sub)
      withBase.withSub = withSub
      withBlock.subs.add(withSub)
      endOfStmt
    }
    consume(Token.rbrace)
    return withBlock
  }

  **
  ** Parse a with-block sub-expression.  If we have a named
  ** expression, then it is implied to be against the withBase.
  ** Otherwise we assume syntax sugar for 'withBase.add(sub)'.
  ** In case we get it wrong here, we try again in CallResolver.
  **
  private Expr withSub(WithBaseExpr withBase)
  {
    // if NameExpr, then apply implicit withBase
    Expr sub := termExpr
    if (sub is NameExpr)
    {
      x := sub
      while (x is NameExpr && x->target != null) x = x->target
      if (x is NameExpr)
      {
        x->target = withBase
        return assignExpr(sub)
      }
    }

    // assume syntax sugar for 'withBase.add(sub)'
    return CallExpr.make(sub.location, withBase, "add") { args.add(sub) }
  }

//////////////////////////////////////////////////////////////////////////
// Term Expr Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Identifier expression:
  **   <idExpr>  :=  <local> | <field> | <call>
  **   <local>   :=  <id>
  **   <field>   :=  ["@"] <id>
  **
  private Expr idExpr(Expr target, Bool dynamicCall, Bool safeCall)
  {
    loc := cur

    if (curt == Token.at)
    {
      consume
      return UnknownVarExpr.makeStorage(loc, target, consumeId)
    }

    if (peek.isCallOpenParen)
    {
      call := callExpr(target)
      call.isDynamic = dynamicCall
      call.isSafe = safeCall
      return call
    }

    name := consumeId

    // if we have a closure then this is a call with one arg of a closure
    closure := tryClosure
    if (closure != null)
    {
      call := CallExpr.make(loc)
      call.target = target
      call.name   = name
      call.args.add(closure)
      return call
    }

    // if dynamic call then we know this is a call not a field
    if (dynamicCall)
    {
      call := CallExpr.make(loc)
      call.target    = target
      call.name      = name
      call.isDynamic = true
      call.isSafe    = safeCall
      return call
    }

    return UnknownVarExpr.make(loc, target, name) { isSafe = safeCall }
  }

  **
  ** Call expression:
  **   <call>  :=  <id> ["(" <args> ")"] [<closure>]
  **
  private CallExpr callExpr(Expr target)
  {
    call := CallExpr.make(cur)
    call.target  = target
    call.name    = consumeId
    callArgs(call)
    return call
  }

  **
  ** Parse args with known parens:
  **   <args>  := [<expr> ("," <expr>)*] [<closure>]
  **
  private Void callArgs(CallExpr call)
  {
    consume(Token.lparen)
    if (curt != Token.rparen)
    {
      while (true)
      {
        call.args.add(expr)
        if (curt === Token.rparen) break
        consume(Token.comma)
      }
    }
    consume(Token.rparen)

    closure := tryClosure
    if (closure != null) call.args.add(closure);
  }

  **
  ** Call operator:
  **   <callOp>  := "(" <args> ")" [<closure>]
  **
  private Expr callOp(Expr target)
  {
    loc := cur
    call := CallExpr.make(loc)
    call.target = target
    callArgs(call)
    call.name = "call${call.args.size}"
    return call
  }

  **
  ** Index expression:
  **   <indexExpr>  := "[" <expr> "]"
  **
  private Expr indexExpr(Expr target)
  {
    loc := cur
    consume(Token.lbracket)

    // otherwise this must be a standard single key index
    expr := expr
    consume(Token.rbracket)
    return ShortcutExpr.makeGet(loc, target, expr)
  }

//////////////////////////////////////////////////////////////////////////
// Collection "Literals"
//////////////////////////////////////////////////////////////////////////

  **
  ** Collection literal:
  **   <list>       :=  [<type>] "[" <listItems> "]"
  **   <listItems>  :=  "," | (<expr> ("," <expr>)*)
  **   <map>        :=  [<mapType>] "[" <mapItems> "]"
  **   <mapItems>   :=  ":" | (<mapPair> ("," <mapPair>)*)
  **   <mapPair>    :=  <expr> ":" <expr>
  **
  private Expr collectionLiteralExpr(Location loc, CType explicitType)
  {
    // empty list [,]
    if (peekt === Token.comma)
      return listLiteralExpr(loc, explicitType, null)

    // empty map [:]
    if (peekt === Token.colon)
      return mapLiteralExpr(loc, explicitType, null)

    // opening bracket
    consume(Token.lbracket)

    // [] is error
    if (curt === Token.rbracket)
    {
      err("Invalid list literal; use '[,]' for empty Obj[] list", loc)
      consume
      return ListLiteralExpr.make(loc)
    }

    // read first expression
    first := expr

    // at this point we can determine if it is a list or a map
    if (curt === Token.colon)
      return mapLiteralExpr(loc, explicitType, first)
    else
      return listLiteralExpr(loc, explicitType, first)
  }

  **
  ** Parse List literal; if first is null then
  **   cur must be on lbracket
  ** else
  **   cur must be on comma after first item
  **
  private ListLiteralExpr listLiteralExpr(Location loc, CType explicitType, Expr first)
  {
    // explicitType is type of List:  Str[,]
    if (explicitType != null)
      explicitType = explicitType.toListOf

    list := ListLiteralExpr.make(loc, (ListType)explicitType)

    // if first is null, must be on lbracket
    if (first == null)
    {
      consume(Token.lbracket)

      // if [,] empty list
      if (curt === Token.comma)
      {
        consume
        consume(Token.rbracket)
        return list
      }

      first = expr
    }

    list.vals.add(first)
    while (curt === Token.comma)
    {
      consume
      if (curt === Token.rbracket) break // allow extra trailing comma
      list.vals.add(expr)
    }
    consume(Token.rbracket)
    return list
  }

  **
  ** Parse Map literal; if first is null:
  **   cur must be on lbracket
  ** else
  **   cur must be on colon of first key/value pair
  **
  private MapLiteralExpr mapLiteralExpr(Location loc, CType explicitType, Expr first)
  {
    // explicitType is *the* map type: Str:Str[,]
    if (explicitType != null && !(explicitType is MapType))
    {
      err("Invalid map type '$explicitType' for map literal", loc)
      explicitType = null
    }

    map := MapLiteralExpr.make(loc, (MapType)explicitType)

    // if first is null, must be on lbracket
    if (first == null)
    {
      consume(Token.lbracket)

      // if [,] empty list
      if (curt === Token.colon)
      {
        consume
        consume(Token.rbracket)
        return map
      }

      first = expr
    }

    map.keys.add(first)
    consume(Token.colon)
    map.vals.add(expr)
    while (curt === Token.comma)
    {
      consume
      if (curt === Token.rbracket) break // allow extra trailing comma
      map.keys.add(expr)
      consume(Token.colon)
      map.vals.add(expr)
    }
    consume(Token.rbracket)
    return map
  }

//////////////////////////////////////////////////////////////////////////
// Closure
//////////////////////////////////////////////////////////////////////////

  **
  ** Attempt to parse a closure expression or return null if we
  ** aren't positioned at the start of a closure expression.
  **
  private ClosureExpr tryClosure()
  {
    loc := cur

    // if no pipe, then no closure
    if (curt !== Token.pipe) return null

    // otherwise this can only be a FuncType declaration,
    // so give it a whirl, and bail if that fails
    mark := pos
    funcType := (FuncType)tryType
    if (funcType == null) return null

    // if we don't see opening brace for body - no go
    if (curt !== Token.lbrace) { reset(mark); return null }

    return closure(loc, funcType)
  }

  **
  ** Parse body of closure expression and return ClosureExpr.
  **
  private ClosureExpr closure(Location loc, FuncType funcType)
  {
    if (curMethod == null)
      throw err("Unexpected closure outside of a method")

    // closure anonymous class name: class$method$count
    name := "${curType.name}\$${curMethod.name}\$${closureCount++}"

    // create closure
    closure := ClosureExpr.make(loc, curType, curMethod, curClosure, funcType, name)

    // save all closures in global list and list per type
    closures.add(closure)
    curType.closures.add(closure)

    // parse block; temporarily change our inVoid flag and curClosure
    oldInVoid := inVoid
    oldClosure := curClosure
    curClosure = closure
    closure.code = block(funcType.ret.isVoid)
    curClosure = oldClosure
    inVoid = oldInVoid

    return closure
  }

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a type production into a CType and wrap it as AST TypeRef.
  **
  private TypeRef typeRef()
  {
    Location loc := cur
    return TypeRef.make(loc, ctype)
  }

  **
  ** If the current stream of tokens can be parsed as a
  ** valid type production return it.  Otherwise leave
  ** the parser positioned on the current token.
  **
  private CType tryType()
  {
    // types can only begin with identifier, | or [
    if (curt !== Token.identifier && curt !== Token.pipe && curt !== Token.lbracket)
      return null

    suppressErr = true
    mark := pos
    CType type := null
    try
    {
      type = ctype
    }
    catch (SuppressedErr e)
    {
    }
    suppressErr = false
    if (type == null) reset(mark)
    return type
  }

  **
  ** Type signature:
  **   <type>      :=  <simpleType> | <listType> | <mapType> | <funcType>
  **   <listType>  :=  <type> "[]"
  **   <mapType>   :=  ["["] <type> ":" <type> ["]"]
  **
  private CType ctype()
  {
    CType t := null

    // Types can begin with:
    //   - id
    //   - [k:v]
    //   - |a, b -> r|
    if (curt === Token.identifier)
    {
      t = simpleType
    }
    else if (curt === Token.lbracket)
    {
      loc := consume(Token.lbracket)
      t = ctype
      consume(Token.rbracket)
      if (!(t is MapType)) err("Invalid map type", loc)
    }
    else if (curt === Token.pipe)
    {
      t = funcType
    }
    else
    {
      throw err("Expecting type name")
    }

    // trailing [] for lists
    while (curt === Token.lbracket && peekt === Token.rbracket)
    {
      consume(Token.lbracket)
      consume(Token.rbracket)
      t = t.toListOf
    }

    // check for ":" for map type
    if (curt === Token.colon)
    {
      consume(Token.colon)
      key := t
      val := ctype
      t = MapType.make(key, val)
    }

    // check for ? nullable
    if (curt === Token.question && !cur.whitespace)
    {
      consume(Token.question)
      t = t.toNullable
    }

    return t
  }

  **
  ** Simple type signature:
  **   <simpleType>  :=  <id> ["::" <id>]
  **
  private CType simpleType()
  {
    loc := cur
    id := consumeId

    // fully qualified
    if (curt === Token.doubleColon)
    {
      consume
      return ResolveImports.resolveQualified(this, id, consumeId, loc)
    }

    // unqualified name, lookup in imported types
    types := unit.importedTypes[id]
    if (types == null)
    {
      // handle sys generic parameters
      if (isSys && id.size == 1)
        return ns.genericParameter(id)

      // not found in imports
      err("Unknown type '$id'", loc)
      return ns.voidType
    }

    // if more then one it is ambiguous
    if (types.size > 1) err("Ambiguous type: " + types.join(", "))

    // got it
    return types.first
  }

  **
  ** Method type signature:
  **   <funcType>  :=  "|" <formals> ["->" <type> "|"
  **   <formals>   :=  [<formal> ("," <formal>)*]
  **   <formal>    :=  <type> <id>
  **
  private CType funcType()
  {
    params := CType[,]
    names  := Str[,]
    ret := ns.voidType

    // opening pipe
    consume(Token.pipe)

    // |,| is the empty method type
    if (curt === Token.comma)
    {
      consume
      consume(Token.pipe)
      return FuncType.make(params, names, ret)
    }

    // params, must be one if no ->
    if (curt !== Token.arrow)
    {
      params.add(ctype)
      if (curt === Token.identifier)
        names.add(consumeId)
      else
        names.add("_a")
    }
    while (curt === Token.comma)
    {
      consume
      params.add(ctype)
      if (curt === Token.identifier)
        names.add(consumeId)
      else
        names.add("_" + ('a'+names.size).toChar)
    }

    // optional arrow
    if (curt === Token.arrow)
    {
      consume
      ret = ctype
    }

    // closing pipe
    consume(Token.pipe)
    return FuncType.make(params, names, ret)
  }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse fandoc or retur null
  **
  private Str[] doc()
  {
    Str[] doc := null
    while (curt === Token.docComment)
      doc = (Str[])consume(Token.docComment).val
    return doc
  }

//////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////

  override CompilerErr err(Str msg, Location loc := null)
  {
    if (loc == null) loc = cur
    return super.err(msg, loc)
  }

//////////////////////////////////////////////////////////////////////////
// Tokens
//////////////////////////////////////////////////////////////////////////

  **
  ** Verify current is an identifier, consume it, and return it.
  **
  private Str consumeId()
  {
    if (curt !== Token.identifier)
      throw err("Expected identifier, not '$cur'");
    return (Str)consume.val;
  }

  **
  ** Check that the current token matches the specified
  ** type, but do not consume it.
  **
  private Void verify(Token kind)
  {
    if (curt !== kind)
      throw err("Expected '$kind.symbol', not '$cur'");
  }

  **
  ** Consume the current token and return consumed token.
  ** If kind is non-null then verify first
  **
  private TokenVal consume(Token kind := null)
  {
    // verify if not null
    if (kind != null) verify(kind)

    // save the current we are about to consume for return
    result := cur

    // get the next token from the buffer, if pos is past numTokens,
    // then always use the last token which will be eof
    TokenVal next;
    pos++;
    if (pos+1 < numTokens)
      next = tokens[pos+1]  // next peek is cur+1
    else
      next = tokens[numTokens-1]

    this.cur   = peek
    this.peek  = next
    this.curt  = cur.kind
    this.peekt = peek.kind

    return result
  }

  **
  ** Statements can be terminated with a semicolon, end of line
  ** or } end of block.   Return true on success.  On failure
  ** return false if errMsg is null or log/throw an exception.
  **
  private Bool endOfStmt(Str errMsg := "Expected end of statement: semicolon, newline, or end of block; not '$cur'")
  {
    if (cur.newline) return true
    if (curt === Token.semicolon) { consume; return true }
    if (curt === Token.rbrace) return true
    if (errMsg == null) return false
    throw err(errMsg)
  }

  **
  ** Reset the current position to the specified tokens index.
  **
  private Void reset(Int pos)
  {
    this.pos   = pos
    this.cur   = tokens[pos]
    if (pos+1 < numTokens)
      this.peek  = tokens[pos+1]
    else
      this.peek  = tokens[pos]
    this.curt  = cur.kind
    this.peekt = peek.kind
  }

//////////////////////////////////////////////////////////////////////////
// Parser Flags
//////////////////////////////////////////////////////////////////////////

  // These are flags used only by the parser we merge with FConst
  // flags by starting from most significant bit and working down
  const static Int Once     := 0x8000_0000
  const static Int Readonly := 0x4000_0000
  const static Int ParserFlagsMask := Readonly

  // Bitwise and this mask to clear all protection scope flags
  const static Int ProtectionMask := ~(FConst.Public|FConst.Protected|FConst.Private|FConst.Internal)

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private CompilationUnit unit   // compilation unit to generate
  private TokenVal[] tokens      // tokens all read in
  private Int numTokens          // number of tokens
  private Int pos;               // offset Into tokens for cur
  private TokenVal cur           // current token
  private Token curt             // current token type
  private TokenVal peek          // next token
  private Token peekt            // next token type
  private Bool isSys := false    // are we parsing the sys pod itself
  private Bool inVoid            // are we currently in a void method
  private Bool inFieldInit := false // are we currently in a field initializer
  private TypeDef curType        // current TypeDef scope
  private MethodDef curMethod    // current MethodDef scope
  private ClosureExpr curClosure // current ClosureExpr if inside closure
  private Int closureCount       // number of closures parsed inside curMethod
  private ClosureExpr[] closures // list of all closures parsed

}