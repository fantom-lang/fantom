//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 2024  Ross Schwalm  Creation
//

package fan.cryptoJava;

import fan.sys.*;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

final public class JMacKey extends JKey implements fan.crypto.MacKey
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static JMacKey load(Buf key, String algorithm)
  {
    SecretKeySpec jKey;
    Mac jMac;
    try
    {
      jKey = new SecretKeySpec(key.safeArray(), algorithm);
      jMac = Mac.getInstance(algorithm);
      jMac.init(jKey);
    }
    catch (NoSuchAlgorithmException e)
    {
      throw Err.make("Unknown MAC algorithm: " + algorithm, e);
    }
    catch (InvalidKeyException e)
    {
      throw Err.make("Invalid key", e);
    }

    return new JMacKey(jKey, jMac);
  }

  JMacKey(SecretKeySpec key, Mac mac)
  {
    super(key);
    this.mac = mac;
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return typeof; }
  private static final Type typeof = Type.find("cryptoJava::JMacKey");

//////////////////////////////////////////////////////////////////////////
// Key
//////////////////////////////////////////////////////////////////////////

  public String algorithm()
  {
    return javaKey.getAlgorithm();
  }

  public String format()
  {
    return javaKey.getFormat();
  }

  public Buf encoded()
  {
    return new MemBuf(javaKey.getEncoded());
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final private Mac mac;

//////////////////////////////////////////////////////////////////////////
// Mac
//////////////////////////////////////////////////////////////////////////

  public long macSize() { return this.mac.getMacLength(); }

  public Buf digest()
  {
    final MemBuf buf = new MemBuf(this.mac.doFinal());
    this.reset();
    return buf;
  }

  public JMacKey update(Buf buf)
  {
    mac.update(buf.unsafeArray(), 0, buf.sz());
    return this;
  }

  public JMacKey updateAscii(String s)
  {
    for (int i=0; i<s.length(); ++i)
      mac.update((byte)s.charAt(i));
    return this;
  }

  public JMacKey updateByte(long i)
  {
    mac.update((byte)(i & 0xFF));
    return this;
  }

  public JMacKey updateI4(long i)
  {
    mac.update((byte)((i >> 24) & 0xFF));
    mac.update((byte)((i >> 16) & 0xFF));
    mac.update((byte)((i >> 8)  & 0xFF));
    mac.update((byte)((i >> 0)  & 0xFF));
    return this;
  }

  public JMacKey updateI8(long i)
  {
    mac.update((byte)((i >> 56) & 0xFF));
    mac.update((byte)((i >> 48) & 0xFF));
    mac.update((byte)((i >> 40) & 0xFF));
    mac.update((byte)((i >> 32) & 0xFF));
    mac.update((byte)((i >> 24) & 0xFF));
    mac.update((byte)((i >> 16) & 0xFF));
    mac.update((byte)((i >> 8)  & 0xFF));
    mac.update((byte)((i >> 0)  & 0xFF));
    return this;
  }

  public JMacKey reset() { this.mac.reset(); return this; }
}

