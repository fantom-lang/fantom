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
import java.security.PrivateKey;
import java.security.interfaces.RSAPrivateKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import javax.crypto.Cipher;

final public class JPrivKey extends JKey implements fan.crypto.PrivKey
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  static JPrivKey decode(Buf der)
  {
    try
    {
      KeyFactory keyFactory = KeyFactory.getInstance("RSA");
      return new JPrivKey(keyFactory.generatePrivate(new PKCS8EncodedKeySpec(der.safeArray())));
    }
    catch (Exception e)
    {
      throw Err.make("Failed to decode private key:\n" + der.toHex());
    }
  }

  JPrivKey(PrivateKey privKey)
  {
    super(privKey);
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public final Type typeof() { return typeof; }
  private static final Type typeof = Type.find("cryptoJava::JPrivKey");

//////////////////////////////////////////////////////////////////////////
// AsymKey
//////////////////////////////////////////////////////////////////////////

  public long keySize()
  {
    if (javaKey instanceof RSAPrivateKey)
      return ((RSAPrivateKey)javaKey).getModulus().bitLength();
    throw Err.make("Not an RSA private key");
  }

//////////////////////////////////////////////////////////////////////////
// PrivKey
//////////////////////////////////////////////////////////////////////////

  public Buf sign(Buf data, final String digest)
  {
    try
    {
      Signature signer = toSignature(algorithm(), digest);
      signer.initSign(priv());
      signer.update(data.unsafeArray(), 0, data.sz());
      return new MemBuf(signer.sign());
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

  public Buf decrypt(Buf data) { return decrypt(data, "PKCS1Padding"); }
  public Buf decrypt(Buf data, final String padding)
  {
    try
    {
      Cipher cipher = Cipher.getInstance(algorithm()+"/ECB/"+padding);
      cipher.init(Cipher.DECRYPT_MODE, priv());
      return new MemBuf(cipher.doFinal(data.unsafeArray(), 0, data.sz()));
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Key
//////////////////////////////////////////////////////////////////////////

  public String pem()
  {
    Buf buf = Buf.make();
    PemWriter.make(buf.out()).write(PemLabel.privKey, this.encoded());
    return buf.flip().readAllStr();
  }

  public String toStr() { return pem(); }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  static Signature toSignature(final String keyAlg, final String digest)
    throws Exception
  {
    String algorithm = digest + "with" + keyAlg;

    // Parse signature digest that includes masking generation function
    //   e.g: SHA256withRSAandMGF1
    final int mgfIdx = digest.indexOf("and");
    if (mgfIdx > 0)
    {
      algorithm = digest.substring(0, mgfIdx) + "with"
                  + keyAlg + "and"
                  + digest.substring(mgfIdx+"and".length());
    }

    return Signature.getInstance(algorithm);
  }

  PrivateKey priv()
  {
    return (PrivateKey)this.javaKey;
  }
}
