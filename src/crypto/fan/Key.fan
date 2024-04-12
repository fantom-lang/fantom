//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 2021 Matthew Giannini Creation
//

**************************************************************************
** KeyPair
**************************************************************************

**
** A KeyPair contains a [private key]`PrivKey` and its corresponding
** [public key]`PubKey` in an asymmetric key pair.
**
const mixin KeyPair
{
  ** Get the key pair algorithm
  virtual Str algorithm() { pub.algorithm }

  ** The private key for this pair.
  abstract PrivKey priv()

  ** The public key for this pair.
  abstract PubKey pub()
}

**************************************************************************
** Key
**************************************************************************

**
** Key defines the api for a cryptographic key.
**
const mixin Key
{
  ** The key's algorithm.
  abstract Str algorithm()

  ** Get the encoding format of the key, or null
  ** if the key doesn't support encoding.
  abstract Str? format()

  ** Get the encoded key, or null if the key doesn't
  ** support encoding.
  abstract Buf? encoded()
}

**************************************************************************
** AsymKey
**************************************************************************

**
** A key in an asymmetric key pair
**
const mixin AsymKey : Key
{
  ** Gets the size, in bits, of the key modulus used by the asymmetric algorithm.
  abstract Int keySize()

  ** Get the PEM encoding of the key.
  override abstract Str toStr()
}

**************************************************************************
** PrivKey
**************************************************************************

**
** A private key in an asymmetric key pair. A private key
** can be used to `sign` and `decrypt` data.
**
const mixin PrivKey : AsymKey
{
  ** Sign the contents of the data buffer after applying the given
  ** digest algorithm and return the signature. Throws Err if the
  ** digest algorithm is not supported.
  **
  **    signature := privKey.sign("Message".toBuf, "SHA512")
  **
  abstract Buf sign(Buf data, Str digest)

  ** Decrypt the contents of the data buffer and return the result.
  ** Throws Err if the decryption fails for any reason.
  **
  **    msg := privKey.decrypt(encrypted)
  **
  abstract Buf decrypt(Buf data, Str padding := "PKCS1Padding")
}

**************************************************************************
** PubKey
**************************************************************************

**
** A public key in an asymmetric key pair. A public key
** can be used to `verify` and `encrypt` data.
**
const mixin PubKey : AsymKey
{
  ** Verify the signature of a data buffer. Return true
  ** if the data was signed with the private key corresponding
  ** to this public key using the given digest algorithm.

  ** Throws an Err if the digest algorithm is not supported.
  **
  **    valid := pubKey.verify("Message".toBuf, "SHA512", signature)
  **
  abstract Bool verify(Buf data, Str digest, Buf signature)

  ** Encrypt the contents of the data buffer and return the result.
  **
  ** Throws an Err if the algorithm does not support encryption, or if the
  ** padding is not supported for the algorithm.
  **
  **    encrypted := pubKey.encrypt("Message".toBuf)
  **
  abstract Buf encrypt(Buf data, Str padding := "PKCS1Padding")
}

**************************************************************************
** SecretKey
**************************************************************************

**
** A symmetric key
**
const mixin SymKey : Key { }

**************************************************************************
** MacKey
**************************************************************************

**
** A symmetric key used to generate a message authentication code
**
@NoDoc
const mixin MacKey : SymKey
{
  ** Get the computed MAC size in bytes
  abstract Int macSize()

  ** Complete the digest computation and return the MAC.
  ** The digest is reset after this method is called.
  abstract Buf digest()

  ** Update the digest using *all* the bytes in the buf (regardless of current position).
  ** Return this.
  abstract This update(Buf buf)

  ** Update the digest using only the 8-bit characters in given string.
  ** Return this.
  abstract This updateAscii(Str str)

  ** Update the digest with one byte / 8-bit integer.
  ** Return this.
  abstract This updateByte(Int i)

  ** Update the digest with four byte / 32-bit integer.
  ** Return this.
  abstract This updateI4(Int i)

  ** Update the digest with eight byte / 64-bit integer.
  ** Return this.
  abstract This updateI8(Int i)

  ** Reset the digest. Return this.
  abstract This reset()
}