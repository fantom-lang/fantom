//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    5 Nov 06  Brian Frank  Original
//   14 Jul 09  Brian Frank  Create from "build.fan"
//


**
** Sys test suite.
**

@podDepends = [Depend("sys 1.0")]
@podSrcDirs = [`fan/`]
@podResDirs = [`res/`, `locale/`]
@nodoc
@podIndexFacets = [@testSysByStr, @testSys::testSysByType]

pod testSys
{
  Bool boolA := true
  boolB := false

  virtual Int intA := 0xabcd_0123_eeff_7788
  intB := -4

  floatA := -5f
  floatB := 0f
  floatC := 0f
  floatD := 0f

  decimalA := 6d + 0.7d

  durA := 30ms

  strA := "alpha"
  strB := "line1\nline2\nline3_\u02c3_"

  uriA := `http://fandev.org/`

  Num numA := 45
  Num? numB := null

  virtual listA := ["a", "b", "c"]
  listB := [2, 3f, 4d]
  listC := [["a"], ["b"], ["c"]]
  Obj[] listD := [SerA { i = 0 }, SerA { i = 1 }, SerA { i = 2 }]
  Obj[] listE := [,]

  mapA := [0:"zero", 1:"one"]
  mapB := [2: SerA { i = 2 }, 3: SerA { i = 3 }]

  serialA := Version("2.3")
  serialB := [Version("1"), Version("2")]
  Obj serialC := SerA { i = 12345; s = "symbols!" }

  verA := Version("0")
  monA := Month.jan

  Str[] testSysByStr := Str[,]
  Type[] testSysByType := Type[,]
}