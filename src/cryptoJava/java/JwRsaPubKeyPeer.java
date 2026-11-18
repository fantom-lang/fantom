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

      // RFC 7518 6.3.1: minimal unsigned octets (no leading zero sign byte)
      BigInteger n = rsaPub.getModulus();
      BigInteger e = rsaPub.getPublicExponent();

      Map jwk = Map.make(Sys.StrType, Sys.ObjType);
      jwk.set("n", toBase64Uri(n, (n.bitLength() + 7) / 8));
      jwk.set("e", toBase64Uri(e, (e.bitLength() + 7) / 8));
      return jwk;
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

  /** Encode unsigned big-endian value left-padded or trimmed to len bytes as base64url without padding */
  private static String toBase64Uri(BigInteger v, int len)
  {
    byte[] b = v.toByteArray();
    byte[] r = new byte[len];
    int n = Math.min(b.length, len);
    System.arraycopy(b, b.length - n, r, len - n, n);
    return new MemBuf(r).toBase64Uri();
  }
}

