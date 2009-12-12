#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Apr 08  Brian Frank  Creation
//   08 Sep 09  Brian Frank  Rework fandoc -> example
//

**
** Working with Maps
**
class Maps
{
  Void main()
  {
    signatures
    literals
    access
    modify
    listConversion
    iteration
    search
    map
    reduce
    caseInsensitive
  }


  Void signatures()
  {
    echo("\n--- signatures ---")
    show([sys::Int:sys::Str]#,  "formal signature Int keys, Str vals")
    show([Int:Str]#,            "unqualified type names")
    show(Int:Str#,              "you can omit brackets most of the time")
    show(Int:Str?#,             "Int keys, Str? vals (might store null)")
    show([Int:Str]?#,           "Int:Str variable which might be null")
    show(Str:Int[]#,            "Str keys, Int[] vals")
    show([Str:Int][]#,          "list of Str:Int maps (need brackets)")
  }

  Void literals()
  {
    echo("\n--- literals ---")
    show(Int:Str[4:"four", 5:"five"], "maps Int to Str")
    show([4:"four", 5:"five"],        "same as above with type inference")
    show([4:"four", 5f:"five"],       "Num:Str map with type inference")
    show(Int:Str[:],                  "empty Int:Str map")
    show([:],                         "empty Obj:Obj map")
  }

  Void access()
  {
    echo("\n--- access ---")
    map := [0:"zero", 1:"one", 2:"two"]
    show(map.size,             "number of key/value pairs, returns 3")
    show(map.isEmpty,          "convenience for size == 0")
    show(map.containsKey(2),   "returns true")
    show(map.get(2),           "value keyed by 2, returns two")
    show(map.get(9),           "returns null")
    show(map.get(9, "nine"),   "returns nine")
    show(map[2],               "convenience for map.get(2), returns two")
  }

  Void modify()
  {
    echo("\n--- modify ---")
    map := [0:"zero", 1:"one", 2:"two"]
    map.add(3, "three");     show(map, "add 3:three key/value pair")
    map.addAll([4:"four"]);  show(map, "aadds all the key/value pairs to map")
    map.setAll([4:"Four"]);  show(map, "sets or adds all key/value pairs in list")
    map.set(3, "Three");     show(map, "aset value for for key 3")
    map[2] = "Two";          show(map, "aconvenience for map.set(2, Two)")
    map[5] = "five";         show(map, "adds 5:five key/value pair (new key)")
    map.clear;               show(map, "remove all the pairs")
  }

  Void listConversion()
  {
    echo("\n--- listConversion ---")
    x := [0:"zero", 1:"one", 2:"two"]
    show(x.keys,      "list the keys [0, 1, 2]")
    show(x.vals,      "list the vals [zero, one, two]")
  }

  Void iteration()
  {
    echo("\n--- iteration ---")
    map := [0:"zero", 1:"one", 2:"two"]

    r := ""; map.each |val| { r += "$val " }
    show(r, "each iteration")

    r = ""; map.each |v, k| { r += ("$k:$v ") }
    show(r, "each iteration with key")
 }

  Void search()
  {
    echo("\n--- search ---")
    x := [0:"zero", 1:"one", 2:"two", 3:"three"]
    show(x.find |v| { v[0] == 't' },     "two")
    show(x.find |v| { v[0] == 'x' },     "null")
    show(x.findAll |v| { v[0] == 't' },  "[2:two, 3:three]")
    show(x.findAll |v, k| { k.isEven },  "[0:zero, 2:two]")
    show(x.exclude |v, k| { k.isEven },  "[1:one, 3:three]")
  }

  Void map()
  {
    echo("\n--- map ---")
    x := [4:"four", 5:"five", 6:"six"]
    show(x.map |v, k->Str| { return "$k=$v" }, "[4:4=four, 5:5=five, 6:6=six]")
  }

  Void reduce()
  {
    echo("\n--- reduce ---")
    x := [4:"four", 5:"five", 6:"six"]
    show(x.reduce(StrBuf()) |StrBuf buf, v| { buf->add(v)  }, "fourfivesix")
  }

  Void caseInsensitive()
  {
    echo("\n--- caseInsensitive ---")
    x := Str:Str[:] { it.caseInsensitive = true }
    x["a"] = "alpha";  show(x, "[a:alpha]")
    r := x["A"];       show(r, "alpha")
    x["B"] = "beta";   show(x, "[B:beta, a:alpha]")
    x.remove("b");     show(x, "[a:alpha]")
  }

  Void show(Obj? result, Str what)
  {
    resultStr := "" + result
    if (resultStr.size > 40) resultStr = resultStr[0..40] + "..."
    echo(what.padr(40) + " => " + resultStr)
  }

}



