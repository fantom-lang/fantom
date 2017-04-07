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
  public static TcpListener makeTls(Object keystore) { return makeTls(keystore, null); }
  public static TcpListener makeTls(Object keystore, Object truststore)
  {
    try
    {
      TcpListener self = TcpListener.make();
      self.peer.initTls(keystore, truststore);
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
      if (sslContext != null)
      {
        try { s = upgradeTls(s); }
        catch (IOException e) { s.close(); throw e; }
      }
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

  private void initTls(Object keystore, Object truststore) throws Exception
  {
    // init tls with backwards compatibility where we used to pass
    // uri to keystore and str password
    if ((keystore == null && truststore == null)
        || (keystore instanceof Uri)
        || (truststore instanceof String))
    {
      initTlsWithoutCrypto((Uri)keystore, (String)truststore);
    }
    else
    {
      initTlsWithCrypto((FanObj)keystore, (FanObj)truststore);
    }
  }

  private void initTlsWithoutCrypto(Uri keystore, String pwd)
    throws Exception
  {
    // load keystore
    if (keystore == null)
      keystore = Env.cur().workDir().plus(Uri.fromStr("etc/inet/keystore.p12")).uri();
    if (pwd == null)
      pwd = "changeit";

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

  private void initTlsWithCrypto(FanObj keys, FanObj truststore)
    throws Exception
  {
    // Delegate creation of key and trust managers to crypto
    Class klass = Class.forName("fan.crypto.InetTLS");
    KeyManager[]   kms = (KeyManager[])klass.getMethod("toKeyManagers", FanObj.class).invoke(null, keys);
    TrustManager[] tms = (TrustManager[])klass.getMethod("toTrustManagers", FanObj.class).invoke(null, truststore);

    SSLContext sslContext = SSLContext.getInstance("TLS");
    sslContext.init(kms, tms, null);
    this.sslContext = sslContext;
  }

  private TcpSocket upgradeTls(TcpSocket s) throws IOException
  {
    SSLSocketFactory sf = sslContext.getSocketFactory();
    SSLSocket sslSocket = (SSLSocket)sf.createSocket(
      s.peer.socket,
      s.peer.socket.getInetAddress().getHostAddress(),
      s.peer.socket.getPort(),
      false
    );
    sslSocket.setUseClientMode(false);
    sslSocket.startHandshake();

    TcpSocket upgraded = new TcpSocket();
    upgraded.peer = new TcpSocketPeer(sslSocket);
    upgraded.peer.connected(upgraded);
    return upgraded;
  }

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

  private int inBufSize = 4096;
  private int outBufSize = 4096;
  private SysInStream in;
  private SysOutStream out;

}
