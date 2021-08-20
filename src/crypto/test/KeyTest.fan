//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

class KeyTest : CryptoTest
{
  Void testSigning()
  {
    data := "message".toBuf

    // RSA
    pair := crypto.genKeyPair("RSA", 2048)
    verifyKey(pair.priv, "RSA", "PKCS#8")
    verifyKey(pair.pub, "RSA", "X.509")
    sig := pair.priv.sign(data, "SHA512")
    verify(pair.pub.verify(data, "SHA512", sig))

    // type checks
    verify(pair is KeyPair)
    verify(pair.priv is PrivKey)
    verify(pair.pub is PubKey)

    // DSA
    pair = crypto.genKeyPair("DSA", 1024)
    verifyKey(pair.priv, "DSA", "PKCS#8")
    verifyKey(pair.pub, "DSA", "X.509")
    sig = pair.priv.sign(data, "SHA1")
    verify(pair.pub.verify(data, "SHA1", sig))

    k1 := crypto.genKeyPair("RSA", 1024)
    k2 := crypto.genKeyPair("RSA", 1024)
    sig = k1.priv.sign(data, "SHA512")
    verify(!k2.pub.verify(data, "SHA1", sig))
  }

  Void testEncryption()
  {
    msg  := "message"
    pair := crypto.genKeyPair("RSA", 2048)

    // default padding
    enc := pair.pub.encrypt(msg.toBuf)
    verifyEq(msg, pair.priv.decrypt(enc).readAllStr)

    // try to decrypt with wrong key
    enc = pair.pub.encrypt(msg.toBuf)
    bad := crypto.genKeyPair("RSA", 2048)
    verifyErr(Err#) { bad.priv.decrypt(enc) }
    verifyEq(msg, pair.priv.decrypt(enc).readAllStr)
  }

  private Void verifyKey(Key key, Str alg, Str format)
  {
    verifyEq(key.algorithm, alg)
    verifyEq(key.format, format)
  }
}