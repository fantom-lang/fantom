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
import java.util.Base64;

import java.security.spec.InvalidKeySpecException;
import java.security.NoSuchAlgorithmException;

public class JwRsaPubKeyPeer
{
  public static JwRsaPubKeyPeer make(JwRsaPubKey self) { return new JwRsaPubKeyPeer(); }

  public static Buf jwkToBuf(String modBase64, String expBase64) throws NoSuchAlgorithmException, InvalidKeySpecException
  {
    byte[] modBytes = Base64.getUrlDecoder().decode(modBase64);
    byte[] expBytes = Base64.getUrlDecoder().decode(expBase64);
    RSAPublicKeySpec spec = new RSAPublicKeySpec(new BigInteger(1, modBytes), new BigInteger(1, expBytes));
    return new MemBuf(KeyFactory.getInstance("RSA").generatePublic(spec).getEncoded());
  }

  public static Map bufToJwk(Buf key) throws NoSuchAlgorithmException, InvalidKeySpecException
  {
    KeyFactory keyFactory = KeyFactory.getInstance("RSA");
    X509EncodedKeySpec keySpec = new X509EncodedKeySpec(key.unsafeArray());
    RSAPublicKey rsaPub = (RSAPublicKey) keyFactory.generatePublic(keySpec);

    byte[] modBytes = rsaPub.getModulus().toByteArray();
    byte[] expBytes = rsaPub.getPublicExponent().toByteArray();

    Map jwk = new Map(Sys.StrType, Sys.ObjType);
    jwk.set("n", Base64.getUrlEncoder().encodeToString(modBytes));
    jwk.set("e", Base64.getUrlEncoder().encodeToString(expBytes));
    return jwk;
  }
}

