//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Oct 2026  Matthew Giannini  Creation
//
package fan.inet;

import java.net.Socket;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.HashSet;
import javax.net.ssl.*;

/**
 * HostTrustManager wraps the PKIX trust manager for client sockets that
 * verify the server certificate matches the host name connected to.
 * A self-signed certificate that is itself a trusted entry is accepted
 * for any host, and a failed name check reports the host name.
 */
final class HostTrustManager extends X509ExtendedTrustManager
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  /** Wrap every extended trust manager, leaving any others as is */
  static TrustManager[] wrap(TrustManager[] tms)
  {
    final TrustManager[] acc = new TrustManager[tms.length];
    for (int i=0; i<tms.length; ++i)
    {
      if (tms[i] instanceof X509ExtendedTrustManager)
        acc[i] = new HostTrustManager((X509ExtendedTrustManager)tms[i]);
      else
        acc[i] = tms[i];
    }
    return acc;
  }

  private HostTrustManager(X509ExtendedTrustManager tm)
  {
    this.tm = tm;
    for (X509Certificate cert : tm.getAcceptedIssuers())
      if (isSelfSigned(cert)) pinned.add(cert);
  }

  private final X509ExtendedTrustManager tm;
  private final HashSet<X509Certificate> pinned = new HashSet<X509Certificate>();

//////////////////////////////////////////////////////////////////////////
// Server Trust
//////////////////////////////////////////////////////////////////////////

  public void checkServerTrusted(X509Certificate[] chain, String authType, Socket socket)
    throws CertificateException
  {
    if (isPinned(chain)) return;
    try
    {
      tm.checkServerTrusted(chain, authType, socket);
    }
    catch (CertificateException e)
    {
      throw hostErr(chain, authType, peerHost(socket), e);
    }
  }

  public void checkServerTrusted(X509Certificate[] chain, String authType, SSLEngine engine)
    throws CertificateException
  {
    if (isPinned(chain)) return;
    try
    {
      tm.checkServerTrusted(chain, authType, engine);
    }
    catch (CertificateException e)
    {
      final SSLSession session = engine == null ? null : engine.getHandshakeSession();
      throw hostErr(chain, authType, session == null ? null : session.getPeerHost(), e);
    }
  }

  public void checkServerTrusted(X509Certificate[] chain, String authType)
    throws CertificateException
  {
    if (isPinned(chain)) return;
    tm.checkServerTrusted(chain, authType);
  }

  // The leaf is a self-signed certificate that is itself trusted
  private boolean isPinned(X509Certificate[] chain)
  {
    return chain != null && chain.length > 0 && pinned.contains(chain[0]);
  }

  // If the chain itself is trusted then the failure was the host
  // name check, so report the host; otherwise raise the chain error
  private CertificateException hostErr(X509Certificate[] chain, String authType, String host, CertificateException e)
    throws CertificateException
  {
    tm.checkServerTrusted(chain, authType);
    return new CertificateException("Server certificate does not match host '" + host + "': " + e.getMessage(), e);
  }

  private static String peerHost(Socket socket)
  {
    if (!(socket instanceof SSLSocket)) return null;
    final SSLSession session = ((SSLSocket)socket).getHandshakeSession();
    return session == null ? null : session.getPeerHost();
  }

  // Same test as cryptoJava X509.isSelfSigned: verifies with its own key
  private static boolean isSelfSigned(X509Certificate cert)
  {
    try
    {
      cert.verify(cert.getPublicKey());
      return true;
    }
    catch (Exception e)
    {
      return false;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Client Trust
//////////////////////////////////////////////////////////////////////////

  public void checkClientTrusted(X509Certificate[] chain, String authType, Socket socket)
    throws CertificateException
  {
    tm.checkClientTrusted(chain, authType, socket);
  }

  public void checkClientTrusted(X509Certificate[] chain, String authType, SSLEngine engine)
    throws CertificateException
  {
    tm.checkClientTrusted(chain, authType, engine);
  }

  public void checkClientTrusted(X509Certificate[] chain, String authType)
    throws CertificateException
  {
    tm.checkClientTrusted(chain, authType);
  }

  public X509Certificate[] getAcceptedIssuers()
  {
    return tm.getAcceptedIssuers();
  }
}
