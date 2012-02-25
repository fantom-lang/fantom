//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 11  Brian Frank  Creation
//

class DocTypeRefTest : Test
{
  Void test()
  {
    // basic
    t := DocTypeRef("foo::Bar")
    verifyBasic(t, "foo", "Bar", false)

    // basic nullable
    t = DocTypeRef("foo::Bar?")
    verifyBasic(t, "foo", "Bar", true)

    // list of basic
    t = DocTypeRef("foo::Bar[]")
    verifyEq(t.pod, "sys")
    verifyEq(t.name, "List")
    verifyEq(t.qname, "sys::List")
    verifyEq(t.signature, "foo::Bar[]")
    verifyEq(t.isNullable, false)
    verifyBasic(t.v, "foo", "Bar", false)

    // list of basic nullable
    t = DocTypeRef("foo::Bar?[]")
    verifyEq(t.pod, "sys")
    verifyEq(t.name, "List")
    verifyEq(t.qname, "sys::List")
    verifyEq(t.signature, "foo::Bar?[]")
    verifyEq(t.isNullable, false)
    verifyBasic(t.v, "foo", "Bar", true)

    // nullable list
    t = DocTypeRef("foo::Bar[]?")
    verifyEq(t.pod, "sys")
    verifyEq(t.name, "List")
    verifyEq(t.qname, "sys::List")
    verifyEq(t.signature, "foo::Bar[]?")
    verifyEq(t.isNullable, true)
    verifyBasic(t.v, "foo", "Bar", false)

    // map of basics
    t = DocTypeRef("[sys::Str:foo::Bar]")
    verifyEq(t.pod, "sys")
    verifyEq(t.name, "Map")
    verifyEq(t.qname, "sys::Map")
    verifyEq(t.signature, "[sys::Str:foo::Bar]")
    verifyEq(t.isNullable, false)
    verifyBasic(t.k, "sys", "Str", false)
    verifyBasic(t.v, "foo", "Bar", false)

    // map with nullables
    t = DocTypeRef("[sys::Str:foo::Bar?]?")
    verifyEq(t.pod, "sys")
    verifyEq(t.name, "Map")
    verifyEq(t.qname, "sys::Map")
    verifyEq(t.signature, "[sys::Str:foo::Bar?]?")
    verifyEq(t.isNullable, true)
    verifyBasic(t.k, "sys", "Str", false)
    verifyBasic(t.v, "foo", "Bar", true)

    // func no params
    t = DocTypeRef("|->foo::Bar|")
    verifyEq(t.pod, "sys")
    verifyEq(t.name, "Func")
    verifyEq(t.qname, "sys::Func")
    verifyEq(t.signature, "|->foo::Bar|")
    verifyEq(t.isNullable, false)
    verifyEq(t.funcParams.size, 0)
    verifyBasic(t.funcReturn, "foo", "Bar", false)

    // func one param
    t = DocTypeRef("|sys::Int->foo::Bar?|?")
    verifyEq(t.pod, "sys")
    verifyEq(t.name, "Func")
    verifyEq(t.qname, "sys::Func")
    verifyEq(t.signature, "|sys::Int->foo::Bar?|?")
    verifyEq(t.isNullable, true)
    verifyEq(t.funcParams.size, 1)
    verifyBasic(t.funcParams[0], "sys", "Int", false)
    verifyBasic(t.funcReturn, "foo", "Bar", true)

    // func two params
    t = DocTypeRef("|sys::Int?[],sys::Str->sys::Void|")
    verifyEq(t.pod, "sys")
    verifyEq(t.name, "Func")
    verifyEq(t.qname, "sys::Func")
    verifyEq(t.signature, "|sys::Int?[],sys::Str->sys::Void|")
    verifyEq(t.isNullable, false)
    verifyEq(t.funcParams.size, 2)
    verifyEq(t.funcParams[0].qname, "sys::List")
    verifyBasic(t.funcParams[0].v, "sys", "Int", true)
    verifyBasic(t.funcParams[1], "sys", "Str", false)
    verifyBasic(t.funcReturn, "sys", "Void", false)

    // combos
    t = DocTypeRef("[sys::Str:foo::Bar?[]][]?")
    verifyEq(t.qname, "sys::List")
    verifyEq(t.signature, "[sys::Str:foo::Bar?[]][]?")
    verifyEq(t.isNullable, true)
    t = t.v
    verifyEq(t.qname, "sys::Map")
    verifyEq(t.signature, "[sys::Str:foo::Bar?[]]")
    t = t.v
    verifyEq(t.qname, "sys::List")
    verifyBasic(t.v, "foo", "Bar", true)

    // bug report Feb-2012
    t = DocTypeRef("sys::Str[][]?[]")
    verifyEq(t.qname, "sys::List")
    t = t.v
    verifyEq(t.signature, "sys::Str[][]?")
    verifyEq(t.isNullable, true)
    t = t.v
    verifyEq(t.signature, "sys::Str[]")
    verifyEq(t.isNullable, false)
    t = t.v
    verifyEq(t.signature, "sys::Str")

    // errors
    verifyEq(DocTypeRef.fromStr("foo", false), null)
    verifyErr(ParseErr#) { x := DocTypeRef.fromStr("foo") }
    verifyErr(ParseErr#) { x := DocTypeRef.fromStr("foo", true) }
  }

  Void verifyBasic(DocTypeRef t, Str pod, Str name, Bool nullable)
  {
    verifyEq(t.pod, pod)
    verifyEq(t.name, name)
    verifyEq(t.qname, "$pod::$name")
    verifyEq(t.signature, nullable ? "${t.qname}?" : t.qname)
    verifyEq(t.isNullable, nullable)
    verifyEq(t.isParameterized, false)
  }

}