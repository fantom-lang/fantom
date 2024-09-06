//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Sep 24  Brian Frank  Copy from HxMsg
//

**
** ActorMsg provides simple immutable tuple to use for actor messages.
**
const class ActorMsg
{
  ** Constructor with zero arguments
  new make0(Str id)
  {
    this.id = id
  }

  ** Constructor with one argument
  new make1(Str id, Obj? a)
  {
    this.id = id
    this.a  = a
  }

  ** Constructor with two arguments
  new make2(Str id, Obj? a, Obj? b)
  {
    this.id = id
    this.a  = a
    this.b  = b
  }

  ** Constructor with three arguments
  new make3(Str id, Obj? a, Obj? b, Obj? c)
  {
    this.id = id
    this.a  = a
    this.b  = b
    this.c  = c
  }

  ** Constructor with four arguments
  new make4(Str id, Obj? a, Obj? b, Obj? c, Obj? d)
  {
    this.id = id
    this.a  = a
    this.b  = b
    this.c  = c
    this.d  = d
  }

  ** Constructor with five arguments
  new make5(Str id, Obj? a, Obj? b, Obj? c, Obj? d, Obj? e)
  {
    this.id = id
    this.a  = a
    this.b  = b
    this.c  = c
    this.d  = d
    this.e  = e
  }

  ** Message identifier key
  const Str id

  ** Argument a
  const Obj? a

  ** Argument b
  const Obj? b

  ** Argument c
  const Obj? c

  ** Argument d
  const Obj? d

  ** Argument e
  const Obj? e

  ** Hash is based on id and arguments
  override Int hash()
  {
    hash := id.hash
    if (a != null) hash = hash.xor(a.hash)
    if (b != null) hash = hash.xor(b.hash)
    if (c != null) hash = hash.xor(c.hash)
    if (d != null) hash = hash.xor(d.hash)
    if (e != null) hash = hash.xor(e.hash)
    return hash
  }

  ** Equality is based on id and arguments
  override Bool equals(Obj? that)
  {
    m := that as ActorMsg
    if (m == null) return false
    return id == m.id &&
            a == m.a  &&
            b == m.b  &&
            c == m.c  &&
            d == m.d  &&
            e == m.e
  }

  ** Return debug string representation
  override Str toStr()
  {
    toDebugStr("ActorMsg", id, a, b, c, d, e)
  }

  ** Format actor msg tuple as "type(id, a=a, b=b, ...)"
  @NoDoc static Str toDebugStr(Str type, Obj? id, Obj? a, Obj? b := null, Obj? c := null, Obj? d := null, Obj? e := null)
  {
    s := StrBuf()
    s.add(type).add("(").add(id)
    toDebugArg(s, "a", a)
    toDebugArg(s, "b", b)
    toDebugArg(s, "c", c)
    toDebugArg(s, "d", d)
    toDebugArg(s, "e", e)
    return s.add(")").toStr
  }

  private static Void toDebugArg(StrBuf b, Str name, Obj? arg)
  {
    if (arg == null) return
    b.addChar(' ').add(name).addChar('=')
    try
    {
      s := arg.toStr
      if (s.size <= 64) b.add(s)
      else b.add(s[0..64]).add("...")
    }
    catch (Err e) b.add(e.toStr)
  }
}

