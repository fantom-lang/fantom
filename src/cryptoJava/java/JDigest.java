//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Aug 2021 Matthew Giannini   Creation
//

package fan.cryptoJava;

import fan.sys.*;
import fanx.interop.Interop;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * JDigest
 */
final public class JDigest extends FanObj implements fan.crypto.Digest
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static JDigest make(String algorithm)
  {
    try
    {
      MessageDigest md = MessageDigest.getInstance(algorithm);
      return new JDigest(md);
    }
    catch (NoSuchAlgorithmException e)
    {
      throw ArgErr.make("Unsupported digest: " + algorithm, e);
    }
  }

  private JDigest(MessageDigest md)
  {
    this.md = md;
  }

  final private MessageDigest md;

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public final Type typeof() { return typeof; }
  public static final Type typeof = Type.find("cryptoJava::JDigest");

//////////////////////////////////////////////////////////////////////////
// Digest
//////////////////////////////////////////////////////////////////////////

  public String algorithm() { return this.md.getAlgorithm(); }

  public long digestSize() { return this.md.getDigestLength(); }

  public Buf digest()
  {
    final MemBuf buf = new MemBuf(this.md.digest());
    this.reset();
    return buf;
  }

  public JDigest update(Buf buf)
  {
    md.update(buf.unsafeArray(), 0, buf.sz());
    return this;
  }

  public JDigest updateAscii(String s)
  {
    for (int i=0; i<s.length(); ++i)
      md.update((byte)s.charAt(i));
    return this;
  }

  public JDigest updateByte(long i)
  {
    md.update((byte)(i & 0xFF));
    return this;
  }

  public JDigest updateI4(long i)
  {
    md.update((byte)((i >> 24) & 0xFF));
    md.update((byte)((i >> 16) & 0xFF));
    md.update((byte)((i >> 8)  & 0xFF));
    md.update((byte)((i >> 0)  & 0xFF));
    return this;
  }

  public JDigest updateI8(long i)
  {
    md.update((byte)((i >> 56) & 0xFF));
    md.update((byte)((i >> 48) & 0xFF));
    md.update((byte)((i >> 40) & 0xFF));
    md.update((byte)((i >> 32) & 0xFF));
    md.update((byte)((i >> 24) & 0xFF));
    md.update((byte)((i >> 16) & 0xFF));
    md.update((byte)((i >> 8)  & 0xFF));
    md.update((byte)((i >> 0)  & 0xFF));
    return this;
  }

  public JDigest reset() { this.md.reset(); return this; }
}