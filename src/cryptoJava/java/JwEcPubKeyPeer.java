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
import java.security.NoSuchAlgorithmException;
import java.security.spec.ECPublicKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.security.spec.ECPoint;
import java.security.spec.ECParameterSpec;
import java.security.spec.EllipticCurve;
import java.security.spec.ECFieldFp;
import java.security.spec.InvalidKeySpecException;
import java.security.interfaces.ECPublicKey;

import java.math.BigInteger;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

/*
 *
 *  This source also used for referencing parameters: https://safecurves.cr.yp.to/base.html
 */
public class JwEcPubKeyPeer
{
  private static final java.util.Map<String, ECParameterSpec> curves = new HashMap<String, ECParameterSpec>();
  private static final java.util.Map<EllipticCurve, String> curveNames = new HashMap<EllipticCurve, String>();

  private static int COFACTOR = 1;

  //
  // NIST P-256
  // https://neuromancer.sk/std/nist/P-256
  //
  private static String NIST_P256_JWK_NAME = "P-256";
  private static String NIST_P256_P = "115792089210356248762697446949407573530086143415290314195533631308867097853951";
  private static String NIST_P256_A = "115792089210356248762697446949407573530086143415290314195533631308867097853948";
  private static String NIST_P256_B = "41058363725152142129326129780047268409114441015993725554835256314039467401291";
  private static String NIST_P256_X = "48439561293906451759052585252797914202762949526041747995844080717082404635286";
  private static String NIST_P256_Y = "36134250956749795798585127919587881956611106672985015071877198253568414405109";
  private static String NIST_P256_N = "115792089210356248762697446949407573529996955224135760342422259061068512044369";

  private static final ECParameterSpec NIST_P256 = new ECParameterSpec(
    new EllipticCurve(new ECFieldFp(new BigInteger(NIST_P256_P)), new BigInteger(NIST_P256_A), new BigInteger(NIST_P256_B)),
    new ECPoint(new BigInteger(NIST_P256_X),new BigInteger(NIST_P256_Y)),
    new BigInteger(NIST_P256_N),
    COFACTOR);

  //
  // NIST P-384
  // https://neuromancer.sk/std/nist/P-384
  //
  private static String NIST_P384_JWK_NAME = "P-384";
  private static String NIST_P384_P = "394020061963944792122790401001436138050797392704654466679482934042457217714968" +
                                      "70329047266088258938001861606973112319";
  private static String NIST_P384_A = "394020061963944792122790401001436138050797392704654466679482934042457217714968" +
                                      "70329047266088258938001861606973112316";
  private static String NIST_P384_B = "275801935599597058778490118403890480930569058563615685214287073019886892413098" +
                                      "60865136260764883745107765439761230575";
  private static String NIST_P384_X = "262470350957996892686231567445669818918529234911092133878156159009255188547380" +
                                      "50089022388053975719786650872476732087";
  private static String NIST_P384_Y = "832571096148902998554675128952010817928785304886131559470920590248050319988441" +
                                      "9224438643760392947333078086511627871";
  private static String NIST_P384_N = "394020061963944792122790401001436138050797392704654466679469052796276593991132" +
                                      "63569398956308152294913554433653942643";

  private static final ECParameterSpec NIST_P384 = new ECParameterSpec(
    new EllipticCurve(new ECFieldFp(new BigInteger(NIST_P384_P)), new BigInteger(NIST_P384_A), new BigInteger(NIST_P384_B)),
    new ECPoint( new BigInteger(NIST_P384_X),new BigInteger(NIST_P384_Y)),
    new BigInteger(NIST_P384_N),
    COFACTOR);

  //
  // NIST P-521
  // https://neuromancer.sk/std/nist/P-521
  //
  private static String NIST_P521_JWK_NAME = "P-521";
  private static String NIST_P521_P = "686479766013060971498190079908139321726943530014330540939446345918554318339765" +
                                      "6052122559640661454554977296311391480858037121987999716643812574028291115057151";
  private static String NIST_P521_A = "686479766013060971498190079908139321726943530014330540939446345918554318339765" +
                                      "6052122559640661454554977296311391480858037121987999716643812574028291115057148";
  private static String NIST_P521_B = "109384903807373427451111239076680556993620759895168374899458639449595311615073" +
                                      "5016013708737573759623248592132296706313309438452531591012912142327488478985984";
  private static String NIST_P521_X = "266174080205021706322876871672336096072985916875697314770667136841880294499642" +
                                      "7808491545080627771902352094241225065558662157113545570916814161637315895999846";
  private static String NIST_P521_Y = "375718002577002046354550722449118360359445513476976248669456777961554447744055" +
                                      "6316691234405012945539562144444537289428522585666729196580810124344277578376784";
  private static String NIST_P521_N = "686479766013060971498190079908139321726943530014330540939446345918554318339765" +
                                      "5394245057746333217197532963996371363321113864768612440380340372808892707005449";

  private static final ECParameterSpec NIST_P521 = new ECParameterSpec(
    new EllipticCurve(new ECFieldFp(new BigInteger(NIST_P521_P)), new BigInteger(NIST_P521_A), new BigInteger(NIST_P521_B)),
    new ECPoint( new BigInteger(NIST_P521_X),new BigInteger(NIST_P521_Y)),
    new BigInteger(NIST_P521_N),
    COFACTOR);

  static
  {
    curves.put(NIST_P256_JWK_NAME, NIST_P256);
    curveNames.put(NIST_P256.getCurve(), NIST_P256_JWK_NAME);
    curves.put(NIST_P384_JWK_NAME, NIST_P384);
    curveNames.put(NIST_P384.getCurve(), NIST_P384_JWK_NAME);
    curves.put(NIST_P521_JWK_NAME, NIST_P521);
    curveNames.put(NIST_P521.getCurve(), NIST_P521_JWK_NAME);
  }

  public static JwEcPubKeyPeer make(JwEcPubKey self) { return new JwEcPubKeyPeer(); }

  public static Buf jwkToBuf(String xBase64, String yBase64, String curve) throws NoSuchAlgorithmException, InvalidKeySpecException
  {
    byte[] xBytes = Base64.getUrlDecoder().decode(xBase64);
    byte[] yBytes = Base64.getUrlDecoder().decode(yBase64);

    ECParameterSpec spec = getSpec(curve);
    if (spec == null)
    {
      throw new InvalidKeySpecException("Unsupported value of (crv) Parameter: " + curve);
    }

    ECPoint ecPt = new ECPoint(new BigInteger(1, xBytes), new BigInteger(1, yBytes));
    ECPublicKeySpec ecPublicKeySpec = new ECPublicKeySpec(ecPt, spec);

    return new MemBuf(KeyFactory.getInstance("EC").generatePublic(ecPublicKeySpec).getEncoded());
  }

  public static fan.sys.Map bufToJwk(Buf key) throws NoSuchAlgorithmException, InvalidKeySpecException
  {
    KeyFactory keyFactory = KeyFactory.getInstance("EC");
    X509EncodedKeySpec keySpec = new X509EncodedKeySpec(key.unsafeArray());
    ECPublicKey ecPub = (ECPublicKey) keyFactory.generatePublic(keySpec);

    ECPoint pt = ecPub.getW();
    ECParameterSpec spec = ecPub.getParams();
    EllipticCurve curve = spec.getCurve();

    BigInteger x = pt.getAffineX();
    byte[] xBytes = x.toByteArray();
    BigInteger y = pt.getAffineY();
    byte[] yBytes = y.toByteArray();

    fan.sys.Map jwk = new fan.sys.Map(Sys.StrType, Sys.ObjType);
    jwk.set("x", Base64.getUrlEncoder().encodeToString(xBytes));
    jwk.set("y", Base64.getUrlEncoder().encodeToString(yBytes));
    jwk.set("crv", getName(curve));

    return jwk;
  }

  private static ECParameterSpec getSpec(String curve)
  {
    return curves.get(curve);
  }

  private static String getName(EllipticCurve curve)
  {
    return curveNames.get(curve);
  }
}

