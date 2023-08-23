//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Aug 2021  Matthew Giannini  Creation
//
package fan.inet;

import fan.sys.*;
import fan.crypto.KeyStore;
import fan.crypto.KeyStoreEntry;
import fan.crypto.PrivKeyEntry;
import fanx.interop.Interop;

import java.util.HashMap;
import java.util.Arrays;
import javax.net.ssl.*;
import java.security.KeyFactory;
import java.security.SecureRandom;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;

public class SocketConfigPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static SocketConfigPeer make(SocketConfig self)
  {
    return new SocketConfigPeer(self);
  }

  public SocketConfigPeer(SocketConfig self)
  {
    this.self = self;
  }

  private SocketConfig self;
  private SSLContext _sslContext;

//////////////////////////////////////////////////////////////////////////
// SSLContext
//////////////////////////////////////////////////////////////////////////

  SSLContext sslContext()
  {
    if (this._sslContext == null)
    {
      try
      {
        final String pwd = "inet::TlsSocketFactory";
        final HashMap<String,Object> options = new HashMap<String,Object>();
        options.put("password", pwd);
        final Map fanOpts = Interop.toFan(options);
        final KeyStore fanKeys  = self.keystore;
        final KeyStore fanTrust = self.truststore;

        // create key manager
        KeyManager[] keyManagers = null;
        if (fanKeys != null)
        {
          Buf buf = Buf.make();
          fanKeys.save(buf.out(), fanOpts);
          buf.flip();
          java.security.KeyStore javaKeys = java.security.KeyStore.getInstance(fanKeys.format());
          javaKeys.load(Interop.toJava(buf.in()), pwd.toCharArray());
          KeyManagerFactory kmf = KeyManagerFactory.getInstance("PKIX");
          kmf.init(javaKeys, pwd.toCharArray());
          keyManagers = kmf.getKeyManagers();
        }

        // create trust manager
        TrustManager[] trustManagers = null;
        if (fanTrust != null)
        {
          Buf buf = Buf.make();
          fanTrust.save(buf.out(), fanOpts);
          buf.flip();
          java.security.KeyStore javaKeys = java.security.KeyStore.getInstance(fanTrust.format());
          javaKeys.load(Interop.toJava(buf.in()), pwd.toCharArray());
          TrustManagerFactory tmf = TrustManagerFactory.getInstance("PKIX");
          tmf.init(javaKeys);
          trustManagers = tmf.getTrustManagers();
        }

        // create the SSLContext for this socket config
        String[] supported = SSLContext.getDefault().getSupportedSSLParameters().getProtocols();
        SSLContext sslContext;
        if (Arrays.asList(supported).contains("TLSv1.3")) { sslContext = SSLContext.getInstance("TLSv1.3"); }
        else { sslContext = SSLContext.getInstance("TLSv1.2"); }
        sslContext.init(keyManagers, trustManagers, new SecureRandom());
        this._sslContext = sslContext;
      }
      catch (Exception e) { throw IOErr.make(e); }
    }

    return this._sslContext;
  }
}
