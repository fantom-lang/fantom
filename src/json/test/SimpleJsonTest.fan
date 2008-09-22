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

  // FIXIT test mixture of all of these of course in 1 obj

  private Str:Obj doTest(Str:Obj map)
  {
    buf := StrBuf.make
    stream := OutStream.makeForStrBuf(buf)
    Json.write(map, stream)
    stream.close
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