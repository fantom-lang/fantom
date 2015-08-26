//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Aug 08  Brian Frank  Creation
//   18 Feb 15  Brian Frank  Port to domkit
//

**
** Key models a key code
**
@Js
@Serializable { simple = true }
const class Key
{

//////////////////////////////////////////////////////////////////////////
// Constants
//////////////////////////////////////////////////////////////////////////

  static const Key a            := make(65, "A")
  static const Key b            := make(66, "B")
  static const Key c            := make(67, "C")
  static const Key d            := make(68, "D")
  static const Key e            := make(69, "E")
  static const Key f            := make(70, "F")
  static const Key g            := make(71, "G")
  static const Key h            := make(72, "H")
  static const Key i            := make(73, "I")
  static const Key j            := make(74, "J")
  static const Key k            := make(75, "K")
  static const Key l            := make(76, "L")
  static const Key m            := make(77, "M")
  static const Key n            := make(78, "N")
  static const Key o            := make(79, "O")
  static const Key p            := make(80, "P")
  static const Key q            := make(81, "Q")
  static const Key r            := make(82, "R")
  static const Key s            := make(83, "S")
  static const Key t            := make(84, "T")
  static const Key u            := make(85, "U")
  static const Key v            := make(86, "V")
  static const Key w            := make(87, "W")
  static const Key x            := make(88, "X")
  static const Key y            := make(89, "Y")
  static const Key z            := make(90, "Z")

  static const Key num0         := make(48, "0")
  static const Key num1         := make(49, "1")
  static const Key num2         := make(50, "2")
  static const Key num3         := make(51, "3")
  static const Key num4         := make(52, "4")
  static const Key num5         := make(53, "5")
  static const Key num6         := make(54, "6")
  static const Key num7         := make(55, "7")
  static const Key num8         := make(56, "8")
  static const Key num9         := make(57, "9")

  static const Key space        := make(32, "Space")
  static const Key backspace    := make(8,  "Backspace")
  static const Key enter        := make(13, "Enter")
  static const Key delete       := make(46, "Del")
  static const Key esc          := make(27, "Esc")
  static const Key tab          := make(9,  "Tab")
  static const Key capsLock     := make(20, "CapsLock")

  static const Key semicolon    := make(186, "Semicolon")
  static const Key equal        := make(187, "Equal")
  static const Key comma        := make(188, "Comma")
  static const Key dash         := make(189, "Dash")
  static const Key period       := make(190, "Period")
  static const Key slash        := make(191, "Slash")
  static const Key backtick     := make(192, "Backtick")
  static const Key openBracket  := make(219, "OpenBracket")
  static const Key backSlash    := make(220, "BackSlash")
  static const Key closeBracket := make(221, "CloseBracket")
  static const Key quote        := make(222, "Quote")

  static const Key left         := make(37, "Left")
  static const Key up           := make(38, "Up")
  static const Key right        := make(39, "Right")
  static const Key down         := make(40, "Down")
  static const Key pageUp       := make(33, "PageUp")
  static const Key pageDown     := make(34, "PageDown")
  static const Key home         := make(36, "Home")
  static const Key end          := make(35, "End")
  static const Key insert       := make(45, "Insert")

  static const Key f1           := make(112, "F1")
  static const Key f2           := make(113, "F2")
  static const Key f3           := make(114, "F3")
  static const Key f4           := make(115, "F4")
  static const Key f5           := make(116, "F5")
  static const Key f6           := make(117, "F6")
  static const Key f7           := make(118, "F7")
  static const Key f8           := make(119, "F8")
  static const Key f9           := make(120, "F9")
  static const Key f10          := make(121, "F10")

  static const Key alt          := make(18, "Alt")
  static const Key shift        := make(16, "Shift")
  static const Key ctrl         := make(17, "Ctrl")
  static const Key meta         := make(91, "Meta")

//////////////////////////////////////////////////////////////////////////
// Registry
//////////////////////////////////////////////////////////////////////////

  private static const Int:Key byCode
  private static const Str:Key byName
  static
  {
    c := Int:Key[:]
    n := Str:Key[:]
    Key#.fields.each |Field f|
    {
      if (f.isStatic && f.type == Key#)
      {
        Key key := f.get(null)
        c.add(key.code, key)
        n.add(key.name, key)
      }
    }
    // additional cross browser mapping
    c.add(173, dash)
    c.add(61,  equal)
    c.add(59,  semicolon)
    c.add(224, meta)
    c.add(93,  meta)
    byCode = c
    byName = n
  }

//////////////////////////////////////////////////////////////////////////
// Lookup
//////////////////////////////////////////////////////////////////////////

  ** Lookup by string name
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      key := byName[s]
      if (key != null) return key
    }
    catch {}
    if (checked) throw ParseErr("Invalid Key: $s")
    return null
  }

  ** Lookup by key code.
  static Key fromCode(Int code)
  {
    return byCode[code] ?: make(code, "0x${code.toHex}")
  }

  ** Private constructor
  private new make(Int code, Str name)
  {
    this.code = code
    this.name = name
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** Key name
  const Str name

  ** Hash code is based on name.
  override Int hash() { name.hash }

  ** Equality is based on name.
  override Bool equals(Obj? that)
  {
    x := that as Key
    if (x == null) return false
    return name == x.name
  }

  ** Return `name`.
  override Str toStr() { name }

  ** Key code
  const Int code
}