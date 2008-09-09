//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 06  Brian Frank  Creation
//

**
** ParserTotureTest
**
class ParserTotureTest : Test
{

  Void testPipe()
  {
// TODO - some of this syntax is old
    // test that | is correctly bit-or and method type signature when semicolon omitted
    /*
    y := 0;
    x := 0xab00
    | 0x00cd
    |->Void| { y = x }.call0
    verifyEq(y, 0xabcd)
    */

    // test that || is correctly logic-or and method type signature
    /*
    Bool c;
    b := true
    || false
    | | { c = b }.call0
    verify(c)
    */

    // test method declaration
    /*
    | | m0 := null
    |->Void| m1; |Int x| m2 := null
    */

    // test closure with closure arg
    /*
    x = 99
    | | | c| { c.call0 }.call1( | | { y = x; } )
    verifyEq(y, 99)
    */

    // test closure with 2 closure args
    Obj obj;
    obj = | |->Int| a, |->Int| b->Int| { return (Int)a.call0 + (Int)b.call0 }
          .call2(|->Int| { return 6 }, |->Int| { return 3 })
    verifyEq(obj, 9)

    /* TODO
    list := [,]
    list.clear
    [6].each |Int value, Int index| {}
    */
  }

  Void testTypes()
  {
    verifyEq([Int:Str][]#get.returns, [Int:Str]#)
    verifyEq([Int:Str][][]#.method("get").returns, [Int:Str][]#)

    verifyEq([Int:Str[]][]#get.returns, Int:Str[]#)
    verifyEq([Int:Str[]][]#.method("get").returns, [Int:Str[]]#)

    verifyEq(Int[]:Str[]#get.returns,   Str[]#)
    verifyEq(Int[]:Str[]#.method("get").params[0].of, Int[]#)

    verifyEq(Int[][]:Str[][]#get.returns,  Str[][]#)
    verifyEq(Int[][]:Str[][]#.method("get").params[0].of, Int[][]#)
  }

}