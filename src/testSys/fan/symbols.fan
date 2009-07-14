//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation
//

Bool boolT := true
boolF := false

Int intA := 0xabcd_0123_eeff_7788
intB := -4

floatA := -5f

** fandoc
decimalA := 6d + 0.7d

** fandoc
durA := 30ms

strA := "alpha"
strB := "line1\nline2\nline3_\u02c3_"

uriA := `http://fandev.org/`

Num numA := 45
Num? numB := null

listA := ["a", "b", "c"]
listB := [2, 3f, 4d]
listC := [["a"], ["b"], ["c"]]
listD := [SerA { i = 0 }, SerA { i = 1 }, SerA { i = 2 }]

mapA := [0:"zero", 1:"one"]
mapB := [2: SerA { i = 2 }, 3: SerA { i = 3 }]

serialA := Version("2.3")
serialB := [Version("1"), Version("2")]
serialC := SerA { i = 12345; s = "symbols!" }






