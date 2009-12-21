//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Kevin McIntire  Creation
//


**
** JsonTestSuite
**
internal class JsonTestSuite
{
  List tests :=
    [
     JsonTestCase
     {
       map = ["key":"val"]
       description = "String value"
     },
     JsonTestCase
     {
       map = ["key":"val\\\"ue"]
       description = "Escaped string value"
     },
     JsonTestCase
     {
       map = ["key":""]
       description = "Empty string value"
     },
     JsonTestCase
     {
       map = ["key":"\b\t\f"]
       description = "Many escapes in string value"
     },
     JsonTestCase
     {
       map = ["key":"314"]
       description = "Int in string value"
     },
     JsonTestCase
     {
       map = ["k1":123]
       description = "Int value"
     },
     JsonTestCase
     {
       map = ["k1":6]
       description = "Short int value"
     },
     JsonTestCase
     {
       map = ["k1":-69]
       description = "Negative int value"
     },
     JsonTestCase
     {
       map = ["k1":123.45]
       description = "Float value"
     },
     JsonTestCase
     {
       map = ["k1":-2309.2309]
       description = "Negative float value"
     },
     JsonTestCase
     {
       map = ["k1":2.309e23]
       description = "Exponent float value"
     },
     JsonTestCase
     {
       map = ["k1":2309ns]
       description = "Duration Ns value"
     },
     JsonTestCase
     {
       map = ["k1":90384ms]
       description = "Duration Ms value"
     },
     JsonTestCase
     {
       map = ["k1":239sec]
       description = "Duration sec value"
     },
     JsonTestCase
     {
       map = ["k1":23min]
       description = "Duration min value"
     },
     JsonTestCase
     {
       map = ["k1":24hr]
       description = "Duration hr value"
     },
     JsonTestCase
     {
       map = ["k1":365day]
       description = "Duration day value"
     },
     JsonTestCase
     {
       map = ["k1":[6,7,8,9]]
       description = "Int array"
     },
     JsonTestCase
     {
       map = ["k1":["foo","bar","quux"]]
       description = "String array"
     },
     JsonTestCase
     {
       map = ["k1":[,]]
       description = "Empty array"
     },
     JsonTestCase
     {
       map = ["k1":["foo",null,"quux"]]
       description = "Array with null"
     },
     JsonTestCase
     {
       map = ["myTrue":true,"myFalse":false,"myNull":null]
       description = "Bools and nulls"
     },
     JsonTestCase
     {
       map = [:]
       description = "Empty object"
     },
     JsonTestCase
     {
       map = ["type":"Girl","stats":["age":38,"location":"Fan","cute":true]]
       description = "Nested object"
     },
     JsonTestCase
     {
       map = ["type":"dork", "values":[ ["k1":"v1"], ["k2":"v2"]]]
       description = "Object nested in array"
     },
    ]
}