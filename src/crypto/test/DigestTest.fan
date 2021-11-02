//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

class DigestTest : CryptoTest
{
  Void testSha256()
  {
    md := crypto.digest("SHA-256")
    verifyEq("SHA-256", md.algorithm)
    verifyEq(32, md.digestSize)
    verifyDigest(md,
      "",
      "e3b0c442 98fc1c14 9afbf4c8 996fb924 27ae41e4 649b934c a495991b 7852b855")
    verifyDigest(md,
      "abc",
      "ba7816bf 8f01cfea 414140de 5dae2223 b00361a3 96177a9c b410ff61 f20015ad")
    verifyDigest(md,
      "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
      "248d6a61 d20638b8 e5c02693 0c3e6039 a33ce459 64ff2167 f6ecedd4 19db06c1")
    verifyDigest(md,
      "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
      "cf5b16a7 78af8380 036ce59e 7b049237 0b249b11 e8f07a51 afac4503 7afee9d1")
    buf := StrBuf()
    1_000_000.times { buf.addChar('a') }
    verifyDigest(md,
      buf.toStr(),
      "cdc76e5c 9914fb92 81a1c7e2 84d73e67 f1809a48 a497200e 046d39cc c7112cd0")
  }

  private Void verifyDigest(Digest md, Str msg, Str expect)
  {
    expectHash := Buf.fromHex(expect.replace(" ", ""))
    buf := msg.toBuf

    // first do single update with all bytes
    verify(md.update(buf).digest.bytesEqual(expectHash))

    // update the digest one byte at a time
    byte := Buf()
    buf.size.times |i| { md.update(byte.clear.write(buf[i])) }
    verify(md.digest.bytesEqual(expectHash))
  }

  Void testUpdates()
  {
    a := Crypto.cur.digest("SHA-1")
    b := Buf()

    a.update("foo".toBuf); b.writeBuf("foo".toBuf)
    a.updateByte(0x46); b.write(0x46)
    a.updateByte(0xFA); b.write(0xFA)
    a.updateI4(0x1234_5678); b.writeI4(0x1234_5678);
    a.updateI4(0xabcd_ef87); b.writeI4(0xabcd_ef87);
    a.updateI8(0xabcd_0123_fedc); b.writeI8(0xabcd_0123_fedc);
    a.updateAscii("hello"); b.print("hello")

    ad := a.digest.toHex
    bd := b.toDigest("SHA-1").toHex
    verifyEq(ad, bd)
  }
}