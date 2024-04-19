//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini   Creation
//

using crypto

**************************************************************************
** JKeyPair
**************************************************************************

const class JKeyPair : KeyPair
{
  native static JKeyPair genKeyPair(Str algorithm, Int bits)

  new make(JPrivKey priv, JPubKey pub)
  {
    this.priv = priv
    this.pub  = pub
  }
  override const JPrivKey priv
  override const JPubKey pub
}

**************************************************************************
** JKey
**************************************************************************

native abstract const class JKey : Key
{
}

**************************************************************************
** JPrivKey
**************************************************************************

native const class JPrivKey : JKey, PrivKey
{
  static JPrivKey decode(Buf der, Str algorithm)

  override Str  algorithm()
  override Str? format()
  override Buf? encoded()
  override Int  keySize()
  override Buf  sign(Buf data, Str digest)
  override Buf  decrypt(Buf data, Str padding := "PKCS1Padding")
  override Str  toStr()
}

**************************************************************************
** JPubKey
**************************************************************************

native const class JPubKey : JKey, PubKey
{
  static JPubKey decode(Buf der, Str algorithm)

  override Str  algorithm()
  override Str? format()
  override Buf? encoded()
  override Int  keySize()
  override Bool verify(Buf data, Str digest, Buf signature)
  override Buf  encrypt(Buf data, Str padding := "PKCS1Padding")
  override Str  toStr()
}

**************************************************************************
** JPubKey
**************************************************************************
@NoDoc
native const class JMacKey : MacKey
{
  static JMacKey load(Buf key, Str algorithm)

  override Str algorithm()
  override Str? format()
  override Buf? encoded()
  override Int macSize()
  override Buf digest()
  override This update(Buf buf)
  override This updateAscii(Str str)
  override This updateByte(Int i)
  override This updateI4(Int i)
  override This updateI8(Int i)
  override This reset()
}