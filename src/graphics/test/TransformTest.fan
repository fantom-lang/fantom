//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 May 2017  Brian Frank  Creation
//

**
** TransformTest
**
class TransformTest : Test
{
  Void test()
  {
    // core multiplication
    a := Transform(1f, 2f, 3f, 4f, 5f, 6f)
    b := Transform(7f, 8f, 9f, 10f, 11f, 12f)
    c := a * b
    verifyTransform(c, "31 46 39 58 52 76")
    verifyTransform(Transform("matrix(31 46 39 58 52 76"), "31 46 39 58 52 76")
    verifyTransform(Transform("matrix(31,46,39,58,52,76"), "31 46 39 58 52 76")
    verifyTransform(Transform("matrix(31, 46, 39, 58, 52, 76"), "31 46 39 58 52 76")
    verifyTransform(Transform("matrix(31 ,  46 ,  39 ,  58 ,  52 ,  76"), "31 46 39 58 52 76")

    // transform
    verifyTransform(Transform.translate(50f, 90f),  "1 0 0 1 50 90")
    verifyTransform(Transform("translate ( 50 90 ) "),  "1 0 0 1 50 90")
    verifyTransform(Transform("translate  (  50  ) "),  "1 0 0 1 50 0")

    // scale
    verifyTransform(Transform.scale(2f, 3f),  "2 0 0 3 0 0")
    verifyTransform(Transform("scale(2 3)"),   "2 0 0 3 0 0")
    verifyTransform(Transform("scale(2)"),   "2 0 0 2 0 0")

    // rotate
    verifyTransform(Transform.rotate(-45f),  "0.70711 -0.70711 0.70711 0.70711 0 0")
    verifyTransform(Transform("rotate(-45)"),  "0.70711 -0.70711 0.70711 0.70711 0 0")

    // example from spec: https://www.w3.org/TR/SVG/coords.html
    a = Transform.translate(50f, 90f)
    b = Transform.rotate(-45f)
    c = Transform.translate(130f, 160f)
    verifyTransform(a * b * c, "0.70711 -0.70711 0.70711 0.70711 255.06097 111.2132")
    c = Transform("translate(50 90) rotate(-45) translate(130 160)")
    verifyTransform(c, "0.70711 -0.70711 0.70711 0.70711 255.06097 111.2132")
    c = Transform("translate(50 90), rotate(-45) ,  translate(130 160)")
    verifyTransform(c, "0.70711 -0.70711 0.70711 0.70711 255.06097 111.2132")
  }

  Void verifyTransform(Transform t, Str expected)
  {
    //echo("-- $t")
    //echo("   matrix($expected)")
    verifyEq(t.toStr, "matrix($expected)")
  }
}

