//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//   24 Jun 06  Brian Frank  Ported from Java to Fan
//

**
** AstWriter
**
class AstWriter
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Make for specified output stream
  **
  new make(OutStream out := Sys.out)
  {
    this.out = out
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Write and then return this.
  **
  AstWriter w(Obj o)
  {
    if (needIndent)
    {
      out.writeChars(Str.spaces(indentation*2))
      needIndent = false
    }
    out.writeChars(o.toStr)
    return this
  }

  **
  ** Write newline and then return this.
  **
  public AstWriter nl()
  {
    w("\n")
    needIndent = true
    out.flush
    return this
  }

  **
  ** Increment the indentation
  **
  AstWriter indent()
  {
    indentation++
    return this
  }

  **
  ** Decrement the indentation
  **
  AstWriter unindent()
  {
    indentation--
    if (indentation < 0) indentation = 0
    return this
  }

  **
  ** Write the source code for the mask of flags with a trailing space.
  **
  AstWriter flags(Int flags)
  {
    if (flags & FConst.Public    != 0) w("public ")
    if (flags & FConst.Protected != 0) w("protected ")
    if (flags & FConst.Private   != 0) w("private ")
    if (flags & FConst.Internal  != 0) w("internal ")
    if (flags & FConst.Native    != 0) w("native ")
    if (flags & FConst.Enum      != 0) w("enum ")
    if (flags & FConst.Mixin     != 0) w("mixin ")
    if (flags & FConst.Final     != 0) w("final ")
    if (flags & FConst.Ctor      != 0) w("new ")
    if (flags & FConst.Override  != 0) w("override ")
    if (flags & FConst.Abstract  != 0) w("abstract ")
    if (flags & FConst.Static    != 0) w("static ")
    if (flags & FConst.Storage   != 0) w("storage ")
    if (flags & FConst.Virtual   != 0) w("virtual ")

    if (flags & FConst.Synthetic != 0) w("synthetic ")
    if (flags & FConst.Getter    != 0) w("getter ")
    if (flags & FConst.Setter    != 0) w("setter ")

    return this
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream out
  Int indentation := 0
  Bool needIndent := false

}