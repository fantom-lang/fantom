//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//

using compiler

**
** JavaBridge is the compiler plugin for bringing Java
** classes into the Fan type system.
**
@compilerBridge="java"
class JavaBridge : CBridge
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a JavaBridge for current environment
  **
  new make(Compiler c)
    : super(c)
  {
    this.cp = ClassPath.makeForCurrent
  }

//////////////////////////////////////////////////////////////////////////
// Namespace
//////////////////////////////////////////////////////////////////////////

  **
  ** Map a FFI "podName" to a Java package.
  **
  override CPod resolvePod(Str name, Location? loc)
  {
    // look for package name in classpatch
    classes := cp.classes[name]
    if (classes == null)
      throw CompilerErr("Java package '$name' not found", loc)

    // map package to JavaPod
    return JavaPod(this, name, classes)
  }

//////////////////////////////////////////////////////////////////////////
// AST
//////////////////////////////////////////////////////////////////////////

  **
  ** Type check the arguments for the specified method call.
  ** Insert any conversions needed.
  **
  override Void checkCall(CallExpr call)
  {
    // try to match one of the overloaded methods
    JavaMethod? m := call.method
    while (m != null)
    {
      if (matchCall(call, m)) return
      m = m.next
    }

    // if no match this is a argument type error
    s := StrBuf()
    s.add("Invalid args ").add(call.method.name).add("(")
    call.args.each |Expr arg, Int i| { if (i > 0) s.add(","); s.add(arg.ctype) }
    s.add(")")
    err(s.toStr, call.location)
  }

  **
  ** Check if the call matches the specified overload method.
  **
  Bool matchCall(CallExpr call, JavaMethod m)
  {
    // first check if have matching numbers of args and params
    args := call.args
    if (m.params.size != args.size) return false

    // check if each argument is ok or can be coerced
    isErr := false
    newArgs := args.dup
    m.params.each |JavaParam p, Int i|
    {
      // ensure arg fits parameter type (or auto-cast)
      newArgs[i] = CheckErrors.coerce(args[i], p.paramType) |,| { isErr = true }
    }
    if (isErr) return false

    // if we have a match, then update the call args with coercions
    call.args = newArgs

    // if this is a call to a constructor, then we need to create
    // an implicit target for the Java runtime to perform the new
    // opcode to ensure it is on the stack before the arguments (if
    // not already on static type, then let CheckErrors do error
    // reporting)
    if (m.isCtor && call.target.id === ExprId.staticTarget)
    {
      loc := call.location
      newMethod := m.parent.newMethod
      call.target = CallExpr.makeWithMethod(loc, null, newMethod) { synthetic=true }
    }

    return true
  }


//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly ClassPath cp

}