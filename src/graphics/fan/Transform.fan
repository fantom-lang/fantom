//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 May 2017  Brian Frank  Creation
//

**
** Transform models an affine transformation matrix:
**
**   |a  c  e|
**   |b  d  f|
**   |0  0  1|
**
@Js
@Serializable { simple = true }
const class Transform
{
  **
  ** Parse from SVG string format:
  **   matrix(<a> <b> <c> <d> <e> <f>)
  **   translate(<x> [<y>])
  **   scale(<x> [<y>])
  **   rotate(<a> [<x> <y>])
  **   skewX(<a>)
  **   skewY(<a>)
  **
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      Transform? t := null
      s.split(')').each |func|
      {
        if (func.startsWith(",")) func = func[1..-1].trim
        if (func.isEmpty) return
        r := parseFunc(func)
        t = t == null ? r : t * r
      }
      if (t != null) return t
    }
    catch (Err e) {}
    if (checked) throw ParseErr("Transform: $s")
    return null
  }

  ** Parse func, trailing ) already stripped from split
  private static Transform parseFunc(Str s)
  {
    op := s.index("(") ?: throw Err()
    name := s[0..<op].trim
    argsStr := s[op+1..-1].trim
    args :=  GeomUtil.parseFloatList(argsStr)
    switch (name)
    {
      case "matrix":    return make(args[0], args[1], args[2], args[3], args[4], args[5])
      case "translate": return translate(args[0], args.getSafe(1) ?: 0f)
      case "scale":     return scale(args[0], args.getSafe(1) ?: args[0])
      case "rotate":    return rotate(args[0], args.getSafe(1), args.getSafe(2))
      case "skewX":     return skewX(args[0])
      case "skewY":     return skewY(args[0])
      default:          throw Err(name)
    }
  }

  ** Translate transform
  static Transform translate(Float tx, Float ty)
  {
    make(1f, 0f, 0f, 1f, tx, ty)
  }

  ** Scale transform
  static Transform scale(Float sx, Float sy)
  {
    make(sx, 0f, 0f, sy, 0f, 0f)
  }

  ** Rotate angle in degrees
  static Transform rotate(Float angle, Float? cx := null, Float? cy := null)
  {
    a := angle.toRadians
    acos := a.cos
    asin := a.sin
    rot := make(acos, asin, -asin, acos, 0f, 0f)
    if (cx == null) return rot
    return translate(cx, cy) * rot * translate(-cx, -cy)
  }

  ** Skew x by angle in degrees
  static Transform skewX(Float angle)
  {
    a := angle.toRadians
    return make(1f, 0f, a.tan, 1f, 0f, 0f)
  }

  ** Skew y by angle in degrees
  static Transform skewY(Float angle)
  {
    a := angle.toRadians
    return make(1f, a.tan, 0f, 1f, 0f, 0f)
  }

  ** Construct from matrix values
  new make(Float a, Float b, Float c, Float d, Float e, Float f)
  {
    this.a = a; this.c = c; this.e = e
    this.b = b; this.d = d; this.f = f
  }

  ** Multiply this matrix by given matrix and return result as new instance
  @Operator This mult(Transform that)
  {
    make(this.a * that.a + this.c * that.b + this.e * 0f,  // a
         this.b * that.a + this.d * that.b + this.f * 0f,  // b
         this.a * that.c + this.c * that.d + this.e * 0f,  // c
         this.b * that.c + this.d * that.d + this.f * 0f,  // d
         this.a * that.e + this.c * that.f + this.e * 1f,  // e
         this.b * that.e + this.d * that.f + this.f * 1f)  // f
  }

  ** Hash code is based on string format
  override Int hash() { toStr.hash }

  ** Equality is based on string format
  override Bool equals(Obj? obj)
  {
    that := obj as Transform
    if (that == null) return false
    return this.toStr == that.toStr
  }

  ** Return in 'matrix(<a> <b> <c> <d> <e> <f>)' format
  override Str toStr()
  {
    s := StrBuf()
    s.add("matrix(")
     .add(f2s(a)).addChar(' ')
     .add(f2s(b)).addChar(' ')
     .add(f2s(c)).addChar(' ')
     .add(f2s(d)).addChar(' ')
     .add(f2s(e)).addChar(' ')
     .add(f2s(f)).addChar(')')
    return s.toStr
  }

  private static Str f2s(Float f) { f.toLocale("0.#####", Locale.en) }

  const Float a
  const Float b
  const Float c
  const Float d
  const Float e
  const Float f

  ** Default instance is no transform.
  static const Transform defVal := Transform(1f, 0f, 0f, 1f, 0f, 0f)
}