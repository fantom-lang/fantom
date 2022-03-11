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

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.Calendar;

import java.io.InputStream;
import java.io.ByteArrayInputStream;

import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;

final public class X509 extends FanObj implements fan.crypto.Cert
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static List load(InStream in)
  {
    InputStream is = null;
    try
    {
      is = Interop.toJava(in);
      return List.make(typeof, load(is).toArray());
    }
    catch (Exception e)           { throw Err.make(e); }
    finally
    {
      if (is != null) try { is.close(); } catch (Exception e) { }
    }
  }

  private static java.util.List<X509> load(InputStream in)
  {
    try
    {
      ArrayList<X509> arr = new ArrayList<X509>();
      CertificateFactory cf = CertificateFactory.getInstance("X.509");
      Collection c = cf.generateCertificates(in);
      Iterator iter = c.iterator();
      while (iter.hasNext())
      {
        X509Certificate cert = (X509Certificate)iter.next();
        arr.add(new X509(cert));
      }
      return arr;
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

  public static List loadCertsForUri(Uri uri)
  {
    return new CertChainLoader(uri).load();
  }

/*
  public static X509 fromStr(final String s)
  {
    String[] parts = s.split(":");
    final String certType = parts[0];
    final String b64      = parts[1];
    if (!"X.509".equals(certType))
      throw ArgErr.make("Can only decode X.509 certificates: " + certType);
    try
    {
      byte[] encoded = Buf.fromBase64(b64).safeArray();
      ByteArrayInputStream bis = new ByteArrayInputStream(encoded);
      return load(bis).get(0);
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }
*/

  public X509(X509Certificate cert)
  {
    this.cert = cert;
  }

  X509Certificate cert;

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  public final Type typeof() { return typeof; }
  static final Type typeof = Type.find("cryptoJava::X509");

//////////////////////////////////////////////////////////////////////////
// Cert
//////////////////////////////////////////////////////////////////////////

  public String subject()
  {
    return cert.getSubjectX500Principal().toString();
  }

  public String issuer()
  {
    return cert.getIssuerX500Principal().toString();
  }

  public String certType()
  {
    return cert.getType();
  }

  public Buf encoded()
  {
    try
    {
      return new MemBuf(cert.getEncoded());
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

  public fan.crypto.PubKey pub()
  {
    return new JPubKey(cert.getPublicKey());
  }

  public Buf serialNum()
  {
    byte[] bytes = cert.getSerialNumber().toByteArray();
    return new MemBuf(bytes);
  }

  public Date notBefore()
  {
    return toDate(cert.getNotBefore());
  }

  public Date notAfter()
  {
    return toDate(cert.getNotAfter());
  }

  private static Date toDate(java.util.Date jdate)
  {
    Calendar c = Calendar.getInstance();
    c.setTime(jdate);
    return Date.make(c.get(Calendar.YEAR), Month.fromOrdinal(c.get(Calendar.MONTH)), c.get(Calendar.DAY_OF_MONTH));
  }

  public String pem()
  {
    Buf buf = Buf.make();
    PemWriter.make(buf.out()).write(PemLabel.cert, this.encoded());
    return buf.flip().readAllStr();
  }

  public String toStr() { return pem(); }
}
