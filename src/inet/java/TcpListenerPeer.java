//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Feb 07  Brian Frank  Creation
//
package fan.inet;

import java.io.*;
import java.net.*;
import java.util.*;
import java.security.*;
import javax.net.ssl.*;
import fan.sys.*;

public class TcpListenerPeer
  extends ServerSocket
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static TcpListenerPeer make(TcpListener fan)
  {
    try
    {
      return new TcpListenerPeer();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public static TcpListener makeTls() { return makeTls(null); }
  public static TcpListener makeTls(Uri keystore) { return makeTls(keystore, null); }
  public static TcpListener makeTls(Uri keystore, String pass)
  {
    if (keystore == null)
      keystore = Env.cur().workDir().plus(Uri.fromStr("etc/inet/keystore.p12")).uri();
    if (pass == null)
     pass = "changeit";
    try
    {
      TcpListener self = TcpListener.make();
      self.peer.initTls(keystore, pass);
      return self;
    }
    catch (Exception e)
    {
      throw IOErr.make(e);
    }
  }

  public TcpListenerPeer()
    throws IOException
  {
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public boolean isBound(TcpListener fan)
  {
    return isBound();
  }

  public boolean isClosed(TcpListener fan)
  {
    return isClosed();
  }

//////////////////////////////////////////////////////////////////////////
// End Points
//////////////////////////////////////////////////////////////////////////

  public IpAddr localAddr(TcpListener fan)
  {
    if (!isBound()) return null;
    InetAddress addr = getInetAddress();
    if (addr == null) return null;
    return IpAddrPeer.make(addr);
  }

  public Long localPort(TcpListener fan)
  {
    if (!isBound()) return null;
    int port = getLocalPort();
    if (port <= 0) return null;
    return Long.valueOf(port);
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public TcpListener bind(TcpListener fan, IpAddr addr, Long port, long backlog)
  {
    try
    {
      InetAddress javaAddr = (addr == null) ? null : addr.peer.java;
      int javaPort = (port == null) ? 0 : port.intValue();
      bind(new InetSocketAddress(javaAddr, javaPort), (int)backlog);
      return fan;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public TcpSocket doAccept(TcpListener fan)
  {
    try
    {
      TcpSocket s = TcpSocket.make();
      implAccept(s.peer.socket);
      s.peer.connected(s);
      if (sslContext != null) s = upgradeTls(s);
      return s;
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean close(TcpListener fan)
  {
    try
    {
      close();
      return true;
    }
    catch (Exception e)
    {
      return false;
    }
  }

//////////////////////////////////////////////////////////////////////////
// TLS
//////////////////////////////////////////////////////////////////////////

  /** If non-null, then the the socket is upgraded to TLS in doAccept() */
  private SSLContext sslContext = null;

  private void initTls(final Uri keystore, final String pwd) throws Exception
  {
    // load keystore
    final String path = keystore.toFile().osPath();
    InputStream storeIn = new FileInputStream(path);
    try
    {
      char[] passphrase = pwd.toCharArray();
      KeyStore keys = KeyStore.getInstance("PKCS12");
      keys.load(storeIn, passphrase);

      KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
      kmf.init(keys, passphrase);

      SSLContext sslContext = SSLContext.getInstance("TLS");
      sslContext.init(kmf.getKeyManagers(), null, null);
      this.sslContext = sslContext;
    }
    finally
    {
      storeIn.close();
    }
  }

  private TcpSocket upgradeTls(TcpSocket s) throws IOException
  {
    SSLSocketFactory sf = sslContext.getSocketFactory();
    InetSocketAddress remoteAddr = (InetSocketAddress)s.peer.socket.getRemoteSocketAddress();
    SSLSocket sslSocket = (SSLSocket)sf.createSocket(
      s.peer.socket,
      remoteAddr.getHostName(),
      s.peer.socket.getPort(),
      false
    );
    sslSocket.setEnabledCipherSuites(intersection(sslSocket.getSupportedCipherSuites(), ENABLED_CIPHER_SUITES));
    sslSocket.setUseClientMode(false);
    sslSocket.startHandshake();

    TcpSocket upgraded = new TcpSocket();
    upgraded.peer = new TcpSocketPeer(sslSocket);
    upgraded.peer.connected(upgraded);
    return upgraded;
  }

  private static String[] intersection(String[] a, String[] b) {
      Set set = new HashSet(Arrays.asList(a));
      set.retainAll(Arrays.asList(b));
      return (String[])set.toArray(new String[set.size()]);
  }

  private static final String[] ENABLED_CIPHER_SUITES = new String[] {

          // Cipher suites that are not listed at
          // http://java.sun.com/javase/6/docs/technotes/guides/security/StandardNames.html

          "TLS_RSA_WITH_DES_CBC_SHA",
          "TLS_RSA_WITH_3DES_EDE_CBC_SHA",
          "TLS_RSA_WITH_RC4_128_SHA",
          "TLS_RSA_WITH_RC4_128_MD5",

          // Strong cipher suites that are listed at
          // http://java.sun.com/javase/6/docs/technotes/guides/security/StandardNames.html

          "TLS_RSA_WITH_AES_128_CBC_SHA",
          "TLS_RSA_WITH_AES_256_CBC_SHA",
          "SSL_RSA_WITH_3DES_EDE_CBC_SHA",
          "SSL_RSA_WITH_RC4_128_MD5",
          "SSL_RSA_WITH_RC4_128_SHA",

          // https://support.google.com/chrome/answer/6098869?p=dh_error&rd=1#DHkey
          // indicates to use ECDHE and disable DHE
          "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA",
          "TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA",
          "TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA",
          "TLS_ECDHE_ECDSA_WITH_RC4_128_SHA",
          "TLS_ECDHE_ECDSA_WITH_NULL_SHA",
          "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA",
          "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA",
          "TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA",
          "TLS_ECDHE_RSA_WITH_RC4_128_SHA",
          "TLS_ECDHE_RSA_WITH_NULL_SHA",
  };

//////////////////////////////////////////////////////////////////////////
// Socket Options
//////////////////////////////////////////////////////////////////////////

  public long getReceiveBufferSize(TcpListener fan)
  {
    try
    {
      return getReceiveBufferSize();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setReceiveBufferSize(TcpListener fan, long v)
  {
    try
    {
      setReceiveBufferSize((int)v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public boolean getReuseAddr(TcpListener fan)
  {
    try
    {
      return getReuseAddress();
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setReuseAddr(TcpListener fan, boolean v)
  {
    try
    {
      setReuseAddress(v);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public Duration getReceiveTimeout(TcpListener fan)
  {
    try
    {
      int timeout = getSoTimeout();
      if (timeout <= 0) return null;
      return Duration.makeMillis(timeout);
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

  public void setReceiveTimeout(TcpListener fan, Duration v)
  {
    try
    {
      if (v == null)
        setSoTimeout(0);
      else
        setSoTimeout((int)(v.millis()));
    }
    catch (IOException e)
    {
      throw IOErr.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private IpAddr remoteAddr;
  private int remotePort;
  private int inBufSize = 4096;
  private int outBufSize = 4096;
  private SysInStream in;
  private SysOutStream out;

}
