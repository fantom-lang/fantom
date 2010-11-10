#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Aug 07  Brian Frank  Creation
//   08 Sep 09  Brian Frank  Rework fandoc -> example
//

**
** Working with Lists
**
class Lists
{
  Void main()
  {
    literals
    access
    modify
    stack
    iteration
    search
    join
    map
    reduce
    sorting
    readOnly
  }

  Void literals()
  {
    echo("\n--- literals ---")
    show(Int[10, 20, 30],   "list of the three Ints 10, 20, and 30")
    show([10, 20, 30],      "same as above using type inference")
    show(Int?[10, 20, 30],  "list of Ints which might contain null")
    show(Int[,],            "empty list of Ints")
    show(Obj[,],            "empty list of Objs")
    show([,],               "empty list of Objs?")
    show([1, 2f, 3],        "evaluates to Num[]")
    show(Num[1, 2, 3],      "evaluates to Num[]")
  }

  Void access()
  {
    echo("\n--- access ---")
    list := ["a", "b", "c", "d"]
    show(list.size,          "get number of items, returns 4")
    show(list.isEmpty,       "convenience for size == 0")
    show(list.index("c"),    "index of 'c', returns 2")
    show(list.index("x"),    "index of 'x', returns null")
    show(list.contains("c"), "does list contain 'c', returns true")
    show(list.first,         "returns 'a'")
    show(list.last,          "retsurns 'd'")
    show(list.get(2),        "return item at index 2, returns 'c'")
    show(list[2],            "convenience for list.get(2), returns 'c'")
    show(list[-1],           "last item 'd'")
    show(list[-3],           "item at size-3, returns 'b'")
    show(list.slice(0..2),   "slice 0 to 1 inclusive, returns [a,b,c]")
    show(list[0..2],         "convenience for list.slice(0..2)")
    show(list[0..<2],        "slice 0 to 2 exclusive [a,b]")
    show(list[-3..-1],       "slice size-3 to size-1 inclusive [b,c,d]")
  }

  Void modify()
  {
    echo("\n--- modify ---")
    list := ["one", "two", "three"]
    show(list.add("four"),        "add 'four' to end of list")
    show(list.remove("four"),     "remove 'four' from list")
    show(list.removeAt(0),        "remove item at index 0")
    show(list.insert(0, "x"),     "insert at index 0")
    show(list.insert(-1, "y"),    "insert at end of list")
    show(list.addAll(["a", "b"]), "add 'a' and 'b' to end of list")
    show(list.set(2, "z"),        "set item at index 2 to 'z'")
    show(list[2] = "z",           "convenience for list.set(2, 'z')")
    show(list.clear,              "remove all the items from the list")
  }

  Void stack()
  {
    echo("\n--- stack ---")
    stack := Str[,]
    show(stack.push("a"),    "[a]")
    show(stack.push("b"),    "[a, b]")
    show(stack.peek,         "returns 'b'")
    show(stack.pop,          "returns 'b'")
    show(stack.pop,          "returns 'a'")
    show(stack.pop,          "returns null")
  }

  Void iteration()
  {
    echo("\n--- iteration ---")

    list := ["a", "b", "c"]
    Str r := ""

    r = ""; list.each |Str s| { r += "$s " }
    show(r, "each")

    r = ""; list.each |Str s, Int i| { r += "$i=$s " }
    show(r, "each with index")

    r = ""; list.each |s, i| { r += "$i=$s " }
    show(r, "each with type inference")

    r = ""; list.eachr |s| { r += "$s " }
    show(r, "reverse iteration")

    x := list.eachWhile |s| { s == "b" ? 99 : null }
    show(x, "iterate until b, then return 99")
  }

  Void search()
  {
    echo("\n--- search ---")

    x := [0, 1, 2, 3, 4]
    y := ["a", 3, "foo", 5sec, null]
    z := ["albatross", "dog", "horse"]

    show(x.find |v| { v.toStr == "3" },  "returns 3")
    show(x.find |v| { v.toStr == "7" },  "returns null")
    show(x.findAll |v| { v.isEven },     "returns [0, 2, 4]")
    show(x.exclude |v| { v.isEven },     "returns [1, 3]")
    show(y.findType(Str#),               "returns Str[a, foo]")
    show(z.max,                          "returns horse")
    show(z.min,                          "returns albatross")
    show(z.min |a, b| { a.size <=> b.size }, "returns dog")
  }

  Void join()
  {
    echo("\n--- join ---")
    x := ['a', 'b', 'c']
    show(x.join,                        "returns 979899")
    show(x.join(","),                   "returns 97,98,99")
    show(x.join(",") |v| { v.toChar },  "returns a,b,c")
    show(x.join("-", Int#toChar.func),  "returns a-b-c")
  }

  Void map()
  {
    echo("\n--- map ---")
    x := [12, 13, 14]
    show(x.map |v->Str| { v.toHex }, "convert ints to hex strings [c, d, e]")
  }

  Void reduce()
  {
    echo("\n--- reduce ---")
    x := [12, 13, 14]
    show(x.reduce(0) |r, v| { v.plus(r) }, "sum list of ints 39")
  }

  Void sorting()
  {
    echo("\n--- sorting ---")
    s := ["candy", "ate", "he"]

    show(s.sort,                             "default ordering [ate, candy, he]")
    show(s.sort |a,b| { a.size <=> b.size }, "order by size [he, ate, candy]")
  }

  Void readOnly()
  {
    q := ["a", "b", "c"]
    r := q.rw;  show(r, "rw on read/write returns this (r === q)")
    s := q.ro;  show(s, "s is readonly with items in q")
    t := s.ro;  show(t, "ro on readonly returns this (t === s)")
    u := s.rw;  show(u, "read/write with items in s (u !== s)")
    show(s.isRO,        "returns true")
    show(s.isRW,        "return false")
  }

  Void show(Obj? result, Str what)
  {
    resultStr := "" + result
    if (resultStr.size > 40) resultStr = resultStr[0..40] + "..."
    echo(what.padr(40) + " => " + resultStr)
  }

}



