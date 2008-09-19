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
    map := doTest(["key":"value"])
    verify(map["key"] == "value")
  }

  Void testInt()
  {
    map := doTest(["k1":123])
    verify(map["k1"] == 123)
  }

  Void testIntShort()
  {
    map := doTest(["k1":6])
    verify(map["k1"] == 6)
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

  Void testBoolsAndNull()
  {
    // don't call doTest since value is null for myNull
    buf := StrBuf.make
    obj := ["myTrue":true,"myFalse":false,"myNull":null]
    Json.write(obj, buf)
    newObj := Json.read(buf)
    verify(newObj["myTrue"])
    verify(!newObj["myFalse"])
    verify(newObj["myNull"] == null)
  }  

  Void testObject()
  {
    map:=doTest(["type":"Girl","stats":["age":38,"location":"Fan","cute":true]])
    verify(((Map)map["stats"])["cute"])
  }

  // FIXIT test mixture of all of these of course in 1 obj

  private Str:Obj doTest(Str:Obj map)
  {
    buf := StrBuf.make
    Json.write(map, buf)
    newMap := Json.read(buf)
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