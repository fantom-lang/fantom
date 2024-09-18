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
    if (Env.cur.javaVersion < 16)
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

  Void testLoadSEC1EncodedEC()
  {
    //secp224r1
    secp224r1Priv :=
      "-----BEGIN EC PRIVATE KEY-----
       MGgCAQEEHNPusR74D/x3agjeySMQDuCInyqHslY9TeDyoOOgBwYFK4EEACGhPAM6
       AAQR6uUh2YHV6Aw9Mi+TTOWtdsiZsb0okM88O/oFy9R27eroXszaEDXO7c+EIZe0
       yQRBXRXgUqssdA==
       -----END EC PRIVATE KEY-----"

    secp224r1X509 :=
      "-----BEGIN CERTIFICATE-----
       MIIBgzCCATECCQCpD+k+mT0boDAKBggqhkjOPQQDAjBTMQswCQYDVQQGEwJVUzEL
       MAkGA1UECAwCVkExETAPBgNVBAcMCFJpY2htb25kMQ8wDQYDVQQKDAZGYW50b20x
       EzARBgNVBAMMCmZhbnRvbS5vcmcwHhcNMjQwOTE2MjAwNjQ2WhcNMjUwOTE2MjAw
       NjQ2WjBTMQswCQYDVQQGEwJVUzELMAkGA1UECAwCVkExETAPBgNVBAcMCFJpY2ht
       b25kMQ8wDQYDVQQKDAZGYW50b20xEzARBgNVBAMMCmZhbnRvbS5vcmcwTjAQBgcq
       hkjOPQIBBgUrgQQAIQM6AAQR6uUh2YHV6Aw9Mi+TTOWtdsiZsb0okM88O/oFy9R2
       7eroXszaEDXO7c+EIZe0yQRBXRXgUqssdDAKBggqhkjOPQQDAgNAADA9Ah0AwPCC
       KX+MIBcOiQAbC7Xr4P1p8YajGAygX0DhMAIcZugPSHA7lTqG4Ror8HdE9ddccqTi
       sUCXhakSPw==
       -----END CERTIFICATE-----"

    PrivKey priv := crypto.loadPem(secp224r1Priv.in) //EC algorithm inferred
    verifyKey(priv, "EC", "PKCS#8")
    Cert cert := crypto.loadPem(secp224r1X509.in)
    verifyEq(cert.certType, "X.509")

    //secp521r1
    secp521r1Priv :=
      "-----BEGIN EC PRIVATE KEY-----
       MIHcAgEBBEIB9JXwBOs9ihM4yZCkqx/ZkahI2O68nzlpi5ndvZ/364ga2zNIJLvP
       Ezd1d2T287CoeuRl0Z1/4nfJlh7sLHz9j6CgBwYFK4EEACOhgYkDgYYABAD6AS1F
       lipJNjqm/DN/ZAtkJLmBaQv4lhizdM/w4wykYmqxHQghyrNrH6t4J3+GR3ZJZvjs
       yuHzeLYJl2CF1+TjpAGfbYxX9C01KV6bhSNzaraUYMN5+vIYC1vR1oL/pkbwxjt2
       ipHHYQUp1NbAAB0VX8ULLSZaTlr0wZGARrONQSVxOw==
       -----END EC PRIVATE KEY-----"

    secp521r1X509 :=
      "-----BEGIN CERTIFICATE-----
       MIICHjCCAX8CCQCiUoxpzin4GzAKBggqhkjOPQQDBDBTMQswCQYDVQQGEwJVUzEL
       MAkGA1UECAwCVkExETAPBgNVBAcMCFJpY2htb25kMQ8wDQYDVQQKDAZGYW50b20x
       EzARBgNVBAMMCmZhbnRvbS5vcmcwHhcNMjQwOTE2MjA1OTU5WhcNMjUwOTE2MjA1
       OTU5WjBTMQswCQYDVQQGEwJVUzELMAkGA1UECAwCVkExETAPBgNVBAcMCFJpY2ht
       b25kMQ8wDQYDVQQKDAZGYW50b20xEzARBgNVBAMMCmZhbnRvbS5vcmcwgZswEAYH
       KoZIzj0CAQYFK4EEACMDgYYABAD6AS1FlipJNjqm/DN/ZAtkJLmBaQv4lhizdM/w
       4wykYmqxHQghyrNrH6t4J3+GR3ZJZvjsyuHzeLYJl2CF1+TjpAGfbYxX9C01KV6b
       hSNzaraUYMN5+vIYC1vR1oL/pkbwxjt2ipHHYQUp1NbAAB0VX8ULLSZaTlr0wZGA
       RrONQSVxOzAKBggqhkjOPQQDBAOBjAAwgYgCQgEPCrMYbywWCloBY0l4wbjaWx1V
       MK9OIrkxMupmB1WmXTIpoJxBD/WZ1zhXnMDdDSE9WLPik2wFMbPMYKWl6jE22gJC
       AcGzJbG9NBqExMxstzHXescXqsczDL9u/1y2NbvSDp8r9GfbrGNZE/uVm0UimNHs
       Z7MuTgBnRoYEE9gooRSoQx67
       -----END CERTIFICATE-----"

    priv = crypto.loadPem(secp521r1Priv.in)
    verifyKey(priv, "EC", "PKCS#8")
    cert = crypto.loadPem(secp521r1X509.in)
    verifyEq(cert.certType, "X.509")

    //sect233k1
    sect233k1Priv :=
      "-----BEGIN EC PRIVATE KEY-----
       MG0CAQEEHSzD7tGQFy7PXZnHRab2n0IiU5LFYYE95jc0PdMLoAcGBSuBBAAaoUAD
       PgAEAA4eD1AQxAx8Zu3ikInx1MAmPsTY2Vi7PnZwWU5hAMibYxvdrnIoYef8t5d4
       XLyECvWtAX5smaTxUYbj
       -----END EC PRIVATE KEY-----"

    priv = crypto.loadPem(sect233k1Priv.in)
    verifyKey(priv, "EC", "PKCS#8")

    //sect571r1
    sect571r1Priv :=
      "-----BEGIN EC PRIVATE KEY-----
       MIHuAgEBBEgBIjbdTxdfNIU0vhtLWFFkJxsPDsXDE1jM563JFvG8093FrhsgYp8u
       0L6KCIZKsXVWNZEMbyoiyiBPiTCa34s3mZFT7U+86i6gBwYFK4EEACehgZUDgZIA
       BAFL12AP9+JvGGm4hC6BaIucrQ4tU5B1nTwTHMRuaSUllLD6itX9ozFJzdNvV+C+
       ufNSFSMy7Kb6WiF9SVhPrgzPu6LtTsBVUgZcjhM8B5py7M5RTxyf/z1PFYUIoSzJ
       7ygLorTbyZf8hbxSHpcOmwGQDh7TpaaFb4aidHVMcszfDw1LvsGjXUrvh9/4c0Bv
       lQ==
       -----END EC PRIVATE KEY-----"

    priv = crypto.loadPem(sect571r1Priv.in)
    verifyKey(priv, "EC", "PKCS#8")
  }

  private Void verifyKey(Key key, Str alg, Str format)
  {
    verifyEq(key.algorithm, alg)
    verifyEq(key.format, format)
  }
}