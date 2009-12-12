//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 08  Kevin McIntire  Creation
//

**
** SimpleJsonTest
**
class SimpleJsonTest : Test
{

  Void testSuite()
  {
    suite := JsonTestSuite.make
    suite.tests.each |JsonTestCase tc|
    {
      // echo("Running "+tc.description)
      map := doTest(tc.map)
    }
  }

  Void testRawJson()
  {
    map := Json.read(makeRawJson.in)
    verifyRawJson(map)
  }

  Void testRawUtfJson()
  {
    buf := StrBuf.make
    out := buf.out
    out.charset = Charset.utf16BE
    out.writeChars(makeRawJson)
    out.close

    ins := buf.toStr.in
    ins.charset = Charset.utf16BE
    map := Json.read(ins)
    verifyRawJson(map)
  }

  Void testTopAsList()
  {
    verifyEq(Json.read("[3, 4.0, null, \"hi\"]".in), [3, 4.0f, null, "hi"])

    buf := Buf()
    Json.write(buf.out, [3, 4.0f, null, "hi"])
    verifyEq(buf.flip.readAllStr, "[3,4.0,null,\"hi\"]")
  }

  private Str:Obj doTest(Str:Obj map)
  {
    buf := StrBuf.make
    stream := buf.out
    Json.write(stream, map)
    stream.close
    //echo(buf.toStr)
    newMap := Json.read(buf.toStr.in)
    validate(map, newMap)
    return newMap
  }

  private Void validate(Str:Obj obj, Str:Obj newObj)
  {
    verify(obj.size == newObj.size)
    newObj.each |Obj? val, Str key|
    {
      verify(newObj[key] == val)
    }
  }

  private Str makeRawJson()
  {
    buf := StrBuf.make
    buf.add("\n{\n  \"type\"\n:\n\"Foobar\",\n \n\n\"age\"\n:\n34,    \n\n\n\n")
    buf.add("\t\"nested\"\t:  \n{\t \"ids\":[3.28, 3.14, 2.14],  \t\t\"dead\":false\n\n,")
    buf.add("\t\n \"friends\"\t:\n null\t  \n}\n\t\n}")
    return buf.toStr
  }

  private Void verifyRawJson(Str:Obj? map)
  {
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
    Str:Obj obj := Json.read(
      Str<|{
           "foo"   : "bar\nbaz",
           "bar"   : "_\r \t \u0abc \\ \/_",
           "baz"   : "\"hi\"",
           "num"   : 1234,
           "bool"  : true,
           "float" : 2.4,
           "dollar": "$100 \u00f7",
           "a\nb"  : "crazy key"
           }|>.in)

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

    f()
    buf := Buf()
    Json.write(buf.out, obj)
    obj = Json.read(buf.flip.in)
    f()
  }

}