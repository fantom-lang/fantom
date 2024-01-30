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
    bad  := "messaGe".toBuf

    // RSA
    pair := crypto.genKeyPair("RSA", 2048)
    verifyKey(pair.priv, "RSA", "PKCS#8")
    verifyKey(pair.pub, "RSA", "X.509")
    sig := pair.priv.sign(data, "SHA512")
    verify(pair.pub.verify(data, "SHA512", sig))
    verifyFalse(pair.pub.verify(bad, "SHA512", sig))

    // type checks
    verify(pair is KeyPair)
    verify(pair.priv is PrivKey)
    verify(pair.pub is PubKey)

    // EC
    pair = crypto.genKeyPair("EC", 256)
    verifyKey(pair.priv, "EC", "PKCS#8")
    verifyKey(pair.pub,  "EC", "X.509")
    sig = pair.priv.sign(data, "SHA256")
    verify(pair.pub.verify(data, "SHA256", sig))
    verifyFalse(pair.pub.verify(bad, "SHA256", sig))

    // DSA
    pair = crypto.genKeyPair("DSA", 1024)
    verifyKey(pair.priv, "DSA", "PKCS#8")
    verifyKey(pair.pub, "DSA", "X.509")
    sig = pair.priv.sign(data, "SHA1")
    verify(pair.pub.verify(data, "SHA1", sig))
    verifyFalse(pair.pub.verify(bad, "SHA1", sig))

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

  Void testLoadEc()
  {
    // # Genereate test keypair
    // $ openssl ecparam -name secp256k1 -genkey -noout -out priv1.pem
    // $ openssl ec -in priv1.pem -pubout > pub.pem
    //
    // TODO: we cannot read the standard pkcs1 output; so for the time
    // being we need to convert to pkcs8
    // $ openssl pkey -in priv1.pem -out priv8.pem

    // private key
    ecPriv :=
      "-----BEGIN PRIVATE KEY-----
       MIGEAgEAMBAGByqGSM49AgEGBSuBBAAKBG0wawIBAQQg3BYiYrV9YyVXwQmyo2Vp
       Iox+Gk3mYFV17fdewbMVKBehRANCAAT0ng721uClmiIoGYm1bBvmVxuSLTwiCt4Y
       p0jY/EKA4YDUxReIbpAr2pdd3kdX6m1tpT26FrpEAYFm40PsxM4Q
       -----END PRIVATE KEY-----"
    PrivKey priv := Crypto.cur.loadPem(ecPriv.in, "EC")
    verifyKey(priv, "EC", "PKCS#8")

    // public key
    ecPub :=
      "-----BEGIN PUBLIC KEY-----
       MFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAE9J4O9tbgpZoiKBmJtWwb5lcbki08Igre
       GKdI2PxCgOGA1MUXiG6QK9qXXd5HV+ptbaU9uha6RAGBZuND7MTOEA==
       -----END PUBLIC KEY-----"
    PubKey pub := Crypto.cur.loadPem(ecPub.in, "EC")
    verifyKey(pub, "EC", "X.509")

    // test sig
    data := "message".toBuf
    sig  := priv.sign(data, "SHA256")
    verify(pub.verify(data, "SHA256", sig))
  }

  private Void verifyKey(Key key, Str alg, Str format)
  {
    verifyEq(key.algorithm, alg)
    verifyEq(key.format, format)
  }
}