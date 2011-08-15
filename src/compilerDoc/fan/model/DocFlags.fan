//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

**
** DocFlags models the flags used to annotate types and slots
**
final const class DocFlags
{

  const static Int Abstract   := 0x00000001
  const static Int Const      := 0x00000002
  const static Int Ctor       := 0x00000004
  const static Int Enum       := 0x00000008
  const static Int Facet      := 0x00000010
  const static Int Final      := 0x00000020
  const static Int Getter     := 0x00000040
  const static Int Internal   := 0x00000080
  const static Int Mixin      := 0x00000100
  const static Int Native     := 0x00000200
  const static Int Override   := 0x00000400
  const static Int Private    := 0x00000800
  const static Int Protected  := 0x00001000
  const static Int Public     := 0x00002000
  const static Int Setter     := 0x00004000
  const static Int Static     := 0x00008000
  const static Int Storage    := 0x00010000
  const static Int Synthetic  := 0x00020000
  const static Int Virtual    := 0x00040000

  static Int fromName(Str name)
  {
    fromNameMap[name] ?: throw Err("Invalid flag '$name'")
  }

  static Str toNames(Int flags)
  {
    s := StrBuf()
    for (b:=1; b<=Virtual; b=b.shiftl(1))
      if (flags.and(b) != 0) s.join(toNameMap[b])
    return s.toStr
  }

  private const static Int:Str toNameMap
  private const static Str:Int fromNameMap
  static
  {
    toNameMap := Int:Str[:]
    fromNameMap := Str:Int[:]
    DocFlags#.fields.each |f|
    {
      if (f.isStatic && f.isConst && f.type == Int#)
      {
        name := f.name.lower
        code := f.get(null) as Int
        if (name == "ctor") name = "new"
        toNameMap[code]   = name
        fromNameMap[name] = code
      }
    }
    DocFlags.toNameMap = toNameMap
    DocFlags.fromNameMap = fromNameMap
  }

}