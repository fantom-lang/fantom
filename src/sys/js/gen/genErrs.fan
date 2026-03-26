//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Mar 2023  Matthew Giannini  Creation
//

class GenErrs
{
  static const Str[] errTypes := [
    "ArgErr",
    "CancelledErr",
    "CastErr",
    "ConstErr",
    "FieldNotSetErr",
    "IndexErr",
    "InterruptedErr",
    "IOErr",
    "NameErr",
    "NotImmutableErr",
    "NullErr",
    // "ParseErr",
    "ReadonlyErr",
    "TestErr",
    "TimeoutErr",
    "UnknownKeyErr",
    "UnknownPodErr",
    "UnknownServiceErr",
    "UnknownSlotErr",
    "UnknownFacetErr",
    "UnknownTypeErr",
    "UnresolvedErr",
    "UnsupportedErr",
  ]

  static Int main(Str[] args)
  {
    sb := StrBuf()
    errTypes.each |type|
    {
      sb.add(
        """/** ${type} */
           class ${type} extends Err {
             constructor(msg = "", cause = null) { super(msg, cause); } 
             \$typeof() { return ${type}.\$type; }
             static make(msg="", cause=null) { return new ${type}(msg, cause); }
           }
           """
      ).add("\n")
    }
    echo(sb)
    return 0
  }
}