//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini   Creation
//

package fan.cryptoJava;

import fan.sys.*;

import java.security.KeyFactory;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;

public abstract class JKey extends FanObj implements fan.crypto.Key
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  JKey(java.security.Key javaKey)
  {
    this.javaKey = javaKey;
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return typeof; }
  private static final Type typeof = Type.find("cryptoJava::JKey");

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

  protected final java.security.Key javaKey;

//////////////////////////////////////////////////////////////////////////
// Decode
//////////////////////////////////////////////////////////////////////////

/*
  public static JKey fromStr(final String s)
  {
    String[] parts = s.split(":");
    if (parts.length != 3) throw ParseErr.make("Invalid key format: " + s);
    final String algorithm = parts[0];
    final String format    = parts[1];
    final String b64       = parts[2];
    if (format.isEmpty()) throw ArgErr.make("Key is missing format: " + s);
    if (b64.isEmpty())    throw ArgErr.make("Key is missing encoding: " + s);

    byte[] key = Buf.fromBase64(b64).safeArray();
    try
    {
      // TODO: support for Secret (symetric keys)
      KeyFactory keyFactory = KeyFactory.getInstance(algorithm);
      if ("X.509".equals(format))
      {
        return new JPubKey(keyFactory.generatePublic(new X509EncodedKeySpec(key)));
      }
      else if ("PKCS#8".equals(format))
      {
        return new JPrivKey(keyFactory.generatePrivate(new PKCS8EncodedKeySpec(key)));
      }
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
    throw Err.make("Unsupported encoding format: " + format);
  }
*/
}
