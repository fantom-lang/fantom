//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//

**
** CodeAsm is used to assemble the fcode instructions of an Expr or Block.
**
class CodeAsm : CompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(Compiler compiler, Location location, FPod fpod)
    : super(compiler)
  {
    this.location  = location
    this.fpod      = fpod
    this.code      = Buf.make
    this.errTable  = Buf.make; errTable.writeI2(-1)
    this.errCount  = 0
    this.lines     = Buf.make; lines.writeI2(-1)
    this.lineCount = 0
    this.loopStack = Loop[,]
  }

//////////////////////////////////////////////////////////////////////////
// Statements
//////////////////////////////////////////////////////////////////////////

  Void block(Block block)
  {
    block.stmts.each |Stmt s| { stmt(s) }
  }

  Void stmt(Stmt stmt)
  {
    switch (stmt.id)
    {
      case StmtId.nop:           return
      case StmtId.expr:          expr(((ExprStmt)stmt).expr)
      case StmtId.localDef:      localVarDefStmt((LocalDefStmt)stmt)
      case StmtId.ifStmt:        ifStmt((IfStmt)stmt)
      case StmtId.returnStmt:    returnStmt((ReturnStmt)stmt)
      case StmtId.throwStmt:     throwStmt((ThrowStmt)stmt)
      case StmtId.forStmt:       forStmt((ForStmt)stmt)
      case StmtId.whileStmt:     whileStmt((WhileStmt)stmt)
      case StmtId.breakStmt:     breakOrContinueStmt(stmt)
      case StmtId.continueStmt:  breakOrContinueStmt(stmt)
      case StmtId.switchStmt:    switchStmt((SwitchStmt)stmt)
      case StmtId.tryStmt:       tryStmt((TryStmt)stmt)
      default:                   throw Err.make(stmt.id.toStr)
    }
  }

  private Void ifStmt(IfStmt stmt)
  {
    endLabel := -1
    c := Cond.make

    // optimize: if (true)
    if (stmt.condition.id == ExprId.trueLiteral)
    {
      block(stmt.trueBlock)
      return
    }

    // optimize: if (false)
    if (stmt.condition.id == ExprId.falseLiteral)
    {
      if (stmt.falseBlock != null)
        block(stmt.falseBlock)
      return
    }

    // check condition - if the condition is itself a CondExpr
    // then we just have it branch directly to the true/false
    // block rather than wasting instructions to push true/false
    // onto the stack
    if (stmt.condition is CondExpr)
    {
      cond((CondExpr)stmt.condition, c)
    }
    else
    {
      expr(stmt.condition)
      c.jumpFalses.add(jump(FOp.JumpFalse))
    }

    // true block
    c.jumpTrues.each |Int pos| { backpatch(pos) }
    block(stmt.trueBlock)
    if (!stmt.trueBlock.isExit && stmt.falseBlock != null)
      endLabel = jump(FOp.Jump)

    // false block
    c.jumpFalses.each |Int pos| { backpatch(pos) }
    if (stmt.falseBlock != null)
      block(stmt.falseBlock)

    // end
    if (endLabel !== -1) backpatch(endLabel)
  }

  private Void returnStmt(ReturnStmt stmt)
  {
    // if we are in a protected region, then we can't return immediately,
    // rather we need to save the result into a temporary local; and use
    // a "leave" instruction which we will backpatch in finishCode() with
    // the actual return sequence;
    if (inProtectedRegion)
    {
      // if returning a result then stash in temp local
      if (stmt.expr != null)
      {
        expr(stmt.expr)
        returnLocal = stmt.leaveVar
        op(FOp.StoreVar, returnLocal.register)
      }

      // jump to any finally blocks we are inside
      protectedRegions.eachr |ProtectedRegion region|
      {
        if (region.hasFinally)
          region.jumpFinallys.add(jump(FOp.JumpFinally))
      }

      // generate leave instruction and register for backpatch
      if (leavesToReturn == null) leavesToReturn = Int[,]
      leavesToReturn.add(jump(FOp.Leave))
      return
    }

    // process as normal return
    if (stmt.expr != null)
    {
      expr(stmt.expr)
      op(FOp.ReturnObj)
    }
    else
    {
      op(FOp.ReturnVoid)
    }
  }

  private Void throwStmt(ThrowStmt stmt)
  {
    expr(stmt.exception)
    op(FOp.Throw)
  }

  private Void localVarDefStmt(LocalDefStmt stmt)
  {
    if (stmt.isCatchVar)
    {
      op(FOp.CatchErrStart, fpod.addTypeRef(stmt.ctype))
      op(FOp.StoreVar,      stmt.var.register)
    }
    else if (stmt.init != null)
    {
      expr(stmt.init)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Loops
//////////////////////////////////////////////////////////////////////////

  private Void whileStmt(WhileStmt stmt)
  {
    // push myself onto the loop stack so that breaks
    // and continues can register for backpatching
    loop := Loop.make(stmt)
    loopStack.push(loop)

    // assemble the while loop code
    continueLabel := mark
    expr(stmt.condition)
    breakJump := jump(FOp.JumpFalse)
    block(stmt.block)
    jump(FOp.Jump, continueLabel)
    breakLabel := mark
    backpatch(breakJump)

    // backpatch continues/breaks
    loop.continues.each |Int pos| { backpatch(pos, continueLabel) }
    loop.breaks.each |Int pos| { backpatch(pos, breakLabel) }

    // pop loop from stack
    loopStack.pop

    // TODO - the fcode will often contain Jumps to Jumps which can be optimized
  }

  private Void forStmt(ForStmt stmt)
  {
    breakJump := -1

    // push myself onto the loop stack so that breaks
    // and continues can register for backpatching
    loop := Loop.make(stmt)
    loopStack.push(loop)

    // assemble init if available
    if (stmt.init != null) this.stmt(stmt.init)

    // assemble the for loop code
    condLabel := mark
    if (stmt.condition != null)
    {
      expr(stmt.condition)
      breakJump = jump(FOp.JumpFalse)
    }
    block(stmt.block)
    updateLabel := mark
    if (stmt.update != null) expr(stmt.update)
    jump(FOp.Jump, condLabel)
    endLabel := mark
    if (breakJump != -1) backpatch(breakJump, endLabel)

    // backpatch continues/breaks
    loop.continues.each |Int pos| { backpatch(pos, updateLabel) }
    loop.breaks.each |Int pos| { backpatch(pos, endLabel) }

    // pop loop from stack
    loopStack.pop

    // TODO - the fcode will often contain Jumps to Jumps which can be optimized
  }

  private Void breakOrContinueStmt(Stmt stmt)
  {
    // associated loop should be top of stack
    loop := loopStack.peek
    if (loop.stmt !== stmt->loop)
      throw err("Internal compiler error", stmt.location)

    // if we are inside a protection region which was pushed onto
    // my loop's own stack that means this break or continue
    // needs to jump out of the protected region - that requires
    // calling each region's finally block and using a "leave"
    // instruction rather than a standard "jump"
    Int toBackpatch := null
    if (!loop.protectedRegions.isEmpty)
    {
      // jump to any finally blocks we are inside
      loop.protectedRegions.eachr |ProtectedRegion region|
      {
        if (region.hasFinally)
          region.jumpFinallys.add(jump(FOp.JumpFinally))
      }

      // generate leave instruction
      toBackpatch = jump(FOp.Leave)
    }
    else
    {
      // generate standard jump instruction
      toBackpatch = jump(FOp.Jump)
    }

    // register for backpatch
    if (stmt.id === StmtId.breakStmt)
      loop.breaks.add(toBackpatch)
    else
      loop.continues.add(toBackpatch)
  }

//////////////////////////////////////////////////////////////////////////
// Switch
//////////////////////////////////////////////////////////////////////////

  private Void switchStmt(SwitchStmt stmt)
  {
    // A table switch is a series of contiguous (or near contiguous)
    // cases which can be represented an offset into a jump table.
    minMax := computeTableRange(stmt)
    if (minMax != null)
      tableSwitchStmt(stmt, minMax[0], minMax[1])
    else
      equalsSwitchStmt(stmt)
  }

  **
  ** Compute the range of this switch and return as a list of '[min, max]'
  ** if the switch is a candidate for a table switch as a series of
  ** contiguous (or near contiguous) cases which can be represented an
  ** offset into a jump table.  Return null if the switch is not numeric
  ** or too sparse to use as a table switch.
  **
  private Int[] computeTableRange(SwitchStmt stmt)
  {
    // we only compute ranges for Ints and Enums
    ctype := stmt.condition.ctype
    if (!ctype.isInt && !ctype.isEnum)
      return null

    // now we need to determine contiguous range
    min := 2147483647
    max := -2147483648
    count := 0
    try
    {
      stmt.cases.each |Case c|
      {
        for (i:=0; i<c.cases.size; ++i)
        {
          count++
          expr := c.cases[i]
          literal := expr.asTableSwitchCase
          if (literal == null) throw CompilerErr.make("return null", c.location)
          if (literal < min) min = literal
          if (literal > max) max = literal
        }
      }
    }
    catch (CompilerErr e)
    {
      return null
    }

    // if no cases, then don't use tableswitch
    if (count == 0) return null

    // enums and anything with less than 32 jumps is immediately
    // allowed, otherwise base the table on a percentage of count
    delta := max - min
    if (ctype.isEnum || delta < 32 || count*32 > delta)
      return [min,max]
    else
      return null
  }

  private Void tableSwitchStmt(SwitchStmt stmt, Int min, Int max)
  {
    stmt.isTableswitch = true
    isEnum := stmt.condition.ctype.isEnum

    // push condition onto the stack
    expr(stmt.condition)

    // if this is an enum get ordinal on the stack
    if (isEnum)
      op(FOp.CallVirtual, fpod.addMethodRef(ns.enumOrdinal))

    // if min is not zero, then do a subtraction so that
    // our condition is a zero based index into the jump table
    if (min != 0)
    {
      op(FOp.LoadInt, fpod.ints.add(-min))
      op(FOp.CallVirtual, fpod.addMethodRef(ns.intPlus))
    }

    // now allocate our jump table
    count := max - min + 1
    jumps := Case[,]
    jumps.size = count

    // walk thru each case, and map the jump offset to a block
    stmt.cases.each |Case c|
    {
      for (i:=0; i<c.cases.size; ++i)
      {
        expr    := c.cases[i]
        literal := expr.asTableSwitchCase
        offset  := literal - min
        jumps[offset] = c
      }
    }

    // now write the switch bytecodes
    op(FOp.Switch)
    code.writeI2(count)
    jumpStart := code.size
    fill := count*2
    fill.times |,| { code.write(0xff) }  // we'll backpatch the jump offsets last

    // default block goes first - it's the switch fall
    // thru, save offset to back patch jump
    defaultStart := mark
    defaultEnd := switchBlock(stmt.defaultBlock)

    // now write each case block
    caseEnds := Int[,]
    caseEnds.size = stmt.cases.size
    stmt.cases.each |Case c, Int i|
    {
      c.startOffset = code.size
      caseEnds[i] = switchBlock(c.block)
    }

    // backpatch the jump table
    end := code.size
    code.seek(jumpStart)
    jumps.each |Case c, Int i|
    {
      if (c == null)
        code.writeI2(defaultStart)
      else
        code.writeI2(c.startOffset)
    }
    code.seek(end)

    // backpatch all the case blocks to jump here when done
    if (defaultEnd != -1) backpatch(defaultEnd)
    caseEnds.each |Int pos|
    {
      if (pos != -1) backpatch(pos)
    }
  }

  private Void equalsSwitchStmt(SwitchStmt stmt)
  {
    stmt.isTableswitch = false

    // push condition onto the stack
    expr(stmt.condition)

    // walk thru each case, keeping track of all the
    // places we need to backpatch when cases match
    jumpPositions := Int[,]
    jumpCases := Case[,]
    stmt.cases.each |Case c|
    {
      for (i:=0; i<c.cases.size; ++i)
      {
        op(FOp.Dup)
        expr(c.cases[i])
        op(FOp.CmpEQ) // TODO eq/jump combo?
        jumpPositions.add(jump(FOp.JumpTrue))
        jumpCases.add(c)
      }
    }

    // default block goes first - it's the switch fall
    // thru, save offset to back patch jump
    defaultStart := mark
    defaultEnd := switchBlock(stmt.defaultBlock, true)

    // now write each case block
    caseEnds := Int[,]
    caseEnds.size = stmt.cases.size
    stmt.cases.each |Case c, Int i|
    {
      c.startOffset = code.size
      caseEnds[i] = switchBlock(c.block, true)
    }

    // backpatch the jump table
    end := code.size
    jumpPositions.each |Int pos, Int i|
    {
      backpatch(pos, jumpCases[i].startOffset)
    }
    code.seek(end)

    // backpatch all the case blocks to jump here when done
    if (defaultEnd != -1) backpatch(defaultEnd)
    caseEnds.each |Int pos|
    {
      if (pos != -1) backpatch(pos)
    }
  }

  private Int switchBlock(Block block, Bool pop := false)
  {
    if (pop) op(FOp.Pop);
    if (block != null)
    {
      this.block(block)
      if (block.isExit) return -1
    }
    return jump(FOp.Jump)
  }

//////////////////////////////////////////////////////////////////////////
// Try
//////////////////////////////////////////////////////////////////////////

  private Bool inProtectedRegion()
  {
    return protectedRegions != null && !protectedRegions.isEmpty
  }

  private Void tryStmt(TryStmt stmt)
  {
    // enter a "protected region" which means that we can't
    // jump or return out of this region directly - we have to
    // use a special "leave" jump of the protected region
    if (protectedRegions == null) protectedRegions = ProtectedRegion[,]
    region := ProtectedRegion.make(stmt)
    protectedRegions.push(region)
    if (!loopStack.isEmpty) loopStack.peek.protectedRegions.push(region)

    // assemble body of try block
    start := mark
    block(stmt.block)
    end := mark

    // if the block isn't guaranteed to exit:
    //  1) if we have a finally, then jump to finally
    //  2) jump over catch blocks
    tryDone := -1
    finallyStart := -1
    if (!stmt.block.isExit)
    {
      if (region.hasFinally)
      {
        region.jumpFinallys.add(jump(FOp.JumpFinally))
        end = mark
      }
      tryDone = jump(FOp.Leave)
    }

    // assemble catch blocks
    catchDones := Int[,]
    catchDones.size = stmt.catches.size
    stmt.catches.each |Catch c, Int i|
    {
      catchDones[i] = tryCatch(c, start, end, region)
    }

    // assemble finally block
    if (region.hasFinally)
    {
      // wrap try block and each catch block with catch all to finally
      addToErrTable(start, end, mark, null)
      stmt.catches.each |Catch c|
      {
        addToErrTable(c.start, c.end, mark, null)
      }

      // handler code
      region.jumpFinallys.each |Int pos| { backpatch(pos) }
      op(FOp.FinallyStart)
      block(stmt.finallyBlock)
      op(FOp.FinallyEnd)
    }

    // mark next statement as jump destination for try block
    if (tryDone != -1) backpatch(tryDone)
    catchDones.each |Int pos| { if (pos != -1) backpatch(pos) }

    // leave protected region
    if (!loopStack.isEmpty) loopStack.peek.protectedRegions.pop
    protectedRegions.pop
  }

  private Int tryCatch(Catch c, Int start, Int end, ProtectedRegion region)
  {
    // assemble catch block - if there isn't a local variable
    // we emit the CatchAllStart, otherwise the block will
    // start off with a LocalVarDef which will write out the
    // CatchErrStart opcode
    handler := mark
    c.start = mark
    if (c.errVariable == null) op(FOp.CatchAllStart)
    block(c.block)
    done := -1
    if (!c.block.isExit)
    {
      if (region.hasFinally)
        region.jumpFinallys.add(jump(FOp.JumpFinally))

      done = jump(FOp.Leave)
    }
    c.end = mark
    op(FOp.CatchEnd)

    // fill in err table
    addToErrTable(start, end, handler, c.errType)

    // return position to backpatch
    return done
  }

  private Void addToErrTable(Int start, Int end, Int handler, CType errType)
  {
    // catch all is implicitly a catch for sys::Err
    if (errType == null) errType = ns.errType

    // add to err table buffer
    errCount++
    errTable.writeI2(start)
    errTable.writeI2(end)
    errTable.writeI2(handler)
    errTable.writeI2(fpod.addTypeRef(errType))
  }

//////////////////////////////////////////////////////////////////////////
// Expressions
//////////////////////////////////////////////////////////////////////////

  Void expr(Expr expr)
  {
    line(expr.location)
    switch (expr.id)
    {
      case ExprId.nullLiteral:     nullLiteral
      case ExprId.trueLiteral:
      case ExprId.falseLiteral:    boolLiteral((LiteralExpr)expr)
      case ExprId.intLiteral:      intLiteral((LiteralExpr)expr)
      case ExprId.floatLiteral:    floatLiteral((LiteralExpr)expr)
      case ExprId.decimalLiteral:  decimalLiteral((LiteralExpr)expr)
      case ExprId.strLiteral:      strLiteral((LiteralExpr)expr)
      case ExprId.durationLiteral: durationLiteral((LiteralExpr)expr)
      case ExprId.uriLiteral:      uriLiteral((LiteralExpr)expr)
      case ExprId.typeLiteral:     typeLiteral((LiteralExpr)expr)
      case ExprId.slotLiteral:     slotLiteral((SlotLiteralExpr)expr)
      case ExprId.rangeLiteral:    rangeLiteral((RangeLiteralExpr)expr)
      case ExprId.listLiteral:     listLiteral((ListLiteralExpr)expr)
      case ExprId.mapLiteral:      mapLiteral((MapLiteralExpr)expr)
      case ExprId.boolNot:         not((UnaryExpr)expr)
      case ExprId.cmpNull:         cmpNull((UnaryExpr)expr)
      case ExprId.cmpNotNull:      cmpNotNull((UnaryExpr)expr)
      case ExprId.elvis:           elvis((BinaryExpr)expr)
      case ExprId.assign:          assign((BinaryExpr)expr)
      case ExprId.same:            same((BinaryExpr)expr)
      case ExprId.notSame:         notSame((BinaryExpr)expr)
      case ExprId.boolOr:          or((CondExpr)expr, null)
      case ExprId.boolAnd:         and((CondExpr)expr, null)
      case ExprId.isExpr:          isExpr((TypeCheckExpr)expr)
      case ExprId.isnotExpr:       isnotExpr((TypeCheckExpr)expr)
      case ExprId.asExpr:          asExpr((TypeCheckExpr)expr)
      case ExprId.localVar:
      case ExprId.thisExpr:
      case ExprId.superExpr:       loadLocalVar((LocalVarExpr)expr)
      case ExprId.call:
      case ExprId.construction:    call((CallExpr)expr)
      case ExprId.shortcut:        shortcut((ShortcutExpr)expr)
      case ExprId.field:           loadField((FieldExpr)expr)
      case ExprId.cast:            cast((TypeCheckExpr)expr)
      case ExprId.closure:         this.expr(((ClosureExpr)expr).substitute)
      case ExprId.ternary:         ternary((TernaryExpr)expr)
      case ExprId.withBlock:       withBlock((WithBlockExpr)expr)
      case ExprId.withBase:        return
      case ExprId.staticTarget:    return
      default:                     throw Err.make(expr.id.toStr)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Literals
//////////////////////////////////////////////////////////////////////////

  private Void nullLiteral()
  {
    op(FOp.LoadNull)
  }

  private Void boolLiteral(LiteralExpr expr)
  {
    if (expr.val == true)
      op(FOp.LoadTrue)
    else
      op(FOp.LoadFalse)
  }

  private Void intLiteral(LiteralExpr expr)
  {
    op(FOp.LoadInt, fpod.ints.add(expr.val))
  }

  private Void floatLiteral(LiteralExpr expr)
  {
    op(FOp.LoadFloat, fpod.floats.add(expr.val))
  }

  private Void decimalLiteral(LiteralExpr expr)
  {
    op(FOp.LoadDecimal, fpod.decimals.add(expr.val))
  }

  private Void strLiteral(LiteralExpr expr)
  {
    op(FOp.LoadStr, fpod.strs.add(expr.val))
  }

  private Void durationLiteral(LiteralExpr expr)
  {
    op(FOp.LoadDuration, fpod.durations.add(expr.val))
  }

  private Void uriLiteral(LiteralExpr expr)
  {
    op(FOp.LoadUri, fpod.uris.add(expr.val))
  }

  private Void typeLiteral(LiteralExpr expr)
  {
    val := (CType)expr.val
    op(FOp.LoadType, fpod.addTypeRef(val));
  }

  private Void slotLiteral(SlotLiteralExpr expr)
  {
    op(FOp.LoadType, fpod.addTypeRef(expr.parent));
    op(FOp.LoadStr, fpod.strs.add(expr.name))
    if (expr.slot is CField)
      op(FOp.CallVirtual, fpod.addMethodRef(ns.typeField, 1))
    else
      op(FOp.CallVirtual, fpod.addMethodRef(ns.typeMethod, 1))
  }

  private Void rangeLiteral(RangeLiteralExpr r)
  {
    expr(r.start);
    expr(r.end);
    if (r.exclusive)
      op(FOp.CallNew, fpod.addMethodRef(ns.rangeMakeExclusive))
    else
      op(FOp.CallNew, fpod.addMethodRef(ns.rangeMakeInclusive))
  }

  private Void listLiteral(ListLiteralExpr list)
  {
    t := list.ctype
    if (t is NullableType) t = t->root
    v := ((ListType)t).v

    op(FOp.LoadType, fpod.addTypeRef(v));
    op(FOp.LoadInt,  fpod.ints.add(list.vals.size))
    op(FOp.CallNew,  fpod.addMethodRef(ns.listMake))

    add := fpod.addMethodRef(ns.listAdd)
    for (i:=0; i<list.vals.size; ++i)
    {
      expr(list.vals[i])
      op(FOp.CallVirtual, add)
    }
  }

  private Void mapLiteral(MapLiteralExpr map)
  {
    op(FOp.LoadType, fpod.addTypeRef(map.ctype))
    op(FOp.CallNew,  fpod.addMethodRef(ns.mapMake))

    set := fpod.addMethodRef(ns.mapSet)
    for (i:=0; i<map.keys.size; ++i)
    {
      expr(map.keys[i])
      expr(map.vals[i])
      op(FOp.CallVirtual, set)
    }
  }

//////////////////////////////////////////////////////////////////////////
// UnaryExpr
//////////////////////////////////////////////////////////////////////////

  private Void not(UnaryExpr unary)
  {
    expr(unary.operand)
    op(FOp.CallVirtual, fpod.addMethodRef(ns.boolNot))
  }

  private Void cmpNull(UnaryExpr unary)
  {
    expr(unary.operand)
    op(FOp.CmpNull)
  }

  private Void cmpNotNull(UnaryExpr unary)
  {
    expr(unary.operand)
    op(FOp.CmpNotNull)
  }

//////////////////////////////////////////////////////////////////////////
// BinaryExpr
//////////////////////////////////////////////////////////////////////////

  private Void same(BinaryExpr binary)
  {
    if (binary.lhs.id === ExprId.nullLiteral)
    {
      expr(binary.rhs)
      op(FOp.CmpNull)
    }
    else if (binary.rhs.id === ExprId.nullLiteral)
    {
      expr(binary.lhs)
      op(FOp.CmpNull)
    }
    else
    {
      expr(binary.lhs)
      expr(binary.rhs)
      op(FOp.CmpSame)
    }
  }

  private Void notSame(BinaryExpr binary)
  {
    if (binary.lhs.id === ExprId.nullLiteral)
    {
      expr(binary.rhs)
      op(FOp.CmpNotNull)
    }
    else if (binary.rhs.id === ExprId.nullLiteral)
    {
      expr(binary.lhs)
      op(FOp.CmpNotNull)
    }
    else
    {
      expr(binary.lhs)
      expr(binary.rhs)
      op(FOp.CmpNotSame)
    }
  }

//////////////////////////////////////////////////////////////////////////
// CondExpr
//////////////////////////////////////////////////////////////////////////

  private Void cond(CondExpr expr, Cond cond)
  {
    switch (expr.id)
    {
      case ExprId.boolOr:  or(expr, cond)
      case ExprId.boolAnd: and(expr, cond)
      default:             throw Err.make(expr.id.toStr)
    }
  }

  private Void or(CondExpr expr, Cond cond)
  {
    // if cond is null this is a top level expr which means
    // the result is to push true or false onto the stack;
    // otherwise our only job is to do the various jumps if
    // true or fall-thru if true (used with if statement)
    // NOTE: this code could be further optimized because
    //   it doesn't optimize "a && b || c && c"
    topLevel := cond == null
    if (topLevel) cond = Cond.make

    // perform short circuit logical-or
    expr.operands.each |Expr operand, Int i|
    {
      this.expr(operand)
      if (i < expr.operands.size-1)
        cond.jumpTrues.add(jump(FOp.JumpTrue))
      else
        cond.jumpFalses.add(jump(FOp.JumpFalse))
    }

    // if top level push true/false onto stack
    if (topLevel) condEnd(cond)
  }

  private Void and(CondExpr expr, Cond cond)
  {
    // if cond is null this is a top level expr which means
    // the result is to push true or false onto the stack;
    // otherwise our only job is to do the various jumps if
    // true or fall-thru if true (used with if statement)
    // NOTE: this code could be further optimized because
    //   it doesn't optimize "a && b || c && c"
    topLevel := cond == null
    if (topLevel) cond = Cond.make

    // perform short circuit logical-and
    expr.operands.each |Expr operand|
    {
      this.expr(operand)
      cond.jumpFalses.add(jump(FOp.JumpFalse))
    }

    // if top level push true/false onto stack
    if (topLevel) condEnd(cond)
  }

  private Void condEnd(Cond cond)
  {
    // true if always fall-thru
    cond.jumpTrues.each |Int pos| { backpatch(pos) }
    op(FOp.LoadTrue)
    end := jump(FOp.Jump)

    // false
    cond.jumpFalses.each |Int pos| { backpatch(pos) }
    op(FOp.LoadFalse)

    backpatch(end)
  }

//////////////////////////////////////////////////////////////////////////
// Type Checks
//////////////////////////////////////////////////////////////////////////

  private Void isExpr(TypeCheckExpr tc)
  {
    expr(tc.target)
    op(FOp.Is, fpod.addTypeRef(tc.check))
  }

  private Void isnotExpr(TypeCheckExpr tc)
  {
    isExpr(tc)
    op(FOp.CallVirtual, fpod.addMethodRef(ns.boolNot))
  }

  private Void asExpr(TypeCheckExpr tc)
  {
    expr(tc.target)
    op(FOp.As, fpod.addTypeRef(tc.check))
  }

  private Void cast(TypeCheckExpr tc)
  {
    expr(tc.target)
    op(FOp.Cast, fpod.addTypeRef(tc.check))
    if (!tc.leave) op(FOp.Pop)
  }

//////////////////////////////////////////////////////////////////////////
// Elvis
//////////////////////////////////////////////////////////////////////////

  private Void elvis(BinaryExpr binary)
  {
    expr(binary.lhs)
    op(FOp.Dup)
    op(FOp.CmpNull)
    isNullLabel := jump(FOp.JumpTrue)
    endLabel := jump(FOp.Jump)
    backpatch(isNullLabel)
    op(FOp.Pop)
    expr(binary.rhs)
    backpatch(endLabel)
  }

//////////////////////////////////////////////////////////////////////////
// Ternary
//////////////////////////////////////////////////////////////////////////

  private Void ternary(TernaryExpr ternary)
  {
    expr(ternary.condition)
    falseLabel := jump(FOp.JumpFalse)
    expr(ternary.trueExpr)
    endLabel := jump(FOp.Jump)
    backpatch(falseLabel)
    expr(ternary.falseExpr)
    backpatch(endLabel)
  }

//////////////////////////////////////////////////////////////////////////
// WithBlock
//////////////////////////////////////////////////////////////////////////

  private Void withBlock(WithBlockExpr withBlock)
  {
    expr(withBlock.base)
    withBlock.subs.each |WithSubExpr sub|
    {
      op(FOp.Dup)
      expr(sub.expr)
      if (sub.expr.leave) throw Err.make("should never leave with expr " + sub.location)
    }
    if (!withBlock.leave) op(FOp.Pop)
  }

//////////////////////////////////////////////////////////////////////////
// Assign
//////////////////////////////////////////////////////////////////////////

  **
  ** Simple assignment using =
  **
  private Void assign(BinaryExpr expr)
  {
    switch (expr.lhs.id)
    {
      case ExprId.localVar: assignLocalVar(expr)
      case ExprId.field:    assignField(expr)
      default: throw err("Internal compiler error", expr.location)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Local Var
//////////////////////////////////////////////////////////////////////////

  private Void loadLocalVar(LocalVarExpr var)
  {
    op(FOp.LoadVar, var.register)
  }

  private Void storeLocalVar(LocalVarExpr var)
  {
    op(FOp.StoreVar, var.register);
  }

  private Void assignLocalVar(BinaryExpr assign)
  {
    expr(assign.rhs)
    if (assign.leave) op(FOp.Dup)
    storeLocalVar((LocalVarExpr)assign.lhs)
  }

//////////////////////////////////////////////////////////////////////////
// Field
//////////////////////////////////////////////////////////////////////////

  private Void loadField(FieldExpr fexpr, Bool dupTarget := false)
  {
    field := fexpr.field

    // evaluate target expression
    if (fexpr.target != null)
    {
      expr(fexpr.target);
      if (dupTarget) op(FOp.Dup)
    }

    // if safe, check for null condition
    Int isNullLabel := null
    if (fexpr.isSafe)
    {
      if (fexpr.target == null) throw err("Compiler error field isSafe", fexpr.location)
      op(FOp.Dup)
      op(FOp.CmpNull)
      isNullLabel = jump(FOp.JumpTrue)
    }

    // load field via accessor method
    if (fexpr.useAccessor)
    {
      getter := field.getter // if null then bug in useAccessor
      index := fpod.addMethodRef(getter)
      if (field.parent.isMixin)
      {
        if (getter.isStatic)
          op(FOp.CallMixinStatic, index)
        else
          op(FOp.CallMixinVirtual, index)
      }
      else
      {
        if (getter.isStatic)
          op(FOp.CallStatic, index)
        else if (fexpr.target.id == ExprId.superExpr)
          op(FOp.CallNonVirtual, index)
        else
          op(FOp.CallVirtual, index)
      }

      // if parameterized or covariant, then cast
      if (field.isParameterized || field.isCovariant)
      {
        op(FOp.Cast, fpod.addTypeRef(field.fieldType))
      }
    }
    // load field directly from storage
    else
    {
      index := fpod.addFieldRef(field)
      if (field.parent.isMixin)
      {
        if (field.isStatic)
          op(FOp.LoadMixinStatic, index)
        else
          throw err("LoadMixinInstance", fexpr.location)
      }
      else
      {
        if (field.isStatic)
          op(FOp.LoadStatic, index)
        else
          op(FOp.LoadInstance, index)
      }
    }

    // if safe, handle null case
    if (fexpr.isSafe)
    {
      endLabel := jump(FOp.Jump)
      backpatch(isNullLabel)
      op(FOp.Pop)
      op(FOp.LoadNull)
      backpatch(endLabel)
    }
  }

  private Void assignField(BinaryExpr assign)
  {
    lhs := (FieldExpr)assign.lhs
    isInstanceField := !lhs.field.isStatic;  // used to determine how to duplicate

    if (lhs .target != null) expr(lhs.target)
    expr(assign.rhs);
    if (assign.leave)
    {
      op(FOp.Dup)
      if (isInstanceField)
        op(FOp.StoreVar, assign.tempVar.register)
    }
    storeField(lhs)
    if (assign.leave && isInstanceField)
    {
      op(FOp.LoadVar, assign.tempVar.register)
    }
  }

  private Void storeField(FieldExpr fexpr)
  {
    field := fexpr.field
    if (fexpr.useAccessor)
    {
      setter := field.setter  // if null then bug in useAccessor
      index := fpod.addMethodRef(setter)

      if (field.parent.isMixin) // TODO
      {
        if (setter.isStatic)
          op(FOp.CallMixinStatic, index)
        else
          op(FOp.CallMixinVirtual, index)
      }
      else
      {
        if (setter.isStatic)
          op(FOp.CallStatic, index)
        else if (fexpr.target.id == ExprId.superExpr)
          op(FOp.CallNonVirtual, index)
        else
          op(FOp.CallVirtual, index)
      }
    }
    else
    {
      index := fpod.addFieldRef(field)

      if (field.parent.isMixin)
      {
        if (field.isStatic)
          op(FOp.StoreMixinStatic, index)
        else
          throw err("StoreMixinInstance", fexpr.location)
      }
      else
      {
        if (field.isStatic)
          op(FOp.StoreStatic, index)
        else
          op(FOp.StoreInstance, index)
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Call
//////////////////////////////////////////////////////////////////////////

  private Void call(CallExpr call, Bool leave := call.leave)
  {
    // evaluate target
    if (call.target != null) expr(call.target)

    // if safe, check for null
    Int isNullLabel := null
    if (call.isSafe)
    {
      if (call.target == null) throw err("Compiler error call isSafe", call.location)
      op(FOp.Dup)
      op(FOp.CmpNull)
      isNullLabel = jump(FOp.JumpTrue)
    }

    // invoke call
    if (call.isDynamic)
    {
      dynamicCall(call)
    }
    else
    {
      call.args.each |Expr arg| { expr(arg) }
      invokeCall(call, leave)
    }

    // if safe, handle null case
    if (call.isSafe)
    {
      endLabel := jump(FOp.Jump)
      backpatch(isNullLabel)
      op(FOp.Pop)
      if (call.leave) op(FOp.LoadNull)
      backpatch(endLabel)
    }
  }

  private Void dynamicCall(CallExpr call)
  {
    // name str literal
    op(FOp.LoadStr, fpod.strs.add(call.name))

    // args Obj[]
    // TODO: don't need to create whole new Obj[] when no arguments
    op(FOp.LoadInt,  fpod.ints.add(call.args.size))
    op(FOp.CallNew,  fpod.addMethodRef(ns.listMakeObj))
    add := fpod.addMethodRef(ns.listAdd)
    call.args.each |Expr arg|
    {
      expr(arg)
      op(FOp.CallVirtual, add)
    }

    // Obj.trap
    op(FOp.CallVirtual, fpod.addMethodRef(ns.objTrap))

    // pop return if no leave
    if (!call.leave) op(FOp.Pop)
  }

  private Void invokeCall(CallExpr call, Bool leave := call.leave)
  {
    m := call.method
    index := fpod.addMethodRef(m, call.args.size)

    // write CallVirtual, CallNonVirtual, CallStatic, CallNew, or CallCtor;
    // note that if a constructor call has a target (this or super), then it
    // is a CallCtor instance call because we don't want to allocate
    // a new instance
    if (m.parent.isMixin)
    {
      if (m.isStatic)
        op(FOp.CallMixinStatic, index)
      else if (call.target.id == ExprId.superExpr)
        op(FOp.CallMixinNonVirtual, index)
      else
        op(FOp.CallMixinVirtual, index)
    }
    else if (m.isStatic)
    {
      op(FOp.CallStatic, index)
    }
    else if (m.isCtor)
    {
      if (call.target == null || call.target.id == ExprId.staticTarget)
        op(FOp.CallNew, index)
      else
        op(FOp.CallCtor, index)
    }
    else
    {
      // because CallNonVirtual maps to Java's invokespecial, we can't
      // use it for calls outside of the class (consider it like calling
      // protected method)
      targetId := call.target.id
      if (targetId == ExprId.superExpr || (targetId == ExprId.thisExpr && !m.isVirtual))
        op(FOp.CallNonVirtual, index)
      else
        op(FOp.CallVirtual, index)
    }

    // if we are leaving a value on the stack of a method which
    // has a parameterized return value or is covariant, then we
    // need to insert a cast operation
    //   Int.toStr    => non-generic - no cast
    //   Str[].toStr  => return isn't parameterized - no cast
    //   Str[].get()  => actual return is Obj, but we want Str - cast
    //   covariant    => actual call is against inheritedReturnType
    if (leave)
    {
      if (m.isParameterized)
      {
        ret := m.generic.returnType
        if (ret.isGenericParameter)
          op(FOp.Cast, fpod.addTypeRef(m.returnType))
      }
      else if (m.isCovariant)
      {
        op(FOp.Cast, fpod.addTypeRef(m.returnType))
      }
    }

    // if the method left a value on the stack, and we
    // aren't going to use it, then pop it off
    if (!leave)
    {
      // note we need to use the actual method signature (not parameterized)
      x := m.isParameterized ? m.generic : m
      if (!x.returnType.isVoid || x.isCtor)
        op(FOp.Pop)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Shortcut
//////////////////////////////////////////////////////////////////////////

  private Void shortcut(ShortcutExpr call)
  {
    // handle comparisions as special opcodes
    switch (call.opToken)
    {
      case Token.eq:     shortcutOp(call, FOp.CmpEQ); return
      case Token.notEq:  shortcutOp(call, FOp.CmpNE); return
      case Token.cmp:    shortcutOp(call, FOp.Cmp);   return
      case Token.lt:     shortcutOp(call, FOp.CmpLT); return
      case Token.ltEq:   shortcutOp(call, FOp.CmpLE); return
      case Token.gt:     shortcutOp(call, FOp.CmpGT); return
      case Token.gtEq:   shortcutOp(call, FOp.CmpGE); return
    }

    // always check string concat first since it can
    // have string on either left or right hand side
    if (call.isStrConcat)
    {
      addStr(call, true)
      return
    }

    // if assignment we need to do a bunch of special processing
    if (call.isAssign)
    {
      shortcutAssign(call)
      return
    }

    // just process as normal call
    this.call(call)
  }

  private Void shortcutOp(CallExpr call, FOp opCode)
  {
    if (call.target != null) expr(call.target)
    call.args.each |Expr arg| { expr(arg) }
    op(opCode)
  }

  **
  ** This method is used for complex assignments: prefix/postfix
  ** increment and special dual assignment operators like "+=".
  **
  private Void shortcutAssign(ShortcutExpr c)
  {
    var := c.target
    leaveUsingTemp := false

    // load the variable
    switch (var.id)
    {
      case ExprId.localVar:
        loadLocalVar((LocalVarExpr)var)
      case ExprId.field:
        fexpr := (FieldExpr)var
        loadField(fexpr, true) // dup target on stack for upcoming set
        leaveUsingTemp = !fexpr.field.isStatic  // used to determine how to duplicate
      case ExprId.shortcut:
        // since .NET sucks when it comes to stack manipulation,
        // we use two scratch locals to get the stack into the
        // following format:
        //   index  \  used for get
        //   target /
        //   index  \  used for set
        //   target /
        index := (IndexedAssignExpr)c
        get := (ShortcutExpr)index.target
        expr(get.target)  // target
        op(FOp.Dup)
        op(FOp.StoreVar, index.scratchA.register)
        expr(get.args[0]) // index expr
        op(FOp.Dup)
        op(FOp.StoreVar, index.scratchB.register)
        op(FOp.LoadVar, index.scratchA.register)
        op(FOp.LoadVar, index.scratchB.register)
        invokeCall(get, true)
        leaveUsingTemp = true
      default:
        throw err("Internal error", var.location)
    }

    // if postfix leave, duplicate value before we preform computation
    if (c.leave && c.isPostfixLeave)
    {
      op(FOp.Dup)
      if (leaveUsingTemp)
        op(FOp.StoreVar, c.tempVar.register)
    }

    // load args and invoke call
    c.args.each |Expr arg| { expr(arg) }
    invokeCall(c, true)

    // if prefix, duplicate after we've done computation
    if (c.leave && !c.isPostfixLeave)
    {
      op(FOp.Dup)
      if (leaveUsingTemp)
        op(FOp.StoreVar, c.tempVar.register)
    }

    // save the variable back
    switch (var.id)
    {
      case ExprId.localVar:
        storeLocalVar((LocalVarExpr)var)
      case ExprId.field:
        storeField((FieldExpr)var)
      case ExprId.shortcut:
        set := (CMethod)c->setMethod
        op(FOp.CallVirtual, fpod.addMethodRef(set, 2))
        if (!set.returnType.isVoid) op(FOp.Pop)
    }

    // if field leave, then load back from temp local
    if (c.leave && leaveUsingTemp)
      op(FOp.LoadVar, c.tempVar.register)
  }

//////////////////////////////////////////////////////////////////////////
// Strings
//////////////////////////////////////////////////////////////////////////

  **
  ** Assemble code to build a string using sys::StrBuf.
  **
  private Void addStr(ShortcutExpr expr, Bool topLevel)
  {
    if (topLevel)
      op(FOp.CallNew, fpod.addMethodRef(ns.strBufMake, 0))

    lhs := expr.target
    rhs := expr.args.first

    lhsShortcut := lhs as ShortcutExpr
    if (lhsShortcut != null && lhsShortcut.isStrConcat)
    {
      addStr(lhsShortcut, false)
    }
    else
    {
      if (!isEmptyStrLiteral(lhs))
      {
        this.expr(lhs)
        op(FOp.CallVirtual, fpod.addMethodRef(ns.strBufAdd))
      }
    }

    if (!isEmptyStrLiteral(rhs))
    {
      this.expr(rhs)
      op(FOp.CallVirtual, fpod.addMethodRef(ns.strBufAdd))
    }

    if (topLevel) op(FOp.CallVirtual, fpod.addMethodRef(ns.strBufToStr))
  }

  private Bool isEmptyStrLiteral(Expr expr)
  {
    return expr.id === ExprId.strLiteral && expr->val == ""
  }

//////////////////////////////////////////////////////////////////////////
// Code Buffer
//////////////////////////////////////////////////////////////////////////

  **
  ** Append a opcode with option two byte argument.
  **
  Void op(FOp op, Int arg := null)
  {
    code.write(op.ordinal)
    if (arg != null) code.writeI2(arg)
  }

//////////////////////////////////////////////////////////////////////////
// Jumps
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the current location as a mark to use for backwards jump.
  **
  private Int mark()
  {
    return code.size
  }

  **
  ** Add the specified jump opcode and two bytes for the jump
  ** location.  If a backward jump then pass the mark; if a
  ** a forward jump we return the code pos to backpatch the
  ** mark later.
  **
  private Int jump(FOp op, Int mark := 0xffff)
  {
    this.op(op, mark)
    return code.size-2
  }

  **
  ** Backpacth the mark of forward jump using the given
  ** pos which was returned by jump().  If mark is defaulted,
  ** then we use the current instruction as the mark.
  **
  private Void backpatch(Int pos, Int mark := code.size)
  {
    orig := code.pos
    code.seek(pos).writeI2(mark)
    code.seek(orig)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Finish writing out the exception handling table
  **
  Buf finishCode()
  {
    // if we had to return from a protected region, then now we
    // need to generate the actual return instructions and backpatch
    // all the leaves
    if (leavesToReturn != null)
    {
      leavesToReturn.each |Int pos| { backpatch(pos) }
      if (returnLocal != null)
      {
        op(FOp.LoadVar, returnLocal.register)
        op(FOp.ReturnObj)
      }
      else
      {
        op(FOp.ReturnVoid)
      }
    }

    // check final size
    if (code.size >= 0x7fff) throw err("Method too big", location)
    return code
  }

  **
  ** Finish writing out the exception handling table
  **
  Buf finishErrTable()
  {
    errTable.seek(0).writeI2(errCount)
    return errTable
  }

  **
  ** Finish writing out the line number table
  **
  Buf finishLines()
  {
    lines.seek(0).writeI2(lineCount)
    return lines
  }

  **
  ** Map the opcode we are getting ready to add to the specified line number
  **
  private Void line(Location loc)
  {
    line := loc.line
    if (line == null || lastLine == line) return
    lineCount++
    lines.writeI2(code.size)
    lines.writeI2(line)
    lastLine = line
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Location location
  FPod fpod
  Buf code
  Buf errTable
  Int errCount
  Buf lines
  Int lineCount
  Int lastLine := -1
  Loop[] loopStack

  // protected region fields
  ProtectedRegion[] protectedRegions // stack of protection regions
  Int[] leavesToReturn     // list of Leave positions to backpatch
  MethodVar returnLocal    // where we stash return value
}

**************************************************************************
** Loop
**************************************************************************

class Loop
{
  new make(Stmt stmt) { this.stmt = stmt }

  Stmt stmt                  // WhileStmt or ForStmt
  Int[] breaks := Int[,]     // backpatch positions
  Int[] continues := Int[,]  // backpatch positions
  ProtectedRegion[] protectedRegions := ProtectedRegion[,] // stack
}

**************************************************************************
** ProtectedRegion
**************************************************************************

class ProtectedRegion
{
  new make(TryStmt stmt)
  {
    hasFinally = stmt.finallyBlock != null
    if (hasFinally) jumpFinallys = Int[,]
  }

  Bool hasFinally      // does this region have a finally
  Int[] jumpFinallys  // list of JumpFinally positions to backpatch
}

**************************************************************************
** Cond
**************************************************************************

class Cond
{
  Int[] jumpTrues  := Int[,]   // backpatch positions
  Int[] jumpFalses := Int[,]   // backpatch positions
}