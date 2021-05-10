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
  const static Int Once       := 0x00080000

  static Bool isAbstract (Int flags) { flags.and(DocFlags.Abstract)  != 0 }
  static Bool isConst    (Int flags) { flags.and(DocFlags.Const)     != 0 }
  static Bool isCtor     (Int flags) { flags.and(DocFlags.Ctor)      != 0 }
  static Bool isEnum     (Int flags) { flags.and(DocFlags.Enum)      != 0 }
  static Bool isFacet    (Int flags) { flags.and(DocFlags.Facet)     != 0 }
  static Bool isFinal    (Int flags) { flags.and(DocFlags.Final)     != 0 }
  static Bool isGetter   (Int flags) { flags.and(DocFlags.Getter)    != 0 }
  static Bool isInternal (Int flags) { flags.and(DocFlags.Internal)  != 0 }
  static Bool isMixin    (Int flags) { flags.and(DocFlags.Mixin)     != 0 }
  static Bool isNative   (Int flags) { flags.and(DocFlags.Native)    != 0 }
  static Bool isOverride (Int flags) { flags.and(DocFlags.Override)  != 0 }
  static Bool isPrivate  (Int flags) { flags.and(DocFlags.Private)   != 0 }
  static Bool isProtected(Int flags) { flags.and(DocFlags.Protected) != 0 }
  static Bool isPublic   (Int flags) { flags.and(DocFlags.Public)    != 0 }
  static Bool isSetter   (Int flags) { flags.and(DocFlags.Setter)    != 0 }
  static Bool isStatic   (Int flags) { flags.and(DocFlags.Static)    != 0 }
  static Bool isStorage  (Int flags) { flags.and(DocFlags.Storage)   != 0 }
  static Bool isSynthetic(Int flags) { flags.and(DocFlags.Synthetic) != 0 }
  static Bool isVirtual  (Int flags) { flags.and(DocFlags.Virtual)   != 0 }
  static Bool isOnce     (Int flags) { flags.and(DocFlags.Once)      != 0 }

  static Int fromName(Str name)
  {
    fromNameMap[name] ?: throw Err("Invalid flag '$name'")
  }

  static Int fromNames(Str names)
  {
    flags := 0
    names.split.each |name| { flags = flags.or(fromName(name)) }
    return flags
  }

  ** Type flags to display including final 'class' or 'mixin'
  static Str toTypeDis(Int f)
  {
    s := StrBuf()

    if (isInternal(f)) s.join("internal")

    if (isAbstract(f) && !isMixin(f)) s.join("abstract")

    if (isEnum(f))       s.join("enum")
    else if (isFacet(f)) s.join("facet")
    else if (isConst(f)) s.join("const")

    if (isMixin(f)) s.join("mixin")
    else s.join("class")

    return s.toStr()
  }

  static Str toSlotDis(Int f)
  {
    s := StrBuf()

    if (isInternal(f)) s.join("internal")
    else if (isProtected(f)) s.join("protected")
    else if (isPrivate(f)) s.join("private")

    if (isAbstract(f)) s.join("abstract")
    else if (isVirtual(f)) s.join("virtual")

    if (isCtor(f))     s.join("new")
    if (isConst(f))    s.join("const")
    if (isStatic(f))   s.join("static")
    if (isOverride(f)) s.join("override")
    if (isFinal(f))    s.join("final")

    return s.toStr()
  }

  static Str toNames(Int flags)
  {
    s := StrBuf()
    for (b:=1; b<=Virtual; b=b.shiftl(1))
    {
      if (flags.and(b) != 0) s.join(toNameMap[b])
    }
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