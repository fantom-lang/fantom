//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    2 Dec 05  Brian Frank  Creation
//   17 Sep 06  Brian Frank  Ported from Java to Fan
//

**
** CheckErrors walks the tree of statements and expressions looking
** for errors the compiler can detect such as invalid type usage.  We
** attempt to leave all the error reporting to this step, so that we
** can batch report as many errors as possible.
**
** Since CheckErrors already performs a full tree walk down to each leaf
** expression, we also do a couple of other AST decorations in this step:
**   1) add temp local for field assignments like return ++x
**   2) add temp local for returns inside protected region
**   3) check for field accessor optimization
**   4) check for field storage requirements
**   5) add implicit coersions: auto-casts, boxing, to non-nullable
**   6) implicit call to toImmutable when assigning to const field
**   7) mark ClosureExpr.setsConst
**
class CheckErrors : CompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Compiler compiler)
    : super(compiler)
  {
    this.isSys = compiler.isSys
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    log.debug("CheckErrors")
    walk(types, VisitDepth.expr)
    bombIfErr
  }

//////////////////////////////////////////////////////////////////////////
// TypeDef
//////////////////////////////////////////////////////////////////////////

  override Void visitTypeDef(TypeDef t)
  {
    // check type flags
    checkTypeFlags(t)

    // check for abstract slots in concrete class
    checkAbstractSlots(t)

    // check for const slots in const class
    checkConstType(t)

    // if type extends from any FFI types then give bridge a hook
    foreign := t.foreignInheritance
    if (foreign != null) foreign.bridge.checkType(t)

    // check some knuckle head doesn't override type
    if (t.slotDef("type") != null && !compiler.isSys)
      err("Cannot override Obj.type()", t.slotDef("type").location)

    // check inheritance
    if (t.base != null) checkBase(t, t.base)
    t.mixins.each |CType m| { checkMixin(t, m) }
  }

  private Void checkTypeFlags(TypeDef t)
  {
    flags := t.flags
    loc := t.location

    // these modifiers are never allowed on a type
    if (flags & FConst.Ctor != 0)      err("Cannot use 'new' modifier on type", loc)
    if (flags & FConst.Native != 0)    err("Cannot use 'native' modifier on type", loc)
    if (flags & Parser.Once != 0)      err("Cannot use 'once' modifier on type", loc)
    if (flags & FConst.Override != 0)  err("Cannot use 'override' modifier on type", loc)
    if (flags & FConst.Private != 0)   err("Cannot use 'private' modifier on type", loc)
    if (flags & FConst.Protected != 0) err("Cannot use 'protected' modifier on type", loc)
    if (flags & FConst.Static != 0)    err("Cannot use 'static' modifier on type", loc)
    if (flags & FConst.Virtual != 0)   err("Cannot use 'virtual' modifier on type", loc)
    if (flags & Parser.Readonly != 0)  err("Cannot use 'readonly' modifier on type", loc)

    // check invalid protection combinations
    checkProtectionFlags(flags, loc)

    // check abstract and final
    if ((flags & FConst.Abstract != 0) && (flags & FConst.Final != 0))
      err("Invalid combination of 'abstract' and 'final' modifiers", loc)
  }

  private Void checkAbstractSlots(TypeDef t)
  {
    // if already abstract, nothing to check
    if (t.isAbstract) return

    errForDef := false
    closure := |CSlot slot|
    {
      if (!slot.isAbstract) return
      if (slot.parent === t)
      {
        if (!errForDef)
        {
          err("Class '$t.name' must be abstract since it contains abstract slots", t.location)
          errForDef = true
        }
      }
      else
      {
        err("Class '$t.name' must be abstract since it inherits but doesn't override '$slot.qname'", t.location)
      }
    }

    if (compiler.input.isTest)
      t.slots.values.sort.each(closure)
    else
      t.slots.each(closure)
  }

  private Void checkConstType(TypeDef t)
  {
    // if not const then nothing to check
    if (!t.isConst) return

    // const class cannot inherit from non-const class
    if (t.base != null && t.base != ns.objType && !t.base.isConst)
      err("Const type '$t.name' cannot subclass non-const class '$t.base.name'", t.location)

    // check that each field is const or has no storage; don't
    // worry about statics because they are forced to be const
    // in another check
    t.fieldDefs.each |FieldDef f|
    {
      if (!f.isConst && !f.isStatic && f.isStorage && !isSys)
        err("Const type '$t.name' cannot contain non-const field '$f.name'", f.location)
    }

    // check that no once methods
    t.methodDefs.each |MethodDef m|
    {
      if (m.isOnce)
        err("Const type '$t.name' cannot contain once method '$m.name'", m.location)
    }
  }

  private Void checkBase(TypeDef t, CType base)
  {
    // check that a public class doesn't subclass from internal classes
    if (t.isPublic && !base.isPublic)
      err("Public type '$t.name' cannot extend from internal class '$base.name'", t.location)

    // if base is const, then t must be const
    if (!t.isConst && base.isConst)
      err("Non-const type '$t.name' cannot subclass const class '$base.name'", t.location)
  }

  private Void checkMixin(TypeDef t, CType m)
  {
    // check that a public class doesn't implement from internal mixin
    if (t.isPublic && !m.isPublic)
      err("Public type '$t.name' cannot implement internal mixin '$m.name'", t.location)

    // if mixin is const, then t must be const
    if (!t.isConst && m.isConst)
      err("Non-const type '$t.name' cannot implement const mixin '$m.name'", t.location)
  }

//////////////////////////////////////////////////////////////////////////
// FieldDef
//////////////////////////////////////////////////////////////////////////

  override Void visitFieldDef(FieldDef f)
  {
    // if this field overrides a concrete field,
    // then it never gets its own storage
    if (f.concreteBase != null)
      f.flags &= ~FConst.Storage

    // check for invalid flags
    checkFieldFlags(f)

    // mixins cannot have non-abstract fields
    if (curType.isMixin && !f.isAbstract && !f.isStatic)
      err("Mixin field '$f.name' must be abstract", f.location)

    // abstract field cannot have initialization
    if (f.isAbstract && f.init != null)
      err("Abstract field '$f.name' cannot have initializer", f.init.location)

    // abstract field cannot have getter/setter
    if (f.isAbstract && (f.hasGet || f.hasSet))
      err("Abstract field '$f.name' cannot have getter or setter", f.location)

    // check internal type
    checkTypeProtection(f.fieldType, f.location)

    // check that public field isn't using internal type
    if (curType.isPublic && (f.isPublic || f.isProtected) && !f.fieldType.isPublic)
      err("Public field '${curType.name}.${f.name}' cannot use internal type '$f.fieldType'", f.location);
  }

  private Void checkFieldFlags(FieldDef f)
  {
    flags := f.flags
    loc   := f.location

    // these modifiers are never allowed on a field
    if (flags & FConst.Ctor != 0)    err("Cannot use 'new' modifier on field", loc)
    if (flags & FConst.Final != 0)   err("Cannot use 'final' modifier on field", loc)
    if (flags & Parser.Once != 0)    err("Cannot use 'once' modifier on field", loc)

    // check invalid protection combinations
    checkProtectionFlags(flags, loc)

    // if native
    if (flags & FConst.Native != 0)
    {
      if (flags & FConst.Const != 0) err("Invalid combination of 'native' and 'const' modifiers", loc)
      if (flags & FConst.Abstract != 0) err("Invalid combination of 'native' and 'abstract' modifiers", loc)
      if (flags & FConst.Static != 0) err("Invalid combination of 'native' and 'static' modifiers", loc)
    }

    // if const
    if (flags & FConst.Const != 0)
    {
      // invalid const flag combo
      if (flags & FConst.Abstract != 0) err("Invalid combination of 'const' and 'abstract' modifiers", loc)
      else if (flags & FConst.Virtual != 0 && flags & FConst.Override == 0) err("Invalid combination of 'const' and 'virtual' modifiers", loc)

      // invalid type
      if (!isConstFieldType(f.fieldType))
        err("Const field '$f.name' has non-const type '$f.fieldType'", loc)
    }
    else
    {
      // static fields must be const
      if (flags & FConst.Static != 0) err("Static field '$f.name' must be const", loc)
    }

    // check invalid protection combinations on setter (getter
    // can no modifiers which is checked in the parser)
    if (f.setter != null)
    {
      fieldProtection  := flags & ~Parser.ProtectionMask
      setterProtection := f.set.flags & ~Parser.ProtectionMask
      if (fieldProtection != setterProtection)
      {
        // verify protection flag combinations
        checkProtectionFlags(f.set.flags, loc)

        // verify that setter has narrowed protection
        if (fieldProtection & FConst.Private != 0)
        {
          if (setterProtection & FConst.Public != 0)    err("Setter cannot have wider visibility than the field", loc)
          if (setterProtection & FConst.Protected != 0) err("Setter cannot have wider visibility than the field", loc)
          if (setterProtection & FConst.Internal != 0)  err("Setter cannot have wider visibility than the field", loc)
        }
        else if (fieldProtection & FConst.Internal != 0)
        {
          if (setterProtection & FConst.Public != 0)    err("Setter cannot have wider visibility than the field", loc)
          if (setterProtection & FConst.Protected != 0) err("Setter cannot have wider visibility than the field", loc)
        }
        else if (fieldProtection & FConst.Protected != 0)
        {
          if (setterProtection & FConst.Public != 0)    err("Setter cannot have wider visibility than the field", loc)
        }
      }
    }
  }

  private Bool isConstFieldType(CType t)
  {
    if (t.isConst) return true
    if (t.isObj) return true
    t = t.deref.toNonNullable

    if (t is ListType)
    {
      // allow list types since they are checked to toImmutable at runtime
      //list := t as ListType
      //return isConstFieldType(f, list.v)
      return true
    }

    if (t is MapType)
    {
      // allow list types since they are checked to toImmutable at runtime
      //map := t as MapType
      //return isConstFieldType(f, map.k) && isConstFieldType(fmap.v)
      return true
    }

    if (t.isFunc)
    {
      return true
    }

    return false
  }

//////////////////////////////////////////////////////////////////////////
// MethodDef
//////////////////////////////////////////////////////////////////////////

  override Void visitMethodDef(MethodDef m)
  {
    // check invalid use of flags
    checkMethodFlags(m)

    // check parameters
    checkParams(m)

    // check return
    checkMethodReturn(m)

    // check ctors call super (or another this) ctor
    if (m.isCtor()) checkCtor(m)

    // check types used in signature
    if (!m.isAccessor)
    {
      checkTypeProtection(m.returnType, m.location)
      m.paramDefs.each |ParamDef p| { checkTypeProtection(p.paramType, p.location) }
    }

    // check that public method isn't using internal types in its signature
    if (!m.isAccessor && curType.isPublic && (m.isPublic || m.isProtected))
    {
      if (!m.returnType.isPublic) err("Public method '${curType.name}.${m.name}' cannot use internal type '$m.returnType'", m.location);
      m.paramDefs.each |ParamDef p|
      {
        if (!p.paramType.isPublic) err("Public method '${curType.name}.${m.name}' cannot use internal type '$p.paramType'", m.location);
      }
    }
  }

  private Void checkMethodFlags(MethodDef m)
  {
    // check field accessors in checkFieldFlags
    if (m.isFieldAccessor) return

    flags := m.flags
    loc := m.location

    // these modifiers are never allowed on a method
    if (flags & FConst.Final != 0)     err("Cannot use 'final' modifier on method", loc)
    if (flags & FConst.Const != 0)     err("Cannot use 'const' modifier on method", loc)
    if (flags & Parser.Readonly != 0)  err("Cannot use 'readonly' modifier on method", loc)

    // check invalid protection combinations
    checkProtectionFlags(flags, loc)

    // check invalid constructor flags
    if (flags & FConst.Ctor != 0)
    {
      if (flags & FConst.Abstract != 0) err("Invalid combination of 'new' and 'abstract' modifiers", loc)
      else if (flags & FConst.Override != 0) err("Invalid combination of 'new' and 'override' modifiers", loc)
      else if (flags & FConst.Virtual != 0) err("Invalid combination of 'new' and 'virtual' modifiers", loc)
      if (flags & Parser.Once != 0)     err("Invalid combination of 'new' and 'once' modifiers", loc)
      if (flags & FConst.Native != 0)   err("Invalid combination of 'new' and 'native' modifiers", loc)
      if (flags & FConst.Static != 0)   err("Invalid combination of 'new' and 'static' modifiers", loc)
    }

    // check invalid static flags
    if (flags & FConst.Static != 0)
    {
      if (flags & FConst.Abstract != 0) err("Invalid combination of 'static' and 'abstract' modifiers", loc)
      else if (flags & FConst.Override != 0) err("Invalid combination of 'static' and 'override' modifiers", loc)
      else if (flags & FConst.Virtual != 0) err("Invalid combination of 'static' and 'virtual' modifiers", loc)
      if (flags & Parser.Once != 0) err("Invalid combination of 'static' and 'once' modifiers", loc)
    }

    // check invalid abstract flags
    if (flags & FConst.Abstract != 0)
    {
      if (flags & FConst.Native != 0) err("Invalid combination of 'abstract' and 'native' modifiers", loc)
      if (flags & Parser.Once != 0) err("Invalid combination of 'abstract' and 'once' modifiers", loc)
    }

    // mixins cannot have once methods
    if (flags & Parser.Once != 0)
    {
      if (curType.isMixin)
        err("Mixins cannot have once methods", m.location)
    }

    // normalize method flags after checking
    if (m.flags & FConst.Static != 0)
      m.flags |= FConst.Const;
  }

  private Void checkParams(MethodDef m)
  {
    // check that defs are contiguous after first one
    seenDef := false
    m.paramDefs.each |ParamDef p|
    {
      checkParam(p)
      if (seenDef)
      {
        if (p.def == null)
          err("Parameter '$p.name' must have default", p.location)
      }
      else
      {
        seenDef = p.def != null
      }
    }
  }

  private Void checkParam(ParamDef p)
  {
    // check type
    t := p.paramType
    if (t.isVoid) { err("Cannot use Void as parameter type", p.location); return }
    if (t.isThis)  { err("Cannot use This as parameter type", p.location); return }
    if (t.toNonNullable.signature != "|sys::This->sys::Void|") checkValidType(p.location, t)

    // check parameter default type
    if (p.def != null)
    {
      p.def = coerce(p.def, p.paramType) |,|
      {
        err("'$p.def.toTypeStr' is not assignable to '$p.paramType'", p.def.location)
      }
    }
  }

  private Void checkMethodReturn(MethodDef m)
  {
    if (m.ret.isThis)
    {
      if (m.isStatic)
        err("Cannot return This from static method", m.location)

      if (m.ret.isNullable)
        err("This type cannot be nullable", m.location)
    }

    if (!m.ret.isThis && !m.ret.isVoid)
      checkValidType(m.location, m.ret)
  }

  private Void checkCtor(MethodDef m)
  {
    // mixins cannot have constructors
    if (curType.isMixin)
      err("Mixins cannot have constructors", m.location)

    // ensure super/this constructor is called
    if (m.ctorChain == null && !compiler.isSys && !curType.base.isObj && !curType.isSynthetic)
      err("Must call super class constructor in '$m.name'", m.location)
  }

//////////////////////////////////////////////////////////////////////////
// Statements
//////////////////////////////////////////////////////////////////////////

  override Void enterStmt(Stmt stmt)
  {
    if (stmt.id == StmtId.tryStmt) protectedRegionDepth++
  }

  override Void exitStmt(Stmt stmt)
  {
    if (stmt.id == StmtId.tryStmt) protectedRegionDepth--
  }

  override Void enterFinally(TryStmt stmt)
  {
    finallyDepth++
  }

  override Void exitFinally(TryStmt stmt)
  {
    finallyDepth--
  }

  override Stmt[]? visitStmt(Stmt stmt)
  {
    switch (stmt.id)
    {
      case StmtId.expr:          checkExprStmt((ExprStmt)stmt)
      case StmtId.localDef:      checkLocalDef((LocalDefStmt)stmt)
      case StmtId.ifStmt:        checkIf((IfStmt)stmt)
      case StmtId.returnStmt:    checkReturn((ReturnStmt)stmt)
      case StmtId.throwStmt:     checkThrow((ThrowStmt)stmt)
      case StmtId.forStmt:       checkFor((ForStmt)stmt)
      case StmtId.whileStmt:     checkWhile((WhileStmt)stmt)
      case StmtId.breakStmt:     checkBreak((BreakStmt)stmt)
      case StmtId.continueStmt:  checkContinue((ContinueStmt)stmt)
      case StmtId.tryStmt:       checkTry((TryStmt)stmt)
      case StmtId.switchStmt:    checkSwitch((SwitchStmt)stmt)
    }
    return null
  }

  private Void checkExprStmt(ExprStmt stmt)
  {
    if (!stmt.expr.isStmt)
      err("Not a statement", stmt.expr.location)
  }

  private Void checkLocalDef(LocalDefStmt stmt)
  {
    // check not Void
    t := stmt.ctype
    if (t.isVoid) { err("Cannot use Void as local variable type", stmt.location); return }
    if (t.isThis) { err("Cannot use This as local variable type", stmt.location); return }
    checkValidType(stmt.location, t)
  }

  private Void checkIf(IfStmt stmt)
  {
    stmt.condition = coerce(stmt.condition, ns.boolType) |,|
    {
      err("If condition must be Bool, not '$stmt.condition.ctype'", stmt.condition.location)
    }
  }

  private Void checkThrow(ThrowStmt stmt)
  {
    stmt.exception = coerce(stmt.exception, ns.errType) |,|
    {
      err("Must throw Err, not '$stmt.exception.ctype'", stmt.exception.location)
    }
  }

  private Void checkFor(ForStmt stmt)
  {
    if (stmt.condition != null)
    {
      stmt.condition = coerce(stmt.condition, ns.boolType) |,|
      {
        err("For condition must be Bool, not '$stmt.condition.ctype'", stmt.condition.location)
      }
    }
  }

  private Void checkWhile(WhileStmt stmt)
  {
    stmt.condition = coerce(stmt.condition, ns.boolType) |,|
    {
      err("While condition must be Bool, not '$stmt.condition.ctype'", stmt.condition.location)
    }
  }

  private Void checkBreak(BreakStmt stmt)
  {
    if (stmt.loop == null)
      err("Break outside of loop (break is implicit in switch)", stmt.location)

    // can't leave control of a finally block
    if (finallyDepth > 0)
      err("Cannot leave finally block", stmt.location)
  }

  private Void checkContinue(ContinueStmt stmt)
  {
    if (stmt.loop == null)
      err("Continue outside of loop", stmt.location)

    // can't leave control of a finally block
    if (finallyDepth > 0)
      err("Cannot leave finally block", stmt.location)
  }

  private Void checkReturn(ReturnStmt stmt)
  {
    ret := curMethod.ret
    if (stmt.expr == null)
    {
      // this is just a sanity check - it should be caught in parser
      if (!ret.isVoid)
        err("Must return a value from non-Void method", stmt.location)
    }
    else if (ret.isThis)
    {
      if (!stmt.expr.ctype.fits(curType))
        err("Cannot return '$stmt.expr.toTypeStr' as $curType This", stmt.expr.location)
    }
    else
    {
      stmt.expr = coerce(stmt.expr, ret) |,|
      {
        err("Cannot return '$stmt.expr.toTypeStr' as '$ret'", stmt.expr.location)
      }
    }

    // can't use return inside an it-block (might be confusing)
    if (!stmt.isSynthetic && curType.isClosure && curType.closure.isItBlock)
      err("Cannot use return inside it-block", stmt.location)

    // can't leave control of a finally block
    if (finallyDepth > 0)
      err("Cannot leave finally block", stmt.location)

    // add temp local var if returning from a protected region,
    // we always call this variable "$return" and reuse it if
    // already declared by a previous return
    if (stmt.expr != null && protectedRegionDepth > 0)
    {
      v := curMethod.vars.find |MethodVar v->Bool| { return v.name == "\$return" }
      if (v == null) v = curMethod.addLocalVar(stmt.expr.ctype, "\$return", null)
      stmt.leaveVar = v
    }
  }

  private Void checkTry(TryStmt stmt)
  {
    // check that try block not empty
    if (stmt.block.isEmpty)
      err("Try block cannot be empty", stmt.location)

    // check each catch
    caught := CType[,]
    stmt.catches.each |Catch c|
    {
      CType? errType := c.errType
      if (errType == null) errType = ns.errType
      if (!errType.fits(ns.errType))
        err("Must catch Err, not '$c.errType'", c.errType.location)
      else if (errType.fitsAny(caught))
        err("Already caught '$errType'", c.location)
      caught.add(errType)
    }
  }

  private Void checkSwitch(SwitchStmt stmt)
  {
    dups := Int:Int[:]

    stmt.cases.each |Case c|
    {
      for (i:=0; i<c.cases.size; ++i)
      {
        expr := c.cases[i]

        // check comparability of condition and each case
        checkCompare(expr, stmt.condition)

        // check for dups
        literal := expr.asTableSwitchCase
        if (literal != null)
        {
          if (dups[literal] == null)
            dups[literal] = literal
          else
            err("Duplicate case label", expr.location)
        }
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Expr
//////////////////////////////////////////////////////////////////////////

  override Expr visitExpr(Expr expr)
  {
    switch (expr.id)
    {
      case ExprId.typeLiteral:    checkTypeLiteral((LiteralExpr)expr)
      case ExprId.slotLiteral:    checkSlotLiteral((SlotLiteralExpr)expr)
      case ExprId.listLiteral:    checkListLiteral((ListLiteralExpr)expr)
      case ExprId.mapLiteral:     checkMapLiteral((MapLiteralExpr)expr)
      case ExprId.rangeLiteral:   checkRangeLiteral((RangeLiteralExpr)expr)
      case ExprId.boolNot:        checkBool((UnaryExpr)expr)
      case ExprId.cmpNull:
      case ExprId.cmpNotNull:     checkCompareNull((UnaryExpr)expr)
      case ExprId.assign:         checkAssign((BinaryExpr)expr)
      case ExprId.elvis:          checkElvis((BinaryExpr)expr)
      case ExprId.boolOr:
      case ExprId.boolAnd:        checkBools((CondExpr)expr)
      case ExprId.same:
      case ExprId.notSame:        checkSame((BinaryExpr)expr)
      case ExprId.shortcut:       checkShortcut((ShortcutExpr)expr)
      case ExprId.call:           checkCall((CallExpr)expr)
      case ExprId.construction:   checkConstruction((CallExpr)expr)
      case ExprId.field:          checkField((FieldExpr)expr)
      case ExprId.thisExpr:       checkThis((ThisExpr)expr)
      case ExprId.superExpr:      checkSuper((SuperExpr)expr)
      case ExprId.isExpr:
      case ExprId.isnotExpr:
      case ExprId.asExpr:
      case ExprId.coerce:         checkTypeCheck((TypeCheckExpr)expr)
      case ExprId.ternary:        checkTernary((TernaryExpr)expr)
    }
    return expr
  }

  private Void checkTypeLiteral(LiteralExpr expr)
  {
    checkTypeProtection((CType)expr.val, expr.location)
  }

  private Void checkSlotLiteral(SlotLiteralExpr expr)
  {
    checkSlotProtection(expr.slot, expr.location)
  }

  private Void checkListLiteral(ListLiteralExpr expr)
  {
    // check the types and ensure that everything gets boxed
    listType := (ListType)expr.ctype
    valType := listType.v
    expr.vals.each |Expr val, Int i|
    {
      expr.vals[i] = coerceBoxed(val, valType) |,|
      {
        err("Invalid value type '$val.toTypeStr' for list of '$valType'", val.location)
      }
    }
  }

  private Void checkMapLiteral(MapLiteralExpr expr)
  {
    // check the types and ensure that everything gets boxed
    mapType := (MapType)expr.ctype
    keyType := mapType.k
    valType := mapType.v
    expr.keys.each |Expr key, Int i|
    {
      expr.keys[i] = coerceBoxed(key, keyType) |,|
      {
        err("Invalid key type '$key.toTypeStr' for map type '$mapType'", key.location)
      }

      val := expr.vals[i]
      expr.vals[i] = coerceBoxed(val, valType) |,|
      {
        err("Invalid value type '$val.toTypeStr' for map type '$mapType'", val.location)
      }
    }
  }

  private Void checkRangeLiteral(RangeLiteralExpr range)
  {
    range.start = coerce(range.start, ns.intType) |,|
    {
      err("Range must be Int..Int, not '${range.start.ctype}..${range.end.ctype}'", range.location)
    }
    range.end = coerce(range.end, ns.intType) |,|
    {
      err("Range must be Int..Int, not '${range.start.ctype}..${range.end.ctype}'", range.location)
    }
  }

  private Void checkBool(UnaryExpr expr)
  {
    expr.operand = coerce(expr.operand, ns.boolType) |,|
    {
      err("Cannot apply '$expr.opToken.symbol' operator to '$expr.operand.ctype'", expr.location)
    }
  }

  private Void checkCompareNull(UnaryExpr expr)
  {
    t := expr.operand.ctype
    if (!t.isNullable)
      err("Comparison of non-nullable type '$t' to null", expr.location)
  }

  private Void checkBools(CondExpr expr)
  {
    expr.operands.each |Expr operand, Int i|
    {
      expr.operands[i] = coerce(operand, ns.boolType) |,|
      {
        err("Cannot apply '$expr.opToken.symbol' operator to '$operand.ctype'", operand.location)
      }
    }
  }

  private Void checkSame(BinaryExpr expr)
  {
    checkCompare(expr.lhs, expr.rhs)

    // don't allow for value types
    if (expr.lhs.ctype.isValue || expr.rhs.ctype.isValue)
      err("Cannot use '$expr.opToken.symbol' operator with value types", expr.location)
  }

  private Bool checkCompare(Expr lhs, Expr rhs)
  {
    if (!lhs.ctype.fits(rhs.ctype) && !rhs.ctype.fits(lhs.ctype))
    {
      err("Incomparable types '$lhs.ctype' and '$rhs.ctype'", lhs.location)
      return false
    }
    return true
  }

  private Void checkAssign(BinaryExpr expr)
  {
    // check that rhs is assignable to lhs
    expr.rhs = coerce(expr.rhs, expr.lhs.ctype) |,|
    {
      err("'$expr.rhs.toTypeStr' is not assignable to '$expr.lhs.ctype'", expr.rhs.location)
    }

    // check that lhs is assignable
    if (!expr.lhs.isAssignable)
      err("Left hand side is not assignable", expr.lhs.location)

    // check not assigning to same variable
    if (expr.lhs.sameVarAs(expr.rhs))
      err("Self assignment", expr.lhs.location)

    // check left hand side field (common code with checkShortcut)
    if (expr.lhs.id === ExprId.field)
      expr.rhs = checkAssignField((FieldExpr)expr.lhs, expr.rhs)

    // check that no safe calls used on entire left hand side
    checkNoNullSafes(expr.lhs)

    // take this opportunity to generate a temp local variable if needed
    if (expr.leave && expr.lhs.assignRequiresTempVar)
      expr.tempVar = curMethod.addLocalVar(expr.lhs.ctype, null, null)
  }

  private Void checkElvis(BinaryExpr expr)
  {
    if (!expr.lhs.ctype.isNullable)
      err("Cannot use '?:' operator on non-nullable type '$expr.lhs.ctype'", expr.location)

    expr.rhs = coerce(expr.rhs, expr.ctype) |,|
    {
      err("Cannot coerce '$expr.rhs.toTypeStr' to '$expr.ctype'", expr.rhs.location);
    }
  }

  private Void checkNoNullSafes(Expr? x)
  {
    while (x is NameExpr)
    {
      ne := (NameExpr)x
      if (ne.isSafe) err("Null-safe operator on left hand side of assignment", x.location)
      x = ne.target
    }
  }

  private Void checkShortcut(ShortcutExpr shortcut)
  {
    switch (shortcut.opToken)
    {
      // comparable
      case Token.eq: case Token.notEq:
      case Token.gt: case Token.gtEq:
      case Token.lt: case Token.ltEq:
      case Token.cmp:
        if (!checkCompare(shortcut.target, shortcut.args.first)) return
    }

    // if assignment
    if (shortcut.isAssign)
    {
      // check that lhs is assignable
      if (!shortcut.target.isAssignable)
        err("Target is not assignable", shortcut.target.location)

      // check left hand side field (common code with checkAssign)
      if (shortcut.target.id === ExprId.field)
        checkAssignField((FieldExpr)shortcut.target, shortcut.args.first)

      // check that no safe calls used on entire left hand side
      checkNoNullSafes(shortcut.target)
    }

    // take this oppotunity to generate a temp local variable if needed
    if (shortcut.leave && shortcut.isAssign && shortcut.target.assignRequiresTempVar)
      shortcut.tempVar = curMethod.addLocalVar(shortcut.ctype, null, null)

    // perform normal call checking
    if (!shortcut.isCompare)
      checkCall(shortcut)
  }

  ** Check if field is assignable, return new rhs.
  private Expr? checkAssignField(FieldExpr lhs, Expr? rhs)
  {
    field := ((FieldExpr)lhs).field

    // check protection scope (which might be more narrow than the scope
    // of the entire field as checked in checkProtection by checkField)
    if (field.setter != null && slotProtectionErr(field) == null)
      checkSlotProtection(field.setter, lhs.location, true)

    // if not-const we are done
    if (!field.isConst) return rhs

    // for purposes of const field checking, consider closures
    // inside a constructor or static initializer to be ok
    inType := curType
    inMethod := curMethod
    if (inType.isClosure)
    {
      curType.closure.setsConst = true
      inType = inType.closure.enclosingType
      inMethod = (curType.closure.enclosingSlot as MethodDef) ?: curMethod
    }

    // check attempt to set static field outside of static initializer
    if (field.isStatic && !inMethod.isStaticInit)
    {
      err("Cannot set const static field '$field.name' outside of static initializer", lhs.location)
      return rhs
    }

    // we allow setting an instance ctor field in an
    // it-block, otherwise dive in for further checking
    if (!(curType.isClosure && curType.closure.isItBlock))
    {
      // check attempt to set field outside of owning class
      if (field.parent != inType)
      {
        err("Cannot set const field '$field.qname'", lhs.location)
        return rhs
      }

      // check attempt to set instance field outside of ctor
      if (!field.isStatic && !(inMethod.isInstanceInit || inMethod.isCtor))
      {
        err("Cannot set const field '$field.name' outside of constructor", lhs.location)
        return rhs
      }
    }

    // any other errors should already be logged at this point (see isConstFieldType)

    // if List/Map make an implicit call toImmutable
    ftype := field.fieldType
    if (ftype.isList) return implicitToImmutable(ftype, rhs, ns.listToImmutable)
    if (ftype.isMap)  return implicitToImmutable(ftype, rhs, ns.mapToImmutable)
    if (ftype.isFunc) return implicitToImmutable(ftype, rhs, ns.funcToImmutable)
    return rhs
  }

  private Expr implicitToImmutable(CType fieldType, Expr rhs, CMethod toImmutable)
  {
    // leave null literal as is
    if (rhs.id == ExprId.nullLiteral) return rhs

    // leave type literal as is
    if (fieldType == ns.typeType && rhs.id == ExprId.typeLiteral) return rhs

    // wrap existing assigned with call toImmutable
    return CallExpr.makeWithMethod(rhs.location, rhs, toImmutable) { isSafe = true }
  }

  private Void checkConstruction(CallExpr call)
  {
    if (!call.method.isCtor)
    {
      // check that ctor method is the expected type
      if (call.ctype.toNonNullable != call.method.returnType.toNonNullable)
        err("Construction method '$call.method.qname' must return '$call.ctype.name'", call.location)

      // but allow ctor to be typed as nullable
      call.ctype = call.method.returnType
    }

    checkCall(call)
  }

  private Void checkCall(CallExpr call)
  {
    m := call.method
    if (m == null)
    {
      err("Something wrong with method call?", call.location)
      return
    }

    name := m.name

    // check protection scope
    checkSlotProtection(call.method, call.location)

    // if a foreign function, then verify we aren't using unsupported types
    if (m.isForeign)
    {
      // just log one use of unsupported return or param type and return
      if (!m.returnType.isSupported)
      {
        err("Method '$name' uses unsupported type '$m.returnType'", call.location)
        return
      }
      unsupported := m.params.find |CParam p->Bool| { return !p.paramType.isSupported }
      if (unsupported != null)
      {
        err("Method '$name' uses unsupported type '$unsupported.paramType'", call.location)
        return
      }
    }

    // arguments
    if (!call.isDynamic)
    {
      // do normal call checking and coercion
      checkArgs(call)
    }
    else
    {
      // if dynamic all ensure all the args are boxed
      call.args.each |Expr arg, Int i| { call.args[i] = box(call.args[i]) }
    }

    // if constructor
    if (m.isCtor && !call.isCtorChain)
    {
      // ensure we aren't calling constructors on an instance
      if (call.target != null && call.target.id !== ExprId.staticTarget && !call.target.synthetic)
        err("Cannot call constructor '$name' on instance", call.location)

      // ensure we aren't calling a constructor on an abstract class
      if (m.parent.isAbstract)
        err("Calling constructor on abstract class", call.location)
    }

    // ensure we aren't calling static methods on an instance
    if (m.isStatic)
    {
      if (call.target != null && call.target.id !== ExprId.staticTarget)
        err("Cannot call static method '$name' on instance", call.location)
    }

    // ensure we can't calling an instance method statically
    if (!m.isStatic && !m.isCtor)
    {
      if (call.target == null || call.target.id === ExprId.staticTarget)
        err("Cannot call instance method '$name' in static context", call.location)
    }

    // if using super
    if (call.target != null && call.target.id === ExprId.superExpr)
    {
      // check that super is concrete
      if (m.isAbstract)
        err("Cannot use super to call abstract method '$m.qname'", call.target.location)

      // check that calling super with exact param match otherwise stack overflow
      if (call.args.size != m.params.size && m.name == curMethod.name && !m.isCtor)
        err("Must call super method '$m.qname' with exactly $m.params.size arguments", call.target.location)
    }

    // don't allow safe calls on non-nullable type
    if (call.isSafe && call.target != null && !call.target.ctype.isNullable)
      err("Cannot use null-safe call on non-nullable type '$call.target.ctype'", call.target.location)

    // if calling a method on a value-type, ensure target is
    // coerced to non-null; we don't do this for comparisons
    // and safe calls since they are handled specially
    if (call.target != null && !call.isCompare && !call.isSafe)
    {
      if (call.target.ctype.isValue || call.method.parent.isValue)
        call.target = coerce(call.target, call.method.parent) |,| {}
    }
  }

  private Void checkField(FieldExpr f)
  {
    field := f.field

    // check protection scope
    checkSlotProtection(field, f.location)

    // if a FFI, then verify we aren't using unsupported types
    if (!field.fieldType.isSupported)
    {
      err("Field '$field.name' has unsupported type '$field.fieldType'", f.location)
      return
    }

    // ensure we aren't calling static methods on an instance
    if (field.isStatic)
    {
      if (f.target != null && f.target.id !== ExprId.staticTarget)
        err("Cannot access static field '$f.name' on instance", f.location)
    }

    // if instance field
    else
    {
      if (f.target == null || f.target.id === ExprId.staticTarget)
        err("Cannot access instance field '$f.name' in static context", f.location)
    }

    // if using super check that concrete
    if (f.target != null && f.target.id === ExprId.superExpr)
    {
      if (field.isAbstract)
        err("Cannot use super to access abstract field '$field.qname'", f.target.location)
    }

    // don't allow safe access on non-nullable type
    if (f.isSafe && f.target != null && !f.target.ctype.isNullable)
      err("Cannot use null-safe access on non-nullable type '$f.target.ctype'", f.target.location)

    // if using the field's accessor method
    if (f.useAccessor)
    {
      // check if we can optimize out the accessor (required for constants)
      f.useAccessor = useFieldAccessor(field)

      // check that we aren't using an field accessor inside of itself
      if (curMethod != null && (field.getter === curMethod || field.setter === curMethod))
        err("Cannot use field accessor inside accessor itself - use '@' operator", f.location)
    }

    // if accessing storage directly
    else
    {
      // check that the current class gets access to direct
      // field storage (only defining class gets it); allow closures
      // same scope priviledges as enclosing class
      enclosing := curType.isClosure ? curType.closure.enclosingType : curType
      if (!field.isConst && field.parent != curType && field.parent != enclosing)
      {
        err("Field storage for '$field.qname' not accessible", f.location)
      }

      // sanity check that field has storage
      else if (!field.isStorage)
      {
        if (field is FieldDef && ((FieldDef)field).concreteBase != null)
          err("Field storage of inherited field '${field->concreteBase->qname}' not accessible (might try super)", f.location)
        else
          err("Invalid storage access of field '$field.qname' which doesn't have storage", f.location)
      }
    }
  }

  private Bool useFieldAccessor(CField f)
  {
    // if const field then use field directly
    if (f.isConst || f.getter == null) return false

    // always use accessor if field is imported from another
    // pod (in which case it isn't a def in my compilation unit)
    def := f as FieldDef
    if (def == null) return true

    // if virtual/override/native then always use accessor
    if (def.isVirtual || def.isOverride || f.isNative)
      return true

    // if the field has synthetic getter and setter, then
    // we can safely optimize internal field accessors to
    // use field directly
    if (!def.hasGet && !def.hasSet)
      return false

    // use accessor since there is a custom getter or setter
    return true
  }

  private Void checkThis(ThisExpr expr)
  {
    if (inStatic)
      err("Cannot access 'this' in static context", expr.location)
  }

  private Void checkSuper(SuperExpr expr)
  {
    if (inStatic)
      err("Cannot access 'super' in static context", expr.location)

    if (curType.isMixin)
    {
      if (expr.explicitType == null)
        err("Must use named 'super' inside mixin", expr.location)
      else if (!expr.explicitType.isMixin)
        err("Cannot use 'Obj.super' inside mixin (yeah I know - take it up with Sun)", expr.location)
    }

    if (expr.explicitType != null)
    {
      if (!curType.fits(expr.explicitType))
        err("Named super '$expr.explicitType' not a super class of '$curType.name'", expr.location)
    }
  }

  private Void checkTypeCheck(TypeCheckExpr expr)
  {
    // don't bother checking a synthetic coercion that the
    // compiler generated itself (which is most coercions)
    if (expr.synthetic) return

    // verify types are convertible
    check := expr.check
    target := expr.target.ctype
    if (!check.fits(target) && !target.fits(check) && !check.isMixin && !target.isMixin)
      err("Inconvertible types '$target' and '$check'", expr.location)

    // don't allow is, as, isnot (everything but coerce) to be
    // used with value type expressions
    if (expr.id != ExprId.coerce)
    {
      if (target.isValue) err("Cannot use '$expr.opStr' operator on value type '$target'", expr.location)
    }
  }

  private Void checkTernary(TernaryExpr expr)
  {
    expr.condition = coerce(expr.condition, ns.boolType) |,|
    {
      err("Ternary condition must be Bool, not '$expr.condition.ctype'", expr.condition.location)
    }
    expr.trueExpr = coerce(expr.trueExpr, expr.ctype) |,|
    {
      err("Ternary true expr '$expr.trueExpr.toTypeStr' cannot be coerced to $expr.ctype", expr.trueExpr.location)
    }
    expr.falseExpr = coerce(expr.falseExpr, expr.ctype) |,|
    {
      err("Ternary falseexpr '$expr.falseExpr.toTypeStr' cannot be coerced to $expr.ctype", expr.falseExpr.location)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Check Args
//////////////////////////////////////////////////////////////////////////

  private Void checkArgs(CallExpr call)
  {
    method := call.method
    name := call.name
    args := call.args
    newArgs := args.dup
    isErr := false
    params := method.params
    genericParams := method.isParameterized ? method.generic.params : null

    // if we are calling callx(A, B...) on a FuncType, then
    // use the first class Func signature rather than the
    // version of callx which got picked because we might have
    // picked the wrong callx version
    sig := method.parent as FuncType
    if (sig != null && name.startsWith("call") && name.size == 5)
    {
      if (sig.params.size != args.size)
      {
        isErr = true
      }
      else
      {
        // assume any use of 'This' in the function signature has already
        // been checked to ensure that it parameterizes to current scope
// TODO-IT: not sure this works right
        sig = sig.parameterizeThis(curType)
        sig.params.each |CType p, Int i|
        {
          // check each argument and ensure boxed
          newArgs[i] = coerceBoxed(args[i], p) |,| { isErr = true }
        }
      }
    }

    // if more args than params, always an err
    else if (params.size < args.size)
    {
      isErr = true
    }

    // check each arg against each parameter
    else
    {
      params.each |CParam p, Int i|
      {
        if (i >= args.size)
        {
          // param has a default value, then that is ok
          if (!p.hasDefault) isErr = true
        }
        else
        {
          // TODO-IT
          pt := p.paramType
          if (pt.toNonNullable is FuncType && ((FuncType)pt.toNonNullable).usesThis)
            pt = ns.objType.toNullable

          // ensure arg fits parameter type (or auto-cast)
          newArgs[i] = coerce(args[i], pt) |,|
          {
            isErr = name != "compare" // TODO let anything slide for Obj.compare
          }

          // if this a parameterized generic, then we need to box
          // even if the expected type is a value-type (since the
          // actual implementation methods are all Obj based)
          if (!isErr && genericParams != null && genericParams[i].paramType.isGenericParameter)
            newArgs[i] = box(newArgs[i])
        }
      }
    }

    if (!isErr)
    {
      call.args = newArgs
      return
    }

    msg := "Invalid args "
    if (sig != null)
      msg += "|" + sig.params.join(", ") + "|"
    else
      msg += method.nameAndParamTypesToStr
    msg += ", not (" + args.join(", ", |Expr e->Str| { return "$e.toTypeStr" }) + ")"
    err(msg, call.location)
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  private Void checkValidType(Location loc, CType t)
  {
    if (!t.isValid) err("Invalid type '$t'", loc)
  }

//////////////////////////////////////////////////////////////////////////
// Flag Utils
//////////////////////////////////////////////////////////////////////////

  private Void checkProtectionFlags(Int flags, Location loc)
  {
    isPublic    := flags & FConst.Public    != 0
    isProtected := flags & FConst.Protected != 0
    isPrivate   := flags & FConst.Private   != 0
    isInternal  := flags & FConst.Internal  != 0
    isVirtual   := flags & FConst.Virtual   != 0
    isOverride  := flags & FConst.Override  != 0

    if (isPublic)
    {
      if (isProtected) err("Invalid combination of 'public' and 'protected' modifiers", loc)
      if (isPrivate)   err("Invalid combination of 'public' and 'private' modifiers", loc)
      if (isInternal)  err("Invalid combination of 'public' and 'internal' modifiers", loc)
    }
    else if (isProtected)
    {
      if (isPrivate)   err("Invalid combination of 'protected' and 'private' modifiers", loc)
      if (isInternal)  err("Invalid combination of 'protected' and 'internal' modifiers", loc)
    }
    else if (isPrivate)
    {
      if (isInternal)  err("Invalid combination of 'private' and 'internal' modifiers", loc)
      if (isVirtual && !isOverride) err("Invalid combination of 'private' and 'virtual' modifiers", loc)
    }
  }

  private Void checkTypeProtection(CType t, Location loc)
  {
    t = t.toNonNullable

    if (t is GenericType)
    {
      if (t is ListType)
      {
        x := (ListType)t
        checkTypeProtection(x.v, loc)
      }
      else if (t is MapType)
      {
        x := (MapType)t
        checkTypeProtection(x.k, loc)
        checkTypeProtection(x.v, loc)
      }
      else
      {
        x := (FuncType)t
        checkTypeProtection(x.ret, loc)
        x.params.each |CType p| { checkTypeProtection(p, loc) }
      }
    }
    else
    {
      if (t.isInternal && t.pod != curType.pod)
        err("Internal type '$t' not accessible", loc)
    }
  }

  private Void checkSlotProtection(CSlot slot, Location loc, Bool setter := false)
  {
    errMsg := slotProtectionErr(slot, setter)
    if (errMsg != null) err(errMsg, loc)
  }

  private Str? slotProtectionErr(CSlot slot, Bool setter := false)
  {
    msg := setter ? "setter of field" : (slot is CMethod ? "method" : "field")

    // short circuit if method on myself
    if (curType == slot.parent)
      return null

    // allow closures same scope priviledges as enclosing class
    myType := curType
    if (myType.isClosure)
      myType = curType.closure.enclosingType

    // consider the slot internal if its parent is internal
    isInternal := slot.isInternal || (slot.parent.isInternal && !slot.parent.isParameterized)

    if (slot.isPrivate && myType != slot.parent)
      return "Private $msg '$slot.qname' not accessible"

    else if (slot.isProtected && !myType.fits(slot.parent))
      return "Protected $msg '$slot.qname' not accessible"

    else if (isInternal && myType.pod != slot.parent.pod)
      return "Internal $msg '$slot.qname' not accessible"

    else
      return null
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Ensure the specified expression is boxed to an object reference.
  **
  private Expr box(Expr expr)
  {
    if (expr.ctype.isValue)
      return TypeCheckExpr.coerce(expr, ns.objType.toNullable)
    else
      return expr
  }

  **
  ** Run the standard coerce method and ensure the result is boxed.
  **
  private Expr coerceBoxed(Expr expr, CType expected, |,| onErr)
  {
    return box(coerce(expr, expected, onErr))
  }

  **
  ** Coerce the target expression to the specified type.  If
  ** the expression is not type compatible run the onErr function.
  **
  Expr coerce(Expr expr, CType expected, |,| onErr)
  {
    // route to bridge for FFI coercion if either side if foreign
    if (expected.isForeign) return expected.bridge.coerce(expr, expected, onErr)
    if (expr.ctype.isForeign) return expr.ctype.bridge.coerce(expr, expected, onErr)

    // normal Fan coercion behavior
    return doCoerce(expr, expected, onErr)
  }

  **
  ** Coerce the target expression to the specified type.  If
  ** the expression is not type compatible run the onErr function.
  ** Default Fan behavior.
  **
  static Expr doCoerce(Expr expr, CType expected, |,| onErr)
  {
    // sanity check that expression has been typed
    CType actual := expr.ctype
    if ((Obj?)actual == null) throw NullErr.make("null ctype: ${expr}")

    // if the same type this is easy
    if (actual == expected) return expr

    // we can never use a void expression
    if (actual.isVoid)
    {
      onErr()
      return expr
    }

    // if expr is null literal, verify expected type is nullable
    if (expr.id === ExprId.nullLiteral)
    {
      if (!expected.isNullable) onErr()
      return expr
    }

    // if the expression fits to type, that is ok
    if (actual.fits(expected))
    {
      // if we have any nullable/value difference we need a coercion
      if (needCoerce(actual, expected))
        return TypeCheckExpr.coerce(expr, expected)
      else
        return expr
    }

    // if we can auto-cast to make the expr fit then do it - we
    // have to treat function auto-casting a little specially here
    if (actual.isFunc && expected.isFunc)
    {
      if (isFuncAutoCoerce(actual, expected))
        return TypeCheckExpr.coerce(expr, expected)
    }
    else
    {
      if (expected.fits(actual))
        return TypeCheckExpr.coerce(expr, expected)
    }

    // we have an error condition
    onErr()
    return expr
  }

  static Bool isFuncAutoCoerce(CType actualType, CType expectedType)
  {
    // check if both are function types
    if (!actualType.isFunc || !expectedType.isFunc) return false
    actual   := (FuncType)actualType.toNonNullable
    expected := (FuncType)expectedType.toNonNullable

    // if actual function requires more parameters than
    // we are expecting, then this cannot be a match
    if (actual.arity > expected.arity) return false

    // check return type
    if (!isFuncAutoCoerceMatch(actual.ret, expected.ret))
      return false

    // check that each parameter is auto-castable
    return actual.params.all |CType actualParam, Int i->Bool|
    {
      expectedParam := expected.params[i]
      return isFuncAutoCoerceMatch(actualParam, expectedParam)
    }

    return true
  }

  static Bool isFuncAutoCoerceMatch(CType actual, CType expected)
  {
    if (actual.fits(expected)) return true
    if (expected.fits(actual)) return true
    if (isFuncAutoCoerce(actual, expected)) return true
    return false
  }

  static Bool needCoerce(CType from, CType to)
  {
    // if either side is a value type and we got past
    // the equals check then we definitely need a coercion
    if (from.isValue || to.isValue) return true

    // if going from Obj? -> Obj we need a nullable coercion
    if (!to.isNullable) return from.isNullable

    return false
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Int protectedRegionDepth := 0  // try statement depth
  private Int finallyDepth := 0          // finally block depth
  private Bool isSys
}