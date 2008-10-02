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

  Void testString()
  {
    key := "key"
    val := "value"
    map := doTest([key:val])
    verifyEq(map[key], val)
  }

  Void testEmptyString()
  {
    key := "key"
    val := ""
    map := doTest([key:val])
    verifyEq(map[key], val)
  }

  Void testEscapesString()
  {
    key := "key"
    val := "\b\t\f\r\n"
    map := doTest([key:val])
    verifyEq(map[key], val)
  }

  Void testIntString()
  {
    key := "key"
    val := "314"
    map := doTest([key:val])
    verifyEq(map[key], val)
  }

  Void testInt()
  {
    key := "k1"
    val := 123
    map := doTest([key:val])
    verifyEq(map[key], val)
  }

  Void testIntShort()
  {
    map := doTest(["k1":6])
    verifyEq(map["k1"], 6)
  }

  Void testNegative()
  {
    map := doTest(["k1":-69])
    verifyEq(map["k1"], -69)
  }

  Void testFloat()
  {
    map := doTest(["k1":123.45])
    verify(map["k1"] == 123.45)
  }

  Void testDurationNs()
  {
    map := doTest(["k1":123ns])
    verify(map["k1"] == 123ns)
  }

  Void testDurationMs()
  {
    map := doTest(["k1":123ms])
    verify(map["k1"] == 123ms)
  }

  Void testDurationSec()
  {
    map := doTest(["k1":123sec])
    verify(map["k1"] == 123sec)
  }

  Void testDurationMin()
  {
    map := doTest(["k1":120min])
    verify(map["k1"] == 120min)
  }

  Void testDurationHr()
  {
    map := doTest(["k1":24hr])
    verify(map["k1"] == 24hr)
  }

  Void testDurationDay()
  {
    map := doTest(["k1":365day])
    verify(map["k1"] == 365day)
  }

  Void testExp()
  {
    doTest(["k1":1.23e11])
  }

  Void testIntArray()
  {
    doTest(["k1":[6,7,8]])
  }

  Void testStringArray()
  {
    doTest(["k1":["foo","bar","quux"]])
  }

  Void testEmptyArray()
  {
    doTest(["k1":[,]])
  }

  Void testUri()
  {
    doTest(["kuri":`http://fandev.org`]) 
  }

  Void testBoolsAndNull()
  {
    // don't call doTest since value is null for myNull
    buf := StrBuf.make
    stream := OutStream.makeForStrBuf(buf)
    obj := ["myTrue":true,"myFalse":false,"myNull":null]
    Json.write(obj, stream)
    stream.close
    ins := InStream.makeForStr(buf.toStr)
    newObj := Json.read(ins)
    verify(newObj["myTrue"])
    verify(!newObj["myFalse"])
    verify(newObj["myNull"] == null)
  }  

  Void testObject()
  {
    map:=doTest(["type":"Girl","stats":["age":38,"location":"Fan","cute":true]])
    verify(((Map)map["stats"])["cute"])
  }

  Void testEmptyObject()
  {
    input := [:]
    map:=doTest(input)
    validate(input, map)
  }

  Void testRawJson()
  {
    buf := StrBuf.make
    buf.add("\n{\n  \"type\"\n:\n\"Foobar\",\n \n\n\"age\"\n:\n34,    \n\n\n\n")
    buf.add("\t\"nested\"\t:  \n{\t \"ids\":[3.28, 3.14, 2.14],  \t\t\"dead\":false\n\n,")
    buf.add("\t\n \"friends\"\t:\n null\t  \n}\n\t\n}")
    ins := InStream.makeForStr(buf.toStr)
    map := Json.read(ins)
    verifyEq(map["type"], "Foobar") 
  }

  private Str:Obj doTest(Str:Obj map)
  {
    buf := StrBuf.make
    stream := OutStream.makeForStrBuf(buf)
    Json.write(map, stream)
    stream.close
    echo(buf.toStr)
    ins := InStream.makeForStr(buf.toStr)
    newMap := Json.read(ins)
    validate(map, newMap)
    return newMap
  }

  private Void validate(Str:Obj obj, Str:Obj newObj)
  {
    verify(obj.size == newObj.size)
    newObj.each |Obj val, Str key|
    {
      verify(newObj[key] != null)
      verify(newObj[key] == val)
    }
  }
}