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

  public JDigest reset() { this.md.reset(); return this; }
}