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

    // secp256k1 curve not supported started in Java16
    // https://docs.oracle.com/en/java/javase/17/migrate/removed-tools-and-components.html#GUID-F182E075-858A-4468-9434-8FC1704E7BB7
    if (getJavaMajorVersion < 16)
    {
      // secp256k1 curve
      // private key
      ecPrivLegacy :=
        "-----BEGIN PRIVATE KEY-----
         MIGEAgEAMBAGByqGSM49AgEGBSuBBAAKBG0wawIBAQQg3BYiYrV9YyVXwQmyo2Vp
         Iox+Gk3mYFV17fdewbMVKBehRANCAAT0ng721uClmiIoGYm1bBvmVxuSLTwiCt4Y
         p0jY/EKA4YDUxReIbpAr2pdd3kdX6m1tpT26FrpEAYFm40PsxM4Q
         -----END PRIVATE KEY-----"
      PrivKey privLegacy := Crypto.cur.loadPem(ecPrivLegacy.in, "EC")
      verifyKey(privLegacy, "EC", "PKCS#8")

      // public key
      ecPubLegacy :=
        "-----BEGIN PUBLIC KEY-----
         MFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAE9J4O9tbgpZoiKBmJtWwb5lcbki08Igre
         GKdI2PxCgOGA1MUXiG6QK9qXXd5HV+ptbaU9uha6RAGBZuND7MTOEA==
         -----END PUBLIC KEY-----"
      PubKey pubLegacy := Crypto.cur.loadPem(ecPubLegacy.in, "EC")
      verifyKey(pubLegacy, "EC", "X.509")

      // test sig
      data := "message".toBuf
      sig  := privLegacy.sign(data, "SHA256")
      verify(pubLegacy.verify(data, "SHA256", sig))
    }

    // NIST P-256 curve
    // private key
    ecPriv :=
      "-----BEGIN PRIVATE KEY-----
       MEECAQAwEwYHKoZIzj0CAQYIKoZIzj0DAQcEJzAlAgEBBCBwYc+D4HMQ5OVHQMw9
       KsTo/26oJb6dN5QH1GbFcVysUA==
       -----END PRIVATE KEY-----"
    PrivKey priv := crypto.loadPem(ecPriv.in, "EC")
    verifyKey(priv, "EC", "PKCS#8")

    // private key
    ecPub :=
      "-----BEGIN PUBLIC KEY-----
       MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEI59TOAdnJ7uPgPOdIxj+BhWSQBXK
       S3lsRZJwj5eIYArwUkS9UhkONUGesEk9FQLC2BLzqsegWXWQF9uNf2s6eA==
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