//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Feb 16  Matthew Giannini   Creation
//

**
** BufCryptoTest
**
@Js
class BufCryptoTest : AbstractBufTest
{

//////////////////////////////////////////////////////////////////////////
// Base64
//////////////////////////////////////////////////////////////////////////

  Void testBase64()
  {
    verifyBase64("", "");
    verifyBase64("Man", "TWFu");
    verifyBase64("@", "QA==")
    verifyBase64("[]", "W10=")
    verifyBase64("brian", "YnJpYW4=")
    verifyBase64("hey!", "aGV5IQ==")
    verifyBase64("123456", "MTIzNDU2")
    verifyBase64("SecretPassword", "U2VjcmV0UGFzc3dvcmQ=")
    verifyBase64("su?_d=1~~", "c3U/X2Q9MX5+")
    verifyBase64(
      "Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.",
      "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlzIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2YgdGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGludWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRoZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4=")

    buf := Buf.make
    300.times |Int i| { buf.write(i) }
    buf.flip
    verifyBufEq(Buf.fromBase64(buf.toBase64), buf)
  }

  Void verifyBase64(Str src, Str base64)
  {
    safe := base64.replace("=", "").replace("+", "-").replace("/", "_")

    verifyEq(makeMem.print(src).toBase64, base64)
    verifyEq(makeMem.print(src).toBase64Uri, safe)

    verifyBufEq(Buf.fromBase64(base64), Buf.make.print(src))
    verifyBufEq(Buf.fromBase64(safe), Buf.make.print(src))

    breaks := StrBuf.make
    base64.each |Int ch, Int i| { breaks.addChar(ch); if (i % 3 == 0) breaks.add("\uabcd\r\n") }
    verifyBufEq(Buf.fromBase64(breaks.toStr), ascii(src))
  }

//////////////////////////////////////////////////////////////////////////
// Digest
//////////////////////////////////////////////////////////////////////////

  Void testDigestMD5()
  {
    verifyDigest("fan", "MD5",
      "50bd8c21bfafa6e4e962f6a948b1ef92")
  }

  Void testDigestSHA1()
  {
    // standard test vectors
    verifyDigest("abc", "SHA-1",
     "a9993e364706816aba3e25717850c26c9cd0d89d")
    // standard - empty buf
    verifyDigest("", "SHA-1",
     "da39a3ee5e6b4b0d3255bfef95601890afd80709")
    // standard - 448 bits
    verifyDigest("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "SHA-1",
     "84983e441c3bd26ebaae4aa1f95129e5e54670f1")
    // standard - 896 bits
    verifyDigest("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "SHA-1",
     "a49b2446a02c645bf419f995b67091253a04a259")
    // 'a' 1,000,000 times - takes too long to run in js
    if ("js" != Env.cur.runtime)
    {
      verifyDigest(Buf().fill('a', 1_000_000).flip.readAllStr, "SHA-1",
        "34aa973cd4c4daa4f61eeb2bdbad27316534016f")
    }
  }

  Void testDigestSHA256()
  {
    // standard test vectors
    verifyDigest("abc", "SHA-256",
      "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    // standard - empty buf
    verifyDigest("", "SHA-256",
      "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    // standard - 448 bits
    verifyDigest("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "SHA-256",
      "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
    // standard - 896 bits
    verifyDigest("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "SHA-256",
     "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1")
    // 'a' 1,000,000 times - takes too long to run in js
    if ("js" != Env.cur.runtime)
    {
      verifyDigest(Buf().fill('a', 1_000_000).flip.readAllStr, "SHA-256",
        "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
    }
  }

  ** Message sizes around 64 byte block padding boundaries
  ** and HMAC with key larger than block size
  Void testDigestBoundaries()
  {
    verifyBoundary(0, "d41d8cd98f00b204e9800998ecf8427e", "da39a3ee5e6b4b0d3255bfef95601890afd80709", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "a885741107653e621bae86e72142c2dd", "93cf3b66c85469f193265f4c5867f51cb72c521a", "b33d74937c1e36b168994495205b2b77977aaa7b34129abe3000868328540dc9")
    verifyBoundary(55, "8c3eb046bcdb1f0ffe75fdbaf890cf13", "04bb34aef4880b625e6b1564a014abd25fc02bfe", "16fa57a0a3423a715d594516339f36189d6b5f93754a9714fef202616a9fabfe",
      "65174a59ee5d614e9eb317e7bef977ab", "9f72041caa3f6be95cf196c6353cdea336b78e59", "b9f7f23239c6ec59baa1b9e191be81d41f8694719c58fbe6e27b89b38983d863")
    verifyBoundary(56, "d5e0fa3122448ddd3d843a9c5ed9e839", "83b9fcb6d3e3b20f376ab989a1b6353bcc6c0f44", "c37b44e5f1b18554b36966f4f8e08bfbf3164c4b6c10374d12d89850892073c5",
      "e86af74686310a570b240d7d1a01c1e0", "aa036b89518cb1ff8888675b5e124e14a21f6dd1", "72cc5d3fa4a7f5cd7bdc0ad15165480d5b6e09c68d127e933e215d0ee398895e")
    verifyBoundary(63, "1dd0d6ddeb881b118518c2881555f34b", "ab15090e8dbe512f3733350f9623ab11f9b5165b", "bbba992d2c85af960fb2987a1fd05e0aa82a3db3c740dd8982a9e273b75e36a3",
      "b9921e5d27e2a4a495480b1dc3d75096", "faa233b96765171b6cad73c75357a7d97a536932", "edb50ae844c094649a6304918691666882818867ca666b2a870a39986cfd78c5")
    verifyBoundary(64, "7b412e00d38c31b0845a4f502d39d5e3", "54305ee7e4c7bc5a96afc6d1994fc52d9bcb665f", "66bd4633ed6f71c4ecfa4763bf7ba1c8ec7612de9aa6c0578a7b675207c71e0b",
      "27279a97fd602aaf13d0177c1d2b50d6", "fbe3f1bc3f686d58e889e47bbd5552eef61bdf2b", "4bbbb30870ddf22e5cf64d0283c3982803eb9f8b1ffd82037586297b8f7541e5")
    verifyBoundary(65, "ba03b626aceb7b09c86c2d544afe1dce", "5985422a25357371ebd2a7f6ecd7eebed43db42c", "9f7dc47107b750a1f3d35db5d9547f24ef40da5b731b9540d4f43710a154f6c9",
      "92b2fe1d5e44d5ac882f9626f9909d6f", "32d5108a3bb25c71db300399e50618e099eab877", "fc37b66abde54eb757d2e67375194e2270bd227bb9b3258f2406131724b3f427")
    verifyBoundary(119, "dac58560b386c3d5b29ebbdec5197e10", "6839d6c27f22ed884ac43ae6bd3bfcee9e04b938", "a3ed307b730fa77c07531300c6e4a282330011d4d4caf6bb7b63ae05950f4b66",
      "b8b8639d0df2fbeb7f531dc873f5e77c", "81f6271887a07a83575ddfd2b7babf93a535286b", "86dae5fd3397e1409a8f521cf01d9be1529bd664de260b355837e1de3606c2a3")
    verifyBoundary(120, "6818845a0494b5fade3155f6a8e47b15", "8c40517a14ab8b78fd4b8958f4e31254a34c3fb0", "8e3b15d9fea7472655aa069620b7f8c2e55ee1499f763200a7515fe826e99d20",
      "71cbf72898cffd1128c119fe63ae7888", "82a57e2a1aece1fffb596b86e42380a207ae8507", "e10431d18c6795c420835e88b6389bc2498c382dcaefa789b38a8ac6dc7d96ee")
    verifyBoundary(1000, "7874d3c13d4ed33f057def947e0621ef", "f50d11c8ae2b20fe2598e99a6a2cb859e302615c", "095ecb62e30793ab4b954cd6a0586d0cc91f7ea5b1332694d8da780e98676d78",
      "8f81a859c35063c8c7ab902a01a11f7c", "c7cbce1ac70232752f402c401a1b3b0b49b38c3b", "e723d04aadfdaff88d2d6da93c6c9996c711af6cfb946ecc91a30800a9d0ed20")
  }

  Void verifyBoundary(Int size, Str md5, Str sha1, Str sha256, Str hmacMd5, Str hmacSha1, Str hmacSha256)
  {
    buf := Buf(); size.times |i| { buf.write(i * 7 + 1) }
    key := Buf(); 100.times |i| { key.write(i * 3) }
    verifyEq(buf.toDigest("MD5").toHex, md5)
    verifyEq(buf.toDigest("SHA-1").toHex, sha1)
    verifyEq(buf.toDigest("SHA-256").toHex, sha256)
    verifyEq(buf.hmac("MD5", key).toHex, hmacMd5)
    verifyEq(buf.hmac("SHA-1", key).toHex, hmacSha1)
    verifyEq(buf.hmac("SHA-256", key).toHex, hmacSha256)
  }

  Void testBadDigest()
  {
    verifyErr(ArgErr#) { ascii("foo").toDigest("Foo Digest!") }
  }

  Void verifyDigest(Str text, Str algorithm, Str digest)
  {
    verifyEq(makeMem.print(text).toDigest(algorithm).toHex, digest)
    verifyEq(makeFile.print(text).toDigest(algorithm).toHex, digest)
  }

//////////////////////////////////////////////////////////////////////////
// HMAC
//////////////////////////////////////////////////////////////////////////

  Void testHmacMD5()
  {
    // tests from RFC 2202 http://www.faqs.org/rfcs/rfc2202.html
    verifyHmac("Hi There".toBuf,
               Buf().fill(0x0b, 16), "MD5",
               "9294727a3638bb1c13f48ef8158bfc9d")

    verifyHmac("what do ya want for nothing?".toBuf,
               "Jefe".toBuf, "MD5",
               "750c783e6ab0b503eaa86e310a5db738")

    verifyHmac(Buf().fill(0xdd, 50),
               Buf().fill(0xaa, 16), "MD5",
               "56be34521d144c88dbb8c733f0e8b3f6")

    verifyHmac(Buf().fill(0xcd, 50),
               Buf.fromHex("0102030405060708090a0b0c0d0e0f10111213141516171819"), "MD5",
               "697eaf0aca3a3aea3a75164746ffaa79")

    verifyHmac("Test With Truncation".toBuf,
               Buf().fill(0x0c, 16), "MD5",
               "56461ef2342edc00f9bab995690efd4c")

    verifyHmac("Test Using Larger Than Block-Size Key - Hash Key First".toBuf,
               Buf().fill(0xaa, 80), "MD5",
               "6b1ab7fe4bd7bf8f0b62e6ce61b9d0cd")

    verifyHmac("Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data".toBuf,
               Buf().fill(0xaa, 80), "MD5",
               "6f630fad67cda0ee1fb1f562db3aa53e")
  }

  Void testHmacSHA1()
  {
    // tests from RFC 2202 http://www.faqs.org/rfcs/rfc2202.html
    verifyHmac("Hi There".toBuf,
               Buf().fill(0x0b, 20), "SHA1",
               "b617318655057264e28bc0b6fb378c8ef146be00")

    verifyHmac("what do ya want for nothing?".toBuf,
               "Jefe".toBuf, "SHA1",
               "effcdf6ae5eb2fa2d27416d5f184df9c259a7c79")

    verifyHmac(Buf().fill(0xdd, 50),
               Buf().fill(0xaa, 20), "SHA1",
               "125d7342b9ac11cd91a39af48aa17b4f63f175d3")

    verifyHmac(Buf().fill(0xcd, 50),
               Buf.fromHex("0102030405060708090a0b0c0d0e0f10111213141516171819"), "SHA1",
               "4c9007f4026250c6bc8414f9bf50c86c2d7235da")

    verifyHmac("Test With Truncation".toBuf,
               Buf().fill(0x0c, 20), "SHA1",
               "4c1a03424b55e07fe7f27be1d58bb9324a9a5a04")

    verifyHmac("Test Using Larger Than Block-Size Key - Hash Key First".toBuf,
               Buf().fill(0xaa, 80), "SHA1",
               "aa4ae5e15272d00e95705637ce8a3b55ed402112")

    verifyHmac("Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data".toBuf,
               Buf().fill(0xaa, 80), "SHA1",
               "e8e99d0f45237d786d6bbaa7965c7808bbff1a91")
  }

  Void testHmacSHA256()
  {
    // tests from https://tools.ietf.org/html/rfc4868
    verifyHmac("Hi There".toBuf,
               Buf().fill(0x0b, 20), "SHA-256",
               "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7")

    verifyHmac("what do ya want for nothing?".toBuf,
               "Jefe".toBuf, "SHA-256",
               "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843")

    verifyHmac(Buf().fill(0xdd, 50),
               Buf().fill(0xaa, 20), "SHA-256",
               "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe")

    verifyHmac(Buf().fill(0xcd, 50),
               Buf.fromHex("0102030405060708090a0b0c0d0e0f10111213141516171819"), "SHA-256",
               "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b")

    verifyHmac("Test Using Larger Than Block-Size Key - Hash Key First".toBuf,
               Buf().fill(0xaa, 131), "SHA-256",
               "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54")

    verifyHmac("This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.".toBuf,
               Buf().fill(0xaa, 131), "SHA-256",
               "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2")
  }

  Void testHmacSHA384()
  {
    // tests from https://tools.ietf.org/html/rfc4868
    verifyHmac("Hi There".toBuf,
               Buf().fill(0x0b, 20), "SHA-384",
               "afd03944d84895626b0825f4ab46907f15f9dadbe4101ec682aa034c7cebc59cfaea9ea9076ede7f4af152e8b2fa9cb6")

    verifyHmac("what do ya want for nothing?".toBuf,
               "Jefe".toBuf, "SHA-384",
               "af45d2e376484031617f78d2b58a6b1b9c7ef464f5a01b47e42ec3736322445e8e2240ca5e69e2c78b3239ecfab21649")

    verifyHmac(Buf().fill(0xdd, 50),
               Buf().fill(0xaa, 20), "SHA-384",
               "88062608d3e6ad8a0aa2ace014c8a86f0aa635d947ac9febe83ef4e55966144b2a5ab39dc13814b94e3ab6e101a34f27")

    verifyHmac(Buf().fill(0xcd, 50),
               Buf.fromHex("0102030405060708090a0b0c0d0e0f10111213141516171819"), "SHA-384",
               "3e8a69b7783c25851933ab6290af6ca77a9981480850009cc5577c6e1f573b4e6801dd23c4a7d679ccf8a386c674cffb")

    verifyHmac("Test Using Larger Than Block-Size Key - Hash Key First".toBuf,
               Buf().fill(0xaa, 131), "SHA-384",
               "4ece084485813e9088d2c63a041bc5b44f9ef1012a2b588f3cd11f05033ac4c60c2ef6ab4030fe8296248df163f44952")

    verifyHmac("This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.".toBuf,
               Buf().fill(0xaa, 131), "SHA-384",
               "6617178e941f020d351e2f254e8fd32c602420feb0b8fb9adccebb82461e99c5a678cc31e799176d3860e6110c46523e")
  }

  Void testHmacSHA512()
  {
    // tests from https://tools.ietf.org/html/rfc4868
    verifyHmac("Hi There".toBuf,
               Buf().fill(0x0b, 20), "SHA-512",
               "87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cdedaa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854")

    verifyHmac("what do ya want for nothing?".toBuf,
               "Jefe".toBuf, "SHA-512",
               "164b7a7bfcf819e2e395fbe73b56e0a387bd64222e831fd610270cd7ea2505549758bf75c05a994a6d034f65f8f0e6fdcaeab1a34d4a6b4b636e070a38bce737")

    verifyHmac(Buf().fill(0xdd, 50),
               Buf().fill(0xaa, 20), "SHA-512",
               "fa73b0089d56a284efb0f0756c890be9b1b5dbdd8ee81a3655f83e33b2279d39bf3e848279a722c806b485a47e67c807b946a337bee8942674278859e13292fb")

    verifyHmac(Buf().fill(0xcd, 50),
               Buf.fromHex("0102030405060708090a0b0c0d0e0f10111213141516171819"), "SHA-512",
               "b0ba465637458c6990e5a8c5f61d4af7e576d97ff94b872de76f8050361ee3dba91ca5c11aa25eb4d679275cc5788063a5f19741120c4f2de2adebeb10a298dd")

    verifyHmac("Test Using Larger Than Block-Size Key - Hash Key First".toBuf,
               Buf().fill(0xaa, 131), "SHA-512",
               "80b24263c7c1a3ebb71493c1dd7be8b49b46d1f41b4aeec1121b013783f8f3526b56d037e05f2598bd0fd2215d6a1e5295e64f73f63f0aec8b915a985d786598")

    verifyHmac("This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.".toBuf,
               Buf().fill(0xaa, 131), "SHA-512",
               "e37b6a775dc87dbaa4dfa9f96e5e3ffddebd71f8867289865df5a32d20cdc944b6022cac3c4982b10d5eeb55c3e4de15134676fb6de0446065c97440fa8c6a58")
  }

  Void testBadHmac()
  {
    verifyErr(ArgErr#) { "Hi There".toBuf.hmac("SHA-X", "password".toBuf) }
  }

  Void verifyHmac(Buf data, Buf key, Str algorithm, Str expected)
  {
    verifyEq(data.hmac(algorithm, key).toHex, expected)
  }

//////////////////////////////////////////////////////////////////////////
// PBK
//////////////////////////////////////////////////////////////////////////

  Void testPBKDF2WithHmacSHA1()
  {
    // tests from RFC 6070
    verifyPbk("PBKDF2WithHmacSHA1", "password", "salt".toBuf, 1, 20,
      "0c 60 c8 0f 96 1f 0e 71 f3 a9 b5 24 af 60 12 06 2f e0 37 a6")
    verifyPbk("PBKDF2WithHmacSHA1", "password", "salt".toBuf, 4096, 20,
      "4b 00 79 01 b7 65 48 9a be ad 49 d9 26 f7 21 d0 65 a4 29 c1")
    verifyPbk("PBKDF2WithHmacSHA1", "passwordPASSWORDpassword", "saltSALTsaltSALTsaltSALTsaltSALTsalt".toBuf, 4096, 25,
      "3d 2e ec 4f e4 1c 84 9b 80 c8 d8 36 62 c0 e4 4a 8b 29 1a 96 4c f2 f0 70 38")
  }

  Void testPBKDF2WithHmacSHA256()
  {
    // http://stackoverflow.com/questions/5130513/pbkdf2-hmac-sha2-test-vectors/5136918#5136918
    verifyPbk("PBKDF2WithHmacSHA256", "password", "salt".toBuf, 1, 32,
      "12 0f b6 cf fc f8 b3 2c 43 e7 22 52 56 c4 f8 37 a8 65 48 c9 2c cc 35 48 08 05 98 7c b7 0b e1 7b")
    verifyPbk("PBKDF2WithHmacSHA256", "password", "salt".toBuf, 4096, 32,
      "c5 e4 78 d5 92 88 c8 41 aa 53 0d b6 84 5c 4c 8d 96 28 93 a0 01 ce 4e 11 a4 96 38 73 aa 98 13 4a")
    verifyPbk("PBKDF2WithHmacSHA256", "passwordPASSWORDpassword", "saltSALTsaltSALTsaltSALTsaltSALTsalt".toBuf, 4096, 40,
      "34 8c 89 db cb d3 2b 2f 32 d8 14 b8 11 6e 84 cf 2b 17 34 7e bc 18 00 18 1c 4e 2a 1f b8 dd 53 e1 c6 35 51 8c 7d ac 47 e9")
    verifyPbk("PBKDF2WithHmacSHA256", "pencil", Buf.fromBase64("W22ZaJ0SNY7soEsUEjb6gQ=="), 4096, 32,
      "c4a49510323ab4f952cac1fa99441939e78ea74d6be81ddf7096e87513dc615d")
  }

  Void verifyPbk(Str algorithm, Str pass, Buf salt, Int iterations, Int keyLen, Str expected)
  {
    expected = expected.replace(" ", "")
    actual := Buf.pbk(algorithm, pass, salt, iterations, keyLen).toHex
    /*
    echo(">>>> $algorithm $pass $iterations $keyLen")
    echo("     $actual")
    echo("     $expected")
    */
    verifyEq(actual, expected)
  }
}
