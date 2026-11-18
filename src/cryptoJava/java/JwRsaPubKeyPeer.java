//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 2024  Ross Schwalm  Creation
//

package fan.cryptoJava;

import fan.sys.*;

import java.security.KeyFactory;
import java.security.spec.RSAPublicKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.security.interfaces.RSAPublicKey;
import java.math.BigInteger;

import java.security.spec.InvalidKeySpecException;
import java.security.NoSuchAlgorithmException;

public class JwRsaPubKeyPeer
{
  public static JwRsaPubKeyPeer make(JwRsaPubKey self) { return new JwRsaPubKeyPeer(); }

  public static Buf jwkToBuf(String modBase64, String expBase64)
  {
    try
    {
      byte[] modBytes = Buf.fromBase64(modBase64).safeArray();
      byte[] expBytes = Buf.fromBase64(expBase64).safeArray();
      RSAPublicKeySpec spec = new RSAPublicKeySpec(new BigInteger(1, modBytes), new BigInteger(1, expBytes));
      return new MemBuf(KeyFactory.getInstance("RSA").generatePublic(spec).getEncoded());
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

  public static Map bufToJwk(Buf key)
  {
    try
    {
      KeyFactory keyFactory = KeyFactory.getInstance("RSA");
      X509EncodedKeySpec keySpec = new X509EncodedKeySpec(key.unsafeArray());
      RSAPublicKey rsaPub = (RSAPublicKey) keyFactory.generatePublic(keySpec);

      byte[] modBytes = rsaPub.getModulus().toByteArray();
      byte[] expBytes = rsaPub.getPublicExponent().toByteArray();

      Map jwk = Map.make(Sys.StrType, Sys.ObjType);
      jwk.set("n", new MemBuf(modBytes).toBase64Uri());
      jwk.set("e", new MemBuf(expBytes).toBase64Uri());
      return jwk;
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }
}

