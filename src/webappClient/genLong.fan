#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

using build

**
** Generate the lookup table used to parse Str values into Longs in Javascript.
**
class GenLongTable
{
  Void main(Str[] args)
  {
    genTable
  }

  Void genTable()
  {
    echo("  Int[][] table := ")
    echo("  [")
    (0..19).each |place|
    {
      echo("    [")
      (0..9).each |digit|
      {
        val := digit * 10.pow(place)
        hi := (val >> 32) & 0xffff_ffff
        lo := val & 0xffff_ffff
        echo("      new Long(0x$hi.toHex, 0x$lo.toHex),")
      }
      echo("    ],")
    }
    echo("    ]")
  }
}