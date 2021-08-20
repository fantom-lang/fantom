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

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;

import java.net.Socket;

import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;

import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLException;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;

final class CertChainLoader
{
  public CertChainLoader(Uri uri) { this.uri = uri; }

  final private Uri uri;

  public List load()
  {
    final String host = uri.host();
    final int port    = uriToPort(uri);
    List acc = new List(X509.typeof);
    try
    {
      SSLContext context = SSLContext.getInstance("TLS");
      TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
      tmf.init((java.security.KeyStore)null);
      X509TrustManager defaultTrustManager = (X509TrustManager)tmf.getTrustManagers()[0];
      SavingTrustManager tm = new SavingTrustManager(defaultTrustManager);
      context.init(null, new TrustManager[] {tm}, null);
      SSLSocketFactory factory = context.getSocketFactory();

      SSLSocket socket = (SSLSocket)factory.createSocket(host, port);
      socket.setSoTimeout(10000);
      try
      {
        socket.startHandshake();
        socket.close();
//        return acc;  // no errors, already trusted
      }
      catch (SSLException e) {}

      X509Certificate[] chain = tm.chain;
      if (chain == null && "smtp".equals(uri.scheme()))
      {
        trySTARTTLS(host, port, factory);
        chain = tm.chain;
      }
      else if (chain == null && "ftp".equals(uri.scheme()))
      {
        tryAuthTLS(host, port, factory);
        chain = tm.chain;
      }
      if (chain == null)
        throw Err.make("Could not obtain server certificate chain");

      for (int i = 0; i < chain.length; i++)
        acc.add(new X509(chain[i]));
      return acc;
    }
    catch (Exception e) { throw Err.make(e); }
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  private static int uriToPort(Uri uri)
  {
    Long port = uri.port();
    if (port != null) return port.intValue();
    if (uri.scheme() == null) throw ArgErr.make("URI missing scheme: " + uri);
    if (uri.scheme().equals("http"))  return 80;
    if (uri.scheme().equals("https")) return 443;
    if (uri.scheme().equals("smtp"))  return 25;
    if (uri.scheme().equals("smtps")) return 465;
    if (uri.scheme().equals("ftp"))   return 21;
    throw ArgErr.make("Unsupported URI scheme: " + uri + "; use explicit port");
  }

  private static void trySTARTTLS(final String host, final int port, SSLSocketFactory factory)
    throws Exception
  {
    try
    {
      Socket s = new Socket(host, port);
      BufferedWriter bout = new BufferedWriter(new OutputStreamWriter(s.getOutputStream()));
      BufferedReader bin = new BufferedReader(new InputStreamReader(s.getInputStream()));
      readSmtpRes(bin);
      writeSmtpReq(bout, "EHLO [127.0.0.1]\r\n");
      readSmtpRes(bin);
      writeSmtpReq(bout, "STARTTLS\r\n");
      readSmtpRes(bin);
      SSLSocket tls = (SSLSocket)factory.createSocket(
        s,
        s.getInetAddress().getHostAddress(),
        s.getPort(),
        false);
      tls.setUseClientMode(true);
      tls.startHandshake();
      tls.close();
    }
    catch (SSLException e) {}
    catch (Exception e) { e.printStackTrace(); }
  }

  private static void writeSmtpReq(BufferedWriter out, String line) throws Exception
  {
    System.out.print("c: " + line);
    out.write(line);
    out.flush();
  }

  private static void readSmtpRes(BufferedReader in) throws Exception
  {
    while (true)
    {
      String line = in.readLine();
      System.out.println("s: " + line);
      int code = Integer.parseInt(line.substring(0,3));
      if (line.length() <= 4) break;
      if (line.charAt(3) != '-') break;
    }
  }

  private static void tryAuthTLS(final String host, final int port, SSLSocketFactory factory)
    throws Exception
  {
    try
    {
      Socket s = new Socket(host, port);
      BufferedWriter bout = new BufferedWriter(new OutputStreamWriter(s.getOutputStream()));
      BufferedReader bin = new BufferedReader(new InputStreamReader(s.getInputStream()));
      readFtpRes(bin);
      writeFtpReq(bout, "AUTH TLS\r\n");
      readFtpRes(bin);
      SSLSocket tls = (SSLSocket)factory.createSocket(
        s,
        s.getInetAddress().getHostAddress(),
        s.getPort(),
        false);
      tls.setUseClientMode(true);
      tls.startHandshake();
      tls.close();
    }
    catch (SSLException e) {}
    catch (Exception e) { e.printStackTrace(); }
  }

  private static void readFtpRes(BufferedReader in) throws Exception
  {
    String line = in.readLine();
    System.out.println("s: " + line);
    if (line.charAt(3) == '-')
    {
      String prefix = line.substring(0,3) + " ";
      while (true)
      {
        line = in.readLine();
        System.out.println("s: " + line);
        if (line.startsWith(prefix)) break;
      }
    }
  }

  private static void writeFtpReq(BufferedWriter out, String cmd) throws Exception
  {
    System.out.println("c: " + cmd);
    out.write(cmd);
    out.flush();
  }

//////////////////////////////////////////////////////////////////////////
// SavingTrustManager
//////////////////////////////////////////////////////////////////////////

  private static class SavingTrustManager implements X509TrustManager
  {
    private final X509TrustManager tm;
    private X509Certificate[] chain;

    SavingTrustManager(X509TrustManager tm)
    {
      this.tm = tm;
    }

    public X509Certificate[] getAcceptedIssuers()
    {
      throw new UnsupportedOperationException();
    }

    public void checkClientTrusted(X509Certificate[] chain, String authType)
      throws CertificateException
    {
      throw new UnsupportedOperationException();
    }

    public void checkServerTrusted(X509Certificate[] chain, String authType)
      throws CertificateException
    {
      this.chain = chain;
      tm.checkServerTrusted(chain, authType);
    }
  }
}