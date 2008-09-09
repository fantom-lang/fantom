//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Aug 08  Brian Frank  Creation
//

**
** Key models a keyboard key or key combination.
**
@simple
const class Key
{

//////////////////////////////////////////////////////////////////////////
// Predefined
//////////////////////////////////////////////////////////////////////////

  static const Key a               := predefine('a', "A")
  static const Key b               := predefine('b', "B")
  static const Key c               := predefine('c', "C")
  static const Key d               := predefine('d', "D")
  static const Key e               := predefine('e', "E")
  static const Key f               := predefine('f', "F")
  static const Key g               := predefine('g', "G")
  static const Key h               := predefine('h', "H")
  static const Key i               := predefine('i', "I")
  static const Key j               := predefine('j', "J")
  static const Key k               := predefine('k', "K")
  static const Key l               := predefine('l', "L")
  static const Key m               := predefine('m', "M")
  static const Key n               := predefine('n', "N")
  static const Key o               := predefine('o', "O")
  static const Key p               := predefine('p', "P")
  static const Key q               := predefine('q', "Q")
  static const Key r               := predefine('r', "R")
  static const Key s               := predefine('s', "S")
  static const Key t               := predefine('t', "T")
  static const Key u               := predefine('u', "U")
  static const Key v               := predefine('v', "V")
  static const Key w               := predefine('w', "W")
  static const Key x               := predefine('x', "X")
  static const Key y               := predefine('y', "Y")
  static const Key z               := predefine('z', "Z")

  static const Key num0            := predefine('0', "0")
  static const Key num1            := predefine('1', "1")
  static const Key num2            := predefine('2', "2")
  static const Key num3            := predefine('3', "3")
  static const Key num4            := predefine('4', "4")
  static const Key num5            := predefine('5', "5")
  static const Key num6            := predefine('6', "6")
  static const Key num7            := predefine('7', "7")
  static const Key num8            := predefine('8', "8")
  static const Key num9            := predefine('9', "9")

  static const Key space           := predefine(' ',  "Space")
  static const Key backspace       := predefine('\b', "Backspace")
  static const Key enter           := predefine('\r', "Enter")
  static const Key delete          := predefine(0x7F, "Del")
  static const Key esc             := predefine(0x1B, "Esc")
  static const Key tab             := predefine('\t', "Tab")

  static const Key up              := predefine((1 << 24) + 1,  "Up")
  static const Key down            := predefine((1 << 24) + 2,  "Down")
  static const Key left            := predefine((1 << 24) + 3,  "Left")
  static const Key right           := predefine((1 << 24) + 4,  "Right")
  static const Key pageUp          := predefine((1 << 24) + 5,  "PageUp")
  static const Key pageDown        := predefine((1 << 24) + 6,  "PageDown")
  static const Key home            := predefine((1 << 24) + 7,  "Home")
  static const Key end             := predefine((1 << 24) + 8,  "End")
  static const Key insert          := predefine((1 << 24) + 9,  "Insert")

  static const Key f1              := predefine((1 << 24) + 10, "F1")
  static const Key f2              := predefine((1 << 24) + 11, "F2")
  static const Key f3              := predefine((1 << 24) + 12, "F3")
  static const Key f4              := predefine((1 << 24) + 13, "F4")
  static const Key f5              := predefine((1 << 24) + 14, "F5")
  static const Key f6              := predefine((1 << 24) + 15, "F6")
  static const Key f7              := predefine((1 << 24) + 16, "F7")
  static const Key f8              := predefine((1 << 24) + 17, "F8")
  static const Key f9              := predefine((1 << 24) + 18, "F9")
  static const Key f10             := predefine((1 << 24) + 19, "F10")
  static const Key f11             := predefine((1 << 24) + 20, "F11")
  static const Key f12             := predefine((1 << 24) + 21, "F12")

  static const Key keypadMult      := predefine((1 << 24) + 42, "Keypad*")
  static const Key keypadPlus      := predefine((1 << 24) + 43, "Keypad+")
  static const Key keypadMinus     := predefine((1 << 24) + 45, "Keypad-")
  static const Key keypadDot       := predefine((1 << 24) + 46, "Keypad.")
  static const Key keypadDiv       := predefine((1 << 24) + 47, "Keypad/")
  static const Key keypad0         := predefine((1 << 24) + 48, "Keypad0")
  static const Key keypad1         := predefine((1 << 24) + 49, "Keypad1")
  static const Key keypad2         := predefine((1 << 24) + 50, "Keypad2")
  static const Key keypad3         := predefine((1 << 24) + 51, "Keypad3")
  static const Key keypad4         := predefine((1 << 24) + 52, "Keypad4")
  static const Key keypad5         := predefine((1 << 24) + 53, "Keypad5")
  static const Key keypad6         := predefine((1 << 24) + 54, "Keypad6")
  static const Key keypad7         := predefine((1 << 24) + 55, "Keypad7")
  static const Key keypad8         := predefine((1 << 24) + 56, "Keypad8")
  static const Key keypad9         := predefine((1 << 24) + 57, "Keypad9")
  static const Key keypadEqual     := predefine((1 << 24) + 61, "Keypad=")
  static const Key keypadEnter     := predefine((1 << 24) + 80, "KeypadEnter")

  static const Key capsLock        := predefine((1 << 24) + 82, "CapsLock")
  static const Key numLock         := predefine((1 << 24) + 83, "NumLock")
  static const Key scrollLock      := predefine((1 << 24) + 84, "ScrollLock")
  static const Key pause           := predefine((1 << 24) + 85, "Pause")
  static const Key printScreen     := predefine((1 << 24) + 87, "PrintScreen")

  static const Key alt             := predefine(1 << 16, "Alt")
  static const Key shift           := predefine(1 << 17, "Shift")
  static const Key ctrl            := predefine(1 << 18, "Ctrl")
  static const Key command         := predefine(1 << 22, "Command")

  private new predefine(Int mask, Str str, Bool mod := false)
  {
    this.mask = mask
    this.str  = str
  }

  private static const Int modifierMask := alt.mask | shift.mask | ctrl.mask | command.mask
  private static const Int modifierUnmask := ~modifierMask
  private static const Key none := predefine(0, "")
  private static const Int:Key byMask
  private static const Str:Key byStr
  static
  {
    m := Int:Key[:]
    s := Str:Key[:]
    Key#.fields.each |Field f|
    {
      if (f.isStatic && f.of == Key#)
      {
        Key key := f.get(null)
        m[key.mask] = key
        if (!key.str.isEmpty) s[key.str]  = key
      }
    }
    byMask = m
    byStr  = s
  }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse font from string (see `toStr`).  If invalid
  ** and checked is true then throw ParseErr otherwise
  ** return null.
  **
  static Key fromStr(Str s, Bool checked := true)
  {
    try
    {
      // check predefined name
      key := byStr[s]
      if (key != null) return key

      // split by +
      toks := s.split('+')

      // if one token, then single key not predefined
      if (toks.size == 1)
      {
        x := toks.first
        if (x.size == 1 && !x[0].isAlpha) return makeNew(x[0], x)
        throw Err()
      }

      // combine
      mask := 0
      gotBase := false
      toks.each |Str tok|
      {
        part := fromStr(tok)
        if (!part.isModifier)
        {
          if (gotBase) throw Err()
          gotBase = true
        }
        mask |= part.mask
      }
      return makeNew(mask, s)
    }
    catch {}
    if (checked) throw ParseErr("Invalid Key: $s")
    return null
  }

  **
  ** Iternal lookup by mask: we either return a predefined
  ** instance or create a new one just in case we don't have
  ** a predefined instance defined.
  **
  internal static Key fromMask(Int mask)
  {
    return byMask[mask] ?: makeNew(mask, mask.toChar)
  }

  **
  ** Private constructor
  **
  private new makeNew(Int mask, Str str)
  {
    this.mask = mask
    this.str  = str
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Hash code is based on keycode.
  **
  override Int hash()
  {
    return mask
  }

  **
  ** Equality is based on keycode.
  **
  override Bool equals(Obj that)
  {
    x := that as Key
    if (x == null) return false
    return mask == x.mask
  }

  **
  ** Format as '"TODO"'
  **
  override Str toStr()
  {
    if (str != null) return str
    s := StrBuf()
    if (isShift)   s.join(shift.str,   "+")
    if (isAlt)     s.join(alt.str,     "+")
    if (isCtrl)    s.join(ctrl.str,    "+")
    if (isCommand) s.join(command.str, "+")
    baseMask := mask & modifierUnmask
    if (baseMask != 0) s.join(fromMask(baseMask).str, "+")
    return s.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Modifiers
//////////////////////////////////////////////////////////////////////////

  **
  ** Decompose a key combination into its individual keys.
  ** If instance isn't a combination then return a list with
  ** one item (this instance).
  **
  Key[] list()
  {
    toks := toStr.split('+')
    return toks.map(Key[,]) |Str tok->Key| { return fromStr(tok) }
  }

  **
  ** Is this instance is a modifier which may be combined
  ** with other keys: shift, alt, ctrl, command.
  **
  Bool isModifier() { return mask & modifierUnmask == 0 }

  **
  ** Return if any of the modifier keys are down.
  **
  Bool hasModifier() { return mask & modifierMask != 0 }

  **
  ** Return if the specified modifier is down.
  **
  Bool isDown(Key modifier) { return mask & modifier.mask != 0 }

  **
  ** Convenience for 'isDown(shift)'
  **
  Bool isShift() { return isDown(shift) }

  **
  ** Convenience for 'isDown(alt)'
  **
  Bool isAlt() { return isDown(alt) }

  **
  ** Convenience for 'isDown(ctrl)'
  **
  Bool isCtrl() { return isDown(ctrl) }

  **
  ** Convenience for 'isDown(comand)'
  **
  Bool isCommand() { return isDown(command) }

  **
  ** Add two keys to create a new key combination.
  ** Throws ArgErr if neither this nor x returns true
  ** true for `isModifier`.
  **
  Key plus(Key x)
  {
    if (!isModifier && !x.isModifier) throw ArgErr("Neither is modifier: $this + $x")
    return makeNew(mask|x.mask, null)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Internal mask is based on SWT mask values
  internal const Int mask

  ** String encoding
  internal const Str str
}