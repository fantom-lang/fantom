//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Oct 2026  Matthew Giannini  Creation
//

using concurrent
using crypto

**
** Test TLS server host name verification and client authentication
**
class TlsTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  override Void setup()
  {
    // CA signed server cert for localhost only (no IP SAN)
    caKeys  = crypto.genKeyPair("RSA", 2048)
    caCert  = sign(caKeys, "CN=Test CA", San[,], null, null, true)
    srvKeys = crypto.genKeyPair("RSA", 2048)
    srvCert = sign(srvKeys, "CN=localhost", [San.dnsName("localhost")], caKeys.priv, caCert)

    // self-signed server cert for localhost only (no IP SAN)
    selfKeys = crypto.genKeyPair("RSA", 2048)
    selfCert = sign(selfKeys, "CN=localhost", [San.dnsName("localhost")])
  }

  Crypto crypto := Crypto.cur
  KeyPair? caKeys
  Cert? caCert
  KeyPair? srvKeys
  Cert? srvCert
  KeyPair? selfKeys
  Cert? selfCert

//////////////////////////////////////////////////////////////////////////
// Tests
//////////////////////////////////////////////////////////////////////////

  Void testCaSigned()
  {
    keys  := keyStore(srvKeys, [srvCert, caCert])
    trust := trustStore(caCert)

    // name in the cert
    verifyOk(keys, trust, "localhost")

    // IP address not in the cert
    verifyHostErr(keys, trust, "127.0.0.1")
  }

  Void testCaSignedLeafNotPinned()
  {
    // trusting the CA-signed leaf itself does not exempt it from the name check
    keys  := keyStore(srvKeys, [srvCert, caCert])
    trust := trustStore(srvCert)
    verifyOk(keys, trust, "localhost")
    verifyHostErr(keys, trust, "127.0.0.1")
  }

  Void testSelfSignedPin()
  {
    // trusted self-signed cert is accepted for any host
    keys := keyStore(selfKeys, [selfCert])
    verifyOk(keys, trustStore(selfCert), "localhost")
    verifyOk(keys, trustStore(selfCert), "127.0.0.1")

    // a different self-signed cert for the same name is not trusted
    otherKeys := crypto.genKeyPair("RSA", 2048)
    other := sign(otherKeys, "CN=localhost", [San.dnsName("localhost")])
    verifyErr(IOErr#) { connect(keys, trustStore(other), "127.0.0.1") }
  }

  Void testLayered()
  {
    // plain connect then upgrade (STARTTLS) uses the host passed to connect
    keys  := keyStore(srvKeys, [srvCert, caCert])
    trust := trustStore(caCert)
    verifyOk(keys, trust, "localhost", true)
    verifyHostErr(keys, trust, "127.0.0.1", true)
  }

  Void testTunnelIpv6()
  {
    // bracketed IPv6 literal for the tunnel destination
    certKeys := crypto.genKeyPair("RSA", 2048)
    cert := sign(certKeys, "CN=localhost", [San.ipAddr("::1")], caKeys.priv, caCert)
    keys  := keyStore(certKeys, [cert, caCert])
    trust := trustStore(caCert)
    res := serve(SocketConfig { it.keystore = keys }) |port|
    {
      s := TcpSocket(clientConfig(trust)).connect(IpAddr("::1"), port)
      return talk(s.upgradeTls(IpAddr("[::1]"), port))
    }
    verifyEq(res.first, "hello")
  }

  Void testClientAuth()
  {
    keys  := keyStore(srvKeys, [srvCert, caCert])
    trust := trustStore(caCert)

    // client cert signed by the test CA
    cliKeys := crypto.genKeyPair("RSA", 2048)
    cliCert := sign(cliKeys, "CN=client", San[,], caKeys.priv, caCert)
    withCert := clientConfig(trust).copy { it.keystore = keyStore(cliKeys, [cliCert, caCert]) }
    noCert   := clientConfig(trust)

    // only exact values are accepted
    verifyErr(ArgErr#) { x := SocketConfig { it.tlsParams = ["clientAuth":"bogus"] } }
    verifyErr(ArgErr#) { x := SocketConfig { it.tlsParams = ["clientAuth":"NEED"] } }
    verifyErr(ArgErr#) { x := SocketConfig().copy { it.tlsParams = ["clientAuth":"required"] } }

    // none and want accept a client without a cert
    verifyEq(clientAuth(keys, trust, "none", noCert), "none")
    verifyEq(clientAuth(keys, trust, "want", noCert), "want")
    verifyEq(clientAuth(keys, trust, "want", withCert), "want")

    // need requires a trusted client cert
    verifyEq(clientAuth(keys, trust, "need", withCert), "need")
    verifyEq(clientAuth(keys, trust, "need", noCert), null)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private Void verifyOk(KeyStore keys, KeyStore trust, Str host, Bool layered := false)
  {
    verifyEq(connect(keys, trust, host, layered), "hello")
  }

  private Void verifyHostErr(KeyStore keys, KeyStore trust, Str host, Bool layered := false)
  {
    verifyErrMsgContains(keys, trust, host, layered, "does not match host '${host}'")
  }

  private Void verifyErrMsgContains(KeyStore keys, KeyStore trust, Str host, Bool layered, Str msg)
  {
    try
    {
      connect(keys, trust, host, layered)
      fail
    }
    catch (IOErr e)
    {
      verify(e.msg.contains(msg), e.msg)
    }
  }

  ** Connect to a server with the given clientAuth mode and return the mode
  ** the server socket reports, or null if the handshake failed
  private Str? clientAuth(KeyStore keys, KeyStore trust, Str mode, SocketConfig client)
  {
    config := SocketConfig { it.keystore = keys; it.truststore = trust; it.tlsParams = ["clientAuth":mode] }
    res := serve(config) |port|
    {
      try
        return talk(TcpSocket(client).upgradeTls.connect(IpAddr("localhost"), port))
      catch (IOErr e)
        return null
    }
    return res.last
  }

  private Str? connect(KeyStore keys, KeyStore trust, Str host, Bool layered := false)
  {
    serve(SocketConfig { it.keystore = keys }) |port|
    {
      s := TcpSocket(clientConfig(trust))
      if (layered)
      {
        s.connect(IpAddr(host), port)
        s = s.upgradeTls
      }
      else
      {
        s = s.upgradeTls
        s.connect(IpAddr(host), port)
      }
      return talk(s)
    }.first
  }

  ** Run a TLS server for one connection while the client callback runs
  ** and return the client and server results
  private Str?[] serve(SocketConfig config, |Int port->Str?| client)
  {
    listener := TcpListener(config).bind(null, null)
    future := Actor(ActorPool()) |msg| { runServer(((Unsafe)msg).val) }.send(Unsafe(listener))
    Str? res := null
    Str? srvRes := null
    try
      res = client(listener.localPort)
    finally
    {
      try { srvRes = future.get(10sec) } catch (Err e) {}
      listener.close
    }
    return [res, srvRes]
  }

  private static Obj? runServer(TcpListener listener)
  {
    s := listener.accept
    try
    {
      t := s.upgradeTls
      t.out.printLine("hello").flush
      return t.in.readLine == null ? null : t.clientAuth
    }
    catch (Err e) return null
    finally s.close
  }

  private static Str? talk(TcpSocket s)
  {
    try
    {
      res := s.in.readLine
      s.out.printLine("bye").flush
      return res
    }
    finally s.close
  }

  private SocketConfig clientConfig(KeyStore trust)
  {
    SocketConfig { it.truststore = trust; it.connectTimeout = 5sec; it.receiveTimeout = 5sec }
  }

  private KeyStore keyStore(KeyPair keys, Cert[] chain)
  {
    crypto.loadKeyStore.setPrivKey("https", keys.priv, chain)
  }

  private KeyStore trustStore(Cert cert)
  {
    crypto.loadKeyStore.setTrust("trust", cert)
  }

  private Cert sign(KeyPair keys, Str dn, San[] sans, PrivKey? caPriv := null, Cert? caCert := null, Bool isCa := false)
  {
    signer := crypto.certSigner(crypto.genCsr(keys, dn))
                .notBefore(Date.today - 1day)
                .notAfter(Date.today + 30day)
                .basicConstraints(isCa)
    if (caPriv != null) signer.ca(caPriv, caCert)
    sans.each |san| { signer.subjectAltName(san) }
    return signer.sign
  }
}
