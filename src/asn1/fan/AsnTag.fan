//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini Creation
//

**
** ASN.1 Tag
**
final const class AsnTag
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Get a [builder]`AsnTagBuilder` for a universal tag with the given id.
  static AsnTagBuilder univ(Int id) { AsnTagBuilder().univ.id(id) }

  ** Get a [builder]`AsnTagBuilder` for a context tag with the given id
  static AsnTagBuilder context(Int id) { AsnTagBuilder().context.id(id) }

  ** Get a [builder]`AsnTagBuilder` for an application tag with the given id
  static AsnTagBuilder app(Int id) { AsnTagBuilder().app.id(id) }

  ** Get a [builder]`AsnTagBuilder` for a private tag with the given id
  static AsnTagBuilder priv(Int id) { AsnTagBuilder().priv.id(id) }

  new make(AsnTagClass cls, Int id, AsnTagMode mode)
  {
    this.cls = cls
    this.id = id
    this.mode = mode
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** The [tag class]`AsnTagClass`
  const AsnTagClass cls

  ** The tag id
  const Int id

  ** The [tag mode]`AsnTagMode`
  const AsnTagMode mode

  @NoDoc AsnTag toCls(AsnTagClass newCls)
  {
    AsnTag(newCls, id, mode)
  }

  @NoDoc AsnTag toId(Int newId)
  {
    AsnTag(cls, newId, mode)
  }

//////////////////////////////////////////////////////////////////////////
// Universal Tags
//////////////////////////////////////////////////////////////////////////

  @NoDoc public static const AsnTag univAny := AsnTag.univ(-1).explicit
  public static const AsnTag univBool := AsnTag.univ(1).explicit
  public static const AsnTag univInt := AsnTag.univ(2).explicit
  public static const AsnTag univBits := AsnTag.univ(3).explicit
  public static const AsnTag univOcts := AsnTag.univ(4).explicit
  public static const AsnTag univNull := AsnTag.univ(5).explicit
  public static const AsnTag univOid := AsnTag.univ(6).explicit
  // public static const AsnTag univObjDesc := AsnTag.explicit(TagClass.univ, 7)
  // public static const AsnTag univExt := AsnTag.explicit(TagClass.univ, 8)
  public static const AsnTag univReal := AsnTag.univ(9).explicit
  public static const AsnTag univEnum := AsnTag.univ(10).explicit
  // public static const AsnTag univPdv := AsnTag.explicit(TagClass.univ, 11)
  public static const AsnTag univUtf8 := AsnTag.univ(12).explicit
  // public static const AsnTag univRelOid := AsnTag.explicit(TagClass.univ, 13)
  // 14 - reserved
  // 15 - reserved
  public static const AsnTag univSeq := AsnTag.univ(16).explicit
  public static const AsnTag univSet := AsnTag.univ(17).explicit
  // public static const AsnTag univNumStr := AsnTag.explicit(TagClass.univ, 18)
  public static const AsnTag univPrintStr := AsnTag.univ(19).explicit
  // public static const AsnTag univTeleStr := AsnTag.explicit(TagClass.univ, 20)
  // public static const AsnTag univVidStr := AsnTag.explicit(TagClass.univ, 21)
  public static const AsnTag univIa5Str := AsnTag.univ(22).explicit
  public static const AsnTag univUtcTime := AsnTag.univ(23).explicit
  public static const AsnTag univGenTime := AsnTag.univ(24).explicit
  public static const AsnTag univGraphStr := AsnTag.univ(25).explicit
  public static const AsnTag univVisStr := AsnTag.univ(26).explicit

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  override Int hash()
  {
    res := 31 + cls.hash
    res = (31 * res) + id
    // res = (31 * res) + mode.hash
    return res
  }

  ** Tag equality is based only the [class]`AsnTagClass` and 'id'. The
  ** [mode]`AsnTagMode` is ignored for eqality purposes.
  override Bool equals(Obj? obj)
  {
    if (this === obj) return true
    that := obj as AsnTag
    if (that == null) return false
    if (this.cls !== that.cls) return false
    if (this.id != that.id) return false
    // if (this.mode != that.mode) return false
    return true
  }

  Bool strictEquals(Obj? obj)
  {
    if (this === obj) return true
    that := obj as AsnTag
    if (that == null) return false
    if (this.cls !== that.cls) return false
    if (this.id != that.id) return false
    if (this.mode != that.mode) return false
    return true
  }

  override Str toStr()
  {
    "<$cls, $id, $mode>"
  }
}

**************************************************************************
** TagClass
**************************************************************************

**
** The tag class for an `AsnTag`
**
enum class AsnTagClass
{
  univ(0x00),
  app(0x40),
  context(0x80),
  priv(0xc0)

  private new make(Int mask) { this.mask = mask }

  const Int mask;

  ** Is this the 'UNIVERSAL' class
  Bool isUniv() { this === AsnTagClass.univ }

  ** Is this the 'APPLICATION' class
  Bool isApp() { this === AsnTagClass.app }

  ** Is this the 'CONTEXT' class
  Bool isContext() { this === AsnTagClass.context }

  ** Is this  the 'PRIVATE' class
  Bool isPriv() { this === AsnTagClass.priv }
}

**************************************************************************
** AsnTagMode
**************************************************************************

**
** The tag mode for a `AsnTag`
**
enum class AsnTagMode { explicit, implicit }

**************************************************************************
** AsnTagBuilder
**************************************************************************

**
** Utility to build an `AsnTag`.
**
** See:
**  - `AsnTag.univ`
**  - `AsnTag.context`
**  - `AsnTag.app`
**  - `AsnTag.priv`
**
class AsnTagBuilder
{
  ** Create an unconfigured builder
  new make() { }

  private AsnTagClass? cls
  private Int? identifier

  ** Set the tag class to universal
  This univ() { this.cls = AsnTagClass.univ; return this }

  ** Set the tag class to context
  This context() { this.cls = AsnTagClass.context; return this }

  ** Set the tag class to application
  This app() { this.cls = AsnTagClass.app; return this }

  ** Set the tag class to private
  This priv() { this.cls = AsnTagClass.priv; return this }

  ** Set the tag identifier
  This id(Int id) { this.identifier = id; return this }

  ** Build the tag with explicit mode
  AsnTag explicit()
  {
    check
    return AsnTag(cls, identifier, AsnTagMode.explicit)
  }

  ** Build the tag with implicit mode
  AsnTag implicit()
  {
    check
    return AsnTag(cls, identifier, AsnTagMode.implicit)
  }

  private Void check()
  {
    if (cls == null) throw AsnErr("Tag class is not configured")
    if (identifier == null) throw AsnErr("Tag identifier not configured")
  }
}