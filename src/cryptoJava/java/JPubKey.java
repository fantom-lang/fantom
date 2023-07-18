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
import java.security.PublicKey;
import java.security.interfaces.RSAPublicKey;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import javax.crypto.Cipher;

final public class JPubKey extends JKey implements fan.crypto.PubKey
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static JPubKey decode(Buf der)
  {
    try
    {
      KeyFactory keyFactory = KeyFactory.getInstance("RSA");
      return new JPubKey(keyFactory.generatePublic(new X509EncodedKeySpec(der.safeArray())));
    }
    catch (Exception e)
    {
      throw Err.make("Failed to decode public key:\n" + der.toHex());
    }
  }


  JPubKey(PublicKey pubKey)
  {
    super(pubKey);
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
    if (javaKey instanceof RSAPublicKey)
      return ((RSAPublicKey)javaKey).getModulus().bitLength();
    throw Err.make("Not an RSA public key");
  }

//////////////////////////////////////////////////////////////////////////
// PubKey
//////////////////////////////////////////////////////////////////////////

  public boolean verify(Buf data, final String digest, Buf sig)
  {
    try
    {
      Signature verifier = JPrivKey.toSignature(algorithm(), digest);
      verifier.initVerify(pub());
      verifier.update(data.unsafeArray(), 0, data.sz());
      return verifier.verify(sig.unsafeArray(), 0, sig.sz());
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

  public Buf encrypt(Buf data) { return encrypt(data, "PKCS1Padding"); }
  public Buf encrypt(Buf data, final String padding)
  {
    try
    {
      Cipher cipher = Cipher.getInstance(algorithm()+"/ECB/"+padding);
      cipher.init(Cipher.ENCRYPT_MODE, pub());
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
    PemWriter.make(buf.out()).write(PemLabel.publicKey, this.encoded());
    return buf.flip().readAllStr();
  }

  public String toStr() { return pem(); }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  PublicKey pub()
  {
    return (PublicKey)this.javaKey;
  }
}
