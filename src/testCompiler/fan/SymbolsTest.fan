//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation
//

using compiler

**
** SymbolsTest
**
class SymbolsTest : CompilerTest
{

  Void testBasics()
  {
    symbolsStr =
    "Int foo := 3
     bar := 10sec"
    compile("class Foo {}")
  }

}