//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 May 11  Brian Frank  Creation
//

**
** QueryTest
**
class QueryTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Tokenizer
//////////////////////////////////////////////////////////////////////////

  Void testTokenizer()
  {
    // empty
    verifyToks("", [,])

    // identifiers
    verifyToks("x", [Token.id, "x"])
    verifyToks("fooBar", [Token.id, "fooBar"])
    verifyToks("fooBar1999x", [Token.id, "fooBar1999x"])
    verifyToks("foo_23", [Token.id, "foo_23"])

    // ints
    verifyToks("5", [Token.int, 5])
    verifyToks("123_456", [Token.int, 123_456])

    // date
    verifyToks("2009-10-04", [Token.date, Date(2009, Month.oct, 4)])

    // versions
    verifyToks("1.2", [Token.version, Version("1.2")])
    verifyToks("1.2.3.4", [Token.version, Version("1.2.3.4")])

    // strings
    verifyToks(Str<|""|>,  Obj?[Token.str, ""])
    verifyToks(Str<|"x y"|>,  Obj?[Token.str, "x y"])
    verifyToks(Str<|"x\"y"|>,  Obj?[Token.str, "x\"y"])
    verifyToks(Str<|"_\u012f \n \t \\_"|>,  Obj?[Token.str, "_\u012f \n \t \\_"])
    verifyToks(Str<|''|>,  Obj?[Token.str, ""])
    verifyToks(Str<|'x y'|>,  Obj?[Token.str, "x y"])
    verifyToks(Str<|'x\'y'|>,  Obj?[Token.str, "x'y"])
    verifyToks(Str<|'_\u012f \n \t \\_'|>,  Obj?[Token.str, "_\u012f \n \t \\_"])

    // errors
    verifyErr(ParseErr#) { verifyToks(Str<|"fo..|>, [,]) }
    verifyErr(ParseErr#) { verifyToks(Str<|`fo..|>, [,]) }
    verifyErr(ParseErr#) { verifyToks(Str<|"\u345x"|>, [,]) }
    verifyErr(ParseErr#) { verifyToks(Str<|"\ua"|>, [,]) }
    verifyErr(ParseErr#) { verifyToks(Str<|"\u234"|>, [,]) }
    verifyErr(ParseErr#) { verifyToks("#", [,]) }
    verifyErr(ParseErr#) { verifyToks("2.x", [,]) }
    verifyErr(ParseErr#) { verifyToks("11-03-05", [,]) }
    verifyErr(ParseErr#) { verifyToks("2.5.@6", [,]) }
  }

  Void verifyToks(Str src, Obj?[] toks)
  {
    t := Tokenizer(src)
    acc := Obj?[,]
    while (true)
    {
      x := t.next
      if (x == Token.eof) break
      acc.add(t.tok).add(t.val)
    }
    verifyEq(Obj?[,].addAll(acc), Obj?[,].addAll(toks))
  }

//////////////////////////////////////////////////////////////////////////
// Parser
//////////////////////////////////////////////////////////////////////////

  Void testParser()
  {
    verifyParser("foo", [["foo"]])
    verifyParser("foo_Bar_22", [["foo_Bar_22"]])
    verifyParser("*", [["*"]])
    verifyParser("*foo", [["*foo"]])
    verifyParser("foo*", [["foo*"]])
    verifyParser("*foo_bar*", [["*foo_bar*"]])

    verifyParser("foo 2", [["foo", Depend("v 2")]])
    verifyParser("foo 10.20", [["foo", Depend("v 10.20")]])
    verifyParser("foo 10.20.30", [["foo", Depend("v 10.20.30")]])
    verifyParser("foo 2+", [["foo", Depend("v 2+")]])
    verifyParser("foo 2.3+", [["foo", Depend("v 2.3+")]])
    verifyParser("foo 1.0-1.3", [["foo", Depend("v 1.0-1.3")]])
    verifyParser("foo 1.0,1.3", [["foo", Depend("v 1.0,1.3")]])
    verifyParser("foo 1.0-2.0,3.2+", [["foo", Depend("v 1.0-2.0,3.2+")]])

    verifyParser("foo a.b", [["foo", null, [QueryMeta("a.b", QueryOp.has, null)]]])
    verifyParser("foo a.b == 123", [["foo", null, [QueryMeta("a.b", QueryOp.eq, 123)]]])
    verifyParser("foo a.b != 123", [["foo", null, [QueryMeta("a.b", QueryOp.notEq, 123)]]])
    verifyParser("foo a.b ~= 'bar baz'", [["foo", null, [QueryMeta("a.b", QueryOp.like, "bar baz")]]])
    verifyParser("foo a.b < 2010-01-01", [["foo", null, [QueryMeta("a.b", QueryOp.lt, Date("2010-01-01"))]]])
    verifyParser("foo a.b <= 9", [["foo", null, [QueryMeta("a.b", QueryOp.ltEq, 9)]]])
    verifyParser("foo a.b >= 9", [["foo", null, [QueryMeta("a.b", QueryOp.gtEq, 9)]]])
    verifyParser("foo a.b > 9",  [["foo", null, [QueryMeta("a.b", QueryOp.gt, 9)]]])
    verifyParser("foo a.b > 2 a.b < 10",  [["foo", null, [QueryMeta("a.b", QueryOp.gt, 2), QueryMeta("a.b", QueryOp.lt, 10)]]])
    verifyParser("foo a.b > -9",  [["foo", null, [QueryMeta("a.b", QueryOp.gt, -9)]]])

    verifyParser("foo, bar",  [["foo"], ["bar"]])
    verifyParser("foo,bar,*goo",  [["foo"], ["bar"], ["*goo"]])
    verifyParser("foo 1.2,1.4, bar",  [["foo", Depend("v 1.2,1.4")], ["bar"]])
    verifyParser("foo 1.2,1.4 a.ver ~= 20.3, bar",  [["foo", Depend("v 1.2,1.4"), [QueryMeta("a.ver", QueryOp.like, Version("20.3"))]], ["bar"]])

    verifyEq(Query.fromStr("2", false), null)
    verifyErr(ParseErr#) { Query.fromStr("2", true) }
    verifyErr(ParseErr#) { Query("2") }
  }

  Void verifyParser(Str input, Obj?[][] parts)
  {
    q := Query.fromStr(input)
    verifyEq(q.parts.size, parts.size)
    q.parts.each |actual, i|
    {
      expected := parts[i]
      verifyEq(actual.namePattern, expected[0])
      verifyEq(actual.version, expected.getSafe(1))
      verifyEq(actual.metas, expected.getSafe(2) ?: QueryMeta[,])
    }
  }

//////////////////////////////////////////////////////////////////////////
// Include
//////////////////////////////////////////////////////////////////////////

  Void testInclude()
  {
    // basic name matching
    verifyInclude("fooBar", spec("fooBar", "1.0.34"), true)
    verifyInclude("foobar", spec("fooBar", "1.0.34"), false)
    verifyInclude("fooBar", spec("foo", "1.0.34"), false)

    // wildcard name matching
    verifyInclude("foo*", spec("foo", "1.0.34"), true)
    verifyInclude("*", spec("fooBar", "1.0.34"), true)
    verifyInclude("foo*", spec("fooBar", "1.0.34"), true)
    verifyInclude("foo*", spec("foxBar", "1.0.34"), false)
    verifyInclude("*Bar", spec("fooBar", "1.0.34"), true)
    verifyInclude("*Bar", spec("fooXar", "1.0.34"), false)
    verifyInclude("acme*Ext", spec("acmeFooExt", "1.0.34"), true)
    verifyInclude("acme*Ext", spec("incFooExt", "1.0.34"), false)
    verifyInclude("acme*Ext", spec("acmeFoo", "1.0.34"), false)

    // version matches
    verifyInclude("foo 1.0", spec("foo", "1.0.34"), true)
    verifyInclude("foo 1.0", spec("bar", "1.0.34"), false)
    verifyInclude("foo 1.0", spec("foo", "1.1"), false)
    verifyInclude("foo 1.0.13+", spec("foo", "1.0.12"), false)
    verifyInclude("foo 1.0.13+", spec("foo", "1.0.13"), true)
    verifyInclude("foo 1.0.13+", spec("foo", "1.3.22"), true)
    verifyInclude("foo 1.1,1.3", spec("foo", "1.1.100"), true)
    verifyInclude("foo 1.1,1.3", spec("foo", "1.2.100"), false)
    verifyInclude("foo 1.1,1.3", spec("foo", "1.3.100"), true)
    verifyInclude("foo 1.1-1.3", spec("foo", "1.1.100"), true)
    verifyInclude("foo 1.1-1.3", spec("foo", "1.2.100"), true)
    verifyInclude("foo 1.1-1.3", spec("foo", "1.3.100"), true)
    verifyInclude("foo 1.1-1.3", spec("foo", "1.4.100"), false)

    // has
    verifyInclude("foo a.b", spec("foo", "1.0"), false)
    verifyInclude("foo a.b", spec("foo", "1.0", ["a.b":"xxx"]), true)
    verifyInclude("foo a.b", spec("foo", "1.0", ["a.b":"true"]), true)
    verifyInclude("foo a.b", spec("foo", "1.0", ["a.b":"false"]), false)

    // ==/!= Str
    ts := "2011-05-09T13:51:31.2-04:00 New_York"
    verifyIncludeEq("foo a.b=='hi'", spec("foo", "1.0", ["a.b":"HI"]), false)
    verifyIncludeEq("foo a.b=='hi'", spec("foo", "1.0", ["a.b":"hi"]), true)

    // ==/!= Int
    verifyIncludeEq("foo a.b==123", spec("foo", "1.0", ["a.b":"hi"]), false)
    verifyIncludeEq("foo a.b==123", spec("foo", "1.0", ["a.b":"12"]), false)
    verifyIncludeEq("foo a.b==123", spec("foo", "1.0", ["a.b":"123"]), true)

    // ==/!= Date
    verifyIncludeEq("foo a.b==2011-05-08", spec("foo", "1.0", ["a.b":"hi"]), false)
    verifyIncludeEq("foo a.b==2011-05-08", spec("foo", "1.0", ["a.b":ts]), false)
    verifyIncludeEq("foo a.b==2011-05-09", spec("foo", "1.0", ["a.b":ts]), true)

    // ==/!= Version
    verifyIncludeEq("foo a.b==10.3", spec("foo", "1.0", ["a.b":"hi"]), false)
    verifyIncludeEq("foo a.b==10.3", spec("foo", "1.0", ["a.b":"1.3"]), false)
    verifyIncludeEq("foo a.b==10.3", spec("foo", "1.0", ["a.b":"10.3"]), true)

    // ~= Str
    verifyInclude("foo a.b~='Foo'", spec("foo", "1.0", ["a.b":"fo"]), false)
    verifyInclude("foo a.b~='Foo'", spec("foo", "1.0", ["a.b":"33"]), false)
    verifyInclude("foo a.b~='Foo'", spec("foo", "1.0", ["a.b":"Foo"]), true)
    verifyInclude("foo a.b~='Foo'", spec("foo", "1.0", ["a.b":"FOOL"]), true)
    verifyInclude("foo a.b~='Foo'", spec("foo", "1.0", ["a.b":"it Foo"]), true)

    // <=> Int
    verifyIncludeCmp("foo a.b ? 10", spec("foo", "1.0", ["a.b":"xyz"]), null)
    verifyIncludeCmp("foo a.b ? 10", spec("foo", "1.0", ["a.b":"8"]),  -1)
    verifyIncludeCmp("foo a.b ? 10", spec("foo", "1.0", ["a.b":"10"]), 0)
    verifyIncludeCmp("foo a.b ? 10", spec("foo", "1.0", ["a.b":"12"]), +1)

    // <=> Date
    verifyIncludeCmp("foo a.b ? 2011-05-08", spec("foo", "1.0", ["a.b":"not ts"]), null)
    verifyIncludeCmp("foo a.b ? 2011-05-10", spec("foo", "1.0", ["a.b":ts]), -1)
    verifyIncludeCmp("foo a.b ? 2011-05-09", spec("foo", "1.0", ["a.b":ts]), 0)
    verifyIncludeCmp("foo a.b ? 2011-05-08", spec("foo", "1.0", ["a.b":ts]), +1)

    // <=> Version
    verifyIncludeCmp("foo a.b ? 2.3", spec("foo", "1.0", ["a.b":"xyz"]), null)
    verifyIncludeCmp("foo a.b ? 2.3", spec("foo", "1.0", ["a.b":"2.2"]),  -1)
    verifyIncludeCmp("foo a.b ? 2.3", spec("foo", "1.0", ["a.b":"2.3"]), 0)
    verifyIncludeCmp("foo a.b ? 2.3", spec("foo", "1.0", ["a.b":"2.3.22"]), +1)
  }

  Void verifyIncludeEq(Str query, PodSpec spec, Bool expected)
  {
    verifyInclude(query, spec, expected)
    verifyInclude(query.replace("==", "!="), spec, !expected)
  }

  Void verifyIncludeCmp(Str query, PodSpec spec, Int? expected)
  {
    verifyInclude(query.replace("?", "<"),  spec, expected == -1)
    verifyInclude(query.replace("?", "<="), spec, expected == -1 || expected == 0)
    verifyInclude(query.replace("?", ">="), spec, expected == +1 || expected == 0)
    verifyInclude(query.replace("?", ">"),  spec, expected == +1)
  }

  Void verifyInclude(Str query, PodSpec spec, Bool expected)
  {
echo("==> $query")
    verifyEq(Query(query).include(spec), expected)
  }

  PodSpec spec(Str name, Str ver, Str:Str meta := Str:Str[:])
  {
    meta["pod.name"]    = name
    meta["pod.version"] = ver
    meta["pod.depends"] = ""
    meta["pod.summary"] = "test pod"
    return PodSpec(meta, null)
  }

}