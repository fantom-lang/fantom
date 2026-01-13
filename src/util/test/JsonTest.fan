//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 08  Brian Frank  Creation
//

class JsonTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    // basic scalars
    verifyBasics("null", null)
    verifyBasics("true", true)
    verifyBasics("false", false)
    verifyErr(ParseErr#) { JsonInStream("nabc".in).readJson }
    verifyErr(ParseErr#) { JsonInStream("tabc".in).readJson }
    verifyErr(ParseErr#) { JsonInStream("fabcd".in).readJson }
    verifyErr(ParseErr#) { JsonInStream("a".in).readJson }

    // numbers
    verifyBasics("5", 5)
    verifyBasics("-1234", -1234)
    verifyBasics("23.48", 23.48f)
    verifyBasics("2.309e23", 2.309e23f)
    verifyBasics("-5.8e-15", -5.8e-15f)

    // strings
    verifyBasics(Str<|""|>, "")
    verifyBasics(Str<|"x"|>, "x")
    verifyBasics(Str<|"ab"|>, "ab")
    verifyBasics(Str<|"hello world!"|>, "hello world!")
    verifyBasics(Str<|"\" \\ \/ \b \f \n \r \t"|>, "\" \\ / \b \f \n \r \t")
    verifyBasics(Str<|"\u00ab \u0ABC \uabcd"|>, "\u00ab \u0ABC \uabcd")

    // arrays
    verifyBasics("[]", Obj?[,])
    verifyBasics("[1]", Obj?[1])
    verifyBasics("[1,2.0]", Obj?[1,2f])
    verifyBasics("[1,2,3]", Obj?[1,2,3])
    verifyBasics("[3, 4.0, null, \"hi\"]", [3, 4.0f, null, "hi"])
    verifyBasics("[2,\n3]", Obj?[2, 3])
    verifyBasics("[2\n,3]", Obj?[2, 3])
    verifyBasics("[  2 \n , \n 3 ]", Obj?[2, 3])

    // objects
    verifyBasics(Str<|{}|>, Str:Obj?[:])
    verifyBasics(Str<|{"k":null}|>, Str:Obj?["k":null])
    verifyBasics(Str<|{"a":1, "b":2}|>, Str:Obj?["a":1, "b":2])
    verifyBasics(Str<|{"a":1, "b":2,}|>, Str:Obj?["a":1, "b":2])

    // errors
    verifyErr(ParseErr#) { JsonInStream("\"".in).readJson }
    verifyErr(ParseErr#) { JsonInStream("[".in).readJson }
    verifyErr(ParseErr#) { JsonInStream("[1".in).readJson }
    verifyErr(ParseErr#) { JsonInStream("[1,2".in).readJson }
    verifyErr(ParseErr#) { JsonInStream("{".in).readJson }
    verifyErr(ParseErr#) { JsonInStream("""{"x":""".in).readJson }
    verifyErr(ParseErr#) { JsonInStream("""{"x":4,""".in).readJson }
  }

  Void testUnprintable()
  {
    verifyBasics(
      "\"\\u0000\"",
      Str.fromChars([0]))

    verifyBasics(
      "\"abc\\u0000\"",
      Str.fromChars(['a', 'b', 'c', 0]))

    chars := Int[,]
    for (i := 0; i < 32; i++)
      chars.add(i)
    verifyBasics(
      "\"\\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007\\b\\t\\n\\u000b\\f\\r\\u000e\\u000f\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017\\u0018\\u0019\\u001a\\u001b\\u001c\\u001d\\u001e\\u001f\"",
      Str.fromChars(chars))
  }

  Void verifyBasics(Str s, Obj? expected)
  {
    // verify object stand alone
    verifyRoundtrip(expected)

    // wrap as [s]
    array := JsonInStream("[$s]".in).readJson as Obj?[]
    verifyType(array, Obj?[]#)
    verifyEq(array.size, 1)
    verifyEq(array[0], expected)
    verifyRoundtrip(array)

    // wrap as [s, s]
    array = JsonInStream("[$s,$s]".in).readJson as Obj?[]
    verifyType(array, Obj?[]#)
    verifyEq(array.size, 2)
    verifyEq(array[0], expected)
    verifyEq(array[1], expected)
    verifyRoundtrip(array)

    // wrap as {"key":s}
    map := JsonInStream("{\"key\":$s}".in).readJson as Str:Obj?
    verifyType(map, Str:Obj?#)
    verifyEq(map.size, 1)
    verifyEq(map["key"], expected)
    verifyRoundtrip(map)
  }

  Void verifyRoundtrip(Obj? obj)
  {
    str := JsonOutStream.writeJsonToStr(obj)
    roundtrip := JsonInStream(str.in).readJson
    verifyEq(obj, roundtrip)
  }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  Void testWrite()
  {
    // built-in scalars
    verifyWrite(null, Str<|null|>)
    verifyWrite(true, Str<|true|>)
    verifyWrite(false, Str<|false|>)
    verifyWrite("hi", Str<|"hi"|>)
    verifyWrite(-2.3e34f, Str<|-2.3E34|>)
    verifyWrite(34.12345d, Str<|34.12345|>)

    // list/map sanity checks
    verifyWrite([1, 2, 3], Str<|[1,2,3]|>)
    verifyWrite(["key":"val"], Str<|{"key":"val"}|>)
    verifyWrite(["key":"val\\\"ue"], Str<|{"key":"val\\\"ue"}|>)

    // simples
    verifyWrite(5min, Str<|"5min"|>)
    verifyWrite(`/some/uri/`, Str<|"/some/uri/"|>)
    verifyWrite(Time("23:45:01"), Str<|"23:45:01"|>)
    verifyWrite(Date("2009-12-21"), Str<|"2009-12-21"|>)
    verifyWrite(Month.dec, Str<|"dec"|>)
    verifyWrite(Version("3.4"), Str<|"3.4"|>)

    // serializable
    verifyWrite(SerialA(),
      Str<|{"b":true,"i":7,"f":5.0,"s":"string\n","ints":[1,2,3]}|>)

    // invalid float literals
    verifyErr(IOErr#) { verifyWrite(Float.nan, "")    }
    verifyErr(IOErr#) { verifyWrite(Float.posInf, "") }
    verifyErr(IOErr#) { verifyWrite(Float.negInf, "") }

    // errors
    verifyErr(IOErr#) { verifyWrite(Buf(), "") }
    verifyErr(IOErr#) { verifyWrite(Str#.pod, "") }
  }

  Void verifyWrite(Obj? obj, Str expected)
  {
    verifyEq(JsonOutStream.writeJsonToStr(obj), expected)
  }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  public Void testRaw()
  {
    // make raw json
    buf := StrBuf.make
    buf.add("\n{\n  \"type\"\n:\n\"Foobar\",\n \n\n\"age\"\n:\n34,    \n\n\n\n")
    buf.add("\t\"nested\"\t:  \n{\t \"ids\":[3.28, 3.14, 2.14],  \t\t\"dead\":false\n\n,")
    buf.add("\t\n \"friends\"\t:\n null\t  \n}\n\t\n}")
    str := buf.toStr

    // parse
    Str:Obj? map := JsonInStream(str.in).readJson

    // verify
    verifyEq(map["type"], "Foobar")
    verifyEq(map["age"], 34)
    inner := (Str:Obj?) map["nested"]
    verifyNotEq(inner, null)
    verifyEq(inner["dead"], false)
    verifyEq(inner["friends"], null)
    list := (List)inner["ids"]
    verifyNotEq(list, null)
    verifyEq(list.size, 3)
    verifyEq(map["friends"], null)
  }

  public Void testEscapes()
  {
    Str:Obj obj := JsonInStream(
      Str<|{
           "foo"   : "bar\nbaz",
           "bar"   : "_\r \t \u0abc \\ \/_",
           "baz"   : "\"hi\"",
           "num"   : 1234,
           "bool"  : true,
           "float" : 2.4,
           "dollar": "$100 \u00f7",
           "a\nb"  : "crazy key"
           }|>.in).readJson

    f := |->|
    {
      verifyEq(obj["foo"], "bar\nbaz")
      verifyEq(obj["bar"], "_\r \t \u0abc \\ /_")
      verifyEq(obj["baz"], Str<|"hi"|>)
      verifyEq(obj["num"], 1234)
      verifyEq(obj["bool"], true)
      verify(2.4f.approx(obj["float"]))
      verifyEq(obj["dollar"], "\$100 \u00f7")
      verifyEq(obj["a\nb"], "crazy key")
      verifyEq(obj.keys.join(","), "foo,bar,baz,num,bool,float,dollar,a\nb")
    }

    // verify initial state
    f()

    // write out escaping unicode
    buf := Buf()
    JsonOutStream(buf.out).writeJson(obj)
    str := buf.flip.readAllStr
    verifyEq(str.contains("÷"), false)
    verifyEq(str.contains("\\u00f7"), true)
    obj = JsonInStream(str.in).readJson
    f()

    // write out without escaping unicode
    buf = Buf()
    JsonOutStream(buf.out) { escapeUnicode=false }.writeJson(obj)
    str = buf.flip.readAllStr
    verifyEq(str.contains("÷"), true)
    verifyEq(str.contains("\\u00f7"), false)
    obj = JsonInStream(str.in).readJson
    f()
  }

  public Void testTransform()
  {
    verifyEq(
      FooInStream(
        Str<|[
               {"foo": "abc", "bar": 123},
               {"quux": "xyz"}
             ]|>.in).readJson,
      Obj?[
        Foo("abc", 123),
        Str:Obj?["quux": "xyz"]
      ])
  }
}

**************************************************************************
** SerialA
**************************************************************************

@Serializable
internal class SerialA
{
  Bool b := true
  Int i := 7
  Float f := 5f
  Str s := "string\n"
  @Transient Int noGo := 99
  Int[] ints  := [1, 2, 3]
}

**************************************************************************
** FooInStream
**************************************************************************

internal class FooInStream : JsonInStream
{
  new make(InStream in) : super(in) {}

  override Obj transformObj(Str:Obj? obj)
  {
    return obj.containsKey("foo") ?
      Foo(obj["foo"], obj["bar"]) :
      obj
  }
}

**************************************************************************
** Foo
**************************************************************************

internal class Foo
{
  new make(Str foo, Int bar)
  {
    this.foo = foo
    this.bar = bar
  }

  override Bool equals(Obj? that)
  {
    x := that as Foo
    if (x == null) return false
    return foo == x.foo && bar == x.bar
  }

  override Int hash()
  {
    return foo.hash*31 + bar.hash
  }

  internal Str foo
  internal Int bar
}
