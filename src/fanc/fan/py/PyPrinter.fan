//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 2026  Trevor Adelman  Creation
//

using compiler

**
** Base class for Python code printers
**
class PyPrinter : CodePrinter
{
  new make(OutStream out) { this.m = PyPrinterState(out) }

  override PyPrinterState m

  ** End of statement (newline in Python)
  This eos() { nl }

  ** Write a colon and newline (for block start)
  This colon() { w(":").nl }

  ** Write a Python string literal
  ** Handles UTF-16 surrogate pairs for code points > 0xFFFF
  This str(Str s)
  {
    w("\"")
    i := 0
    while (i < s.size)
    {
      ch := s[i]
      code := ch.toInt

      // Check for high surrogate (0xD800-0xDBFF) followed by low surrogate (0xDC00-0xDFFF)
      if (code >= 0xD800 && code <= 0xDBFF && i + 1 < s.size)
      {
        lowCh := s[i + 1]
        lowCode := lowCh.toInt
        if (lowCode >= 0xDC00 && lowCode <= 0xDFFF)
        {
          // Combine surrogate pair into full code point
          fullCode := ((code - 0xD800) * 0x400) + (lowCode - 0xDC00) + 0x10000
          w("\\U${fullCode.toHex(8)}")
          i += 2
          continue
        }
      }

      switch (ch)
      {
        case '\n': w("\\n")
        case '\r': w("\\r")
        case '\t': w("\\t")
        case '\"': w("\\\"")
        case '\\': w("\\\\")
        default:
          // Escape control characters and non-ASCII to keep output as valid ASCII
          if (code < 0x20 || code > 0x7E)
          {
            if (code < 0x100)
              w("\\x${code.toHex(2)}")
            else if (code < 0x10000)
              w("\\u${code.toHex(4)}")
            else
              w("\\U${code.toHex(8)}")
          }
          else
          {
            w(ch.toChar)
          }
      }
      i++
    }
    w("\"")
    return this
  }

  ** Write 'pass' statement for empty blocks
  This pass() { w("pass").eos }

  ** Write import statement
  This importStmt(Str module, Str? alias := null)
  {
    w("import ").w(module)
    if (alias != null) w(" as ").w(alias)
    eos
    return this
  }

  ** Write from...import statement
  This fromImport(Str module, Str[] names)
  {
    w("from ").w(module).w(" import ")
    names.each |n, i|
    {
      if (i > 0) w(", ")
      w(n)
    }
    eos
    return this
  }

  ** Write Python None literal
  This none() { w("None") }

  ** Write Python True literal
  This true_() { w("True") }

  ** Write Python False literal
  This false_() { w("False") }

  ** Escape Python reserved words
  Str escapeName(Str name) { PyUtil.escapeName(name) }

  ** Convert Fantom qname to Python module path
  Str qnameToPy(CType ctype)
  {
    "${ctype.pod.name}.${ctype.name}"
  }
}

**************************************************************************
** PyPrinterState
**************************************************************************

class PyPrinterState : CodePrinterState
{
  new make(OutStream out) : super(out) {}

  ** Current type being generated
  TypeDef? curType

  ** Current method being generated
  MethodDef? curMethod

  ** Are we in a static context (static method/initializer)?
  ** When true, 'self' is not available
  Bool inStaticContext := false

  ** Are we inside a closure that captures outer this?
  Bool inClosureWithOuter := false

  ** Counter for generating unique closure names
  Int closureCount := 0

  ** Pending multi-statement closures to emit before next statement
  Obj[] pendingClosures := [,]

  ** List of [ClosureExpr, Int] pairs for lookup during expr phase
  ** We use identity comparison since ClosureExpr isn't immutable
  Obj[] registeredClosures := [,]

  ** Map: closureId -> statementIndex where first used
  Int:Int closureFirstUse := [:]

  ** Current statement index during emission
  Int stmtIndex := 0

  ** Closure nesting depth - when > 0, we're scanning inside a closure body
  ** Nested closures should NOT be extracted to method level
  Int closureDepth := 0

  ** Current for loop update expression - when set, continue statements
  ** must emit this expression before the continue to prevent infinite loops
  Expr? forLoopUpdate

  ** Look up closure ID by object identity
  Int? findClosureId(Obj ce)
  {
    for (i := 0; i < registeredClosures.size; i++)
    {
      pair := registeredClosures[i] as Obj[]
      if (pair[0] === ce) return pair[1]
    }
    return null
  }

  ** Flag to prevent closure emission during expression processing
  Bool collectingClosures := false

  ** Get next closure ID and increment counter
  Int nextClosureId() { closureCount++ }

  ** Counter for generating unique switch variable names
  Int switchVarCount := 0

  ** Get next switch variable ID and increment counter
  Int nextSwitchVarId() { switchVarCount++ }

  //////////////////////////////////////////////////////////////////////////
  // Nonlocal Variable Tracking (for closure-captured mutable variables)
  //////////////////////////////////////////////////////////////////////////

  ** Maps Wrap$ wrapper variable names to their original variable names
  ** Example: "x_Wrapper" -> "x" when x is captured and modified in a closure
  ** The Fantom compiler generates Wrap$* classes for these variables;
  ** we use Python's nonlocal keyword instead of ObjUtil.cvar() wrappers
  Str:Str nonlocalVars := [:]

  ** Record a wrapper->original variable mapping
  ** Called when we detect a Wrap$.make() definition in a localDef
  Void recordNonlocal(Str wrapperVarName, Str originalVarName)
  {
    nonlocalVars[wrapperVarName] = originalVarName
  }

  ** Get the original variable name for a Wrap$ wrapper variable
  ** Returns null if this variable is not a known wrapper
  Str? getNonlocalOriginal(Str wrapperVarName)
  {
    return nonlocalVars.get(wrapperVarName)
  }

  ** Get all original variable names that need nonlocal declarations in closures
  Str[] getNonlocalNames()
  {
    return nonlocalVars.vals
  }

  ** Clear closure state (call between methods)
  Void clearClosures()
  {
    pendingClosures.clear
    registeredClosures.clear
    closureFirstUse.clear
    stmtIndex = 0
    closureDepth = 0  // Reset nesting depth
    nonlocalVars.clear  // Clear nonlocal mappings for new method
  }

  //////////////////////////////////////////////////////////////////////////
  // Closure Immutability
  //////////////////////////////////////////////////////////////////////////

  ** Determine closure immutability case from ClosureExpr.cls
  ** The compiler's ClosureToImmutable step adds synthetic methods:
  ** - Always immutable: isImmutable() { return true }
  ** - Never immutable: toImmutable() throws NotImmutableErr (no isImmutable override)
  ** - Maybe immutable: isImmutable() { return this.immutable } + toImmutable() makes copy
  ** Returns: "always", "never", or "maybe"
  Str closureImmutability(ClosureExpr e)
  {
    cls := e.cls
    if (cls == null) return "always"  // no captures = always immutable

    // Find isImmutable method (added by ClosureToImmutable step)
    isImmMethod := cls.methodDefs.find |m| { m.name == "isImmutable" && m.isSynthetic }

    if (isImmMethod == null)
    {
      // No isImmutable override - check for toImmutable that throws (never immutable)
      toImmMethod := cls.methodDefs.find |m| { m.name == "toImmutable" && m.isSynthetic }
      if (toImmMethod != null)
      {
        // Check if toImmutable throws NotImmutableErr (never case)
        // The method body contains ThrowStmt if it's never immutable
        if (toImmMethod.code?.stmts?.any |s| { s.id == StmtId.throwStmt } ?: false)
          return "never"
      }
      // No isImmutable and no throwing toImmutable = always immutable
      return "always"
    }

    // Check what isImmutable returns
    // Case 1: returns true literal -> always immutable
    // Case 2: returns false literal -> never immutable (shouldn't happen, but handle it)
    // Case 3: returns field reference -> maybe immutable
    retStmt := isImmMethod.code?.stmts?.first as ReturnStmt
    if (retStmt?.expr != null)
    {
      if (retStmt.expr.id == ExprId.trueLiteral) return "always"
      if (retStmt.expr.id == ExprId.falseLiteral) return "never"
      // Field reference (isImmutable() { return immutable }) = maybe
      if (retStmt.expr.id == ExprId.field) return "maybe"
    }

    // Couldn't determine - default to maybe (safest)
    return "maybe"
  }
}
