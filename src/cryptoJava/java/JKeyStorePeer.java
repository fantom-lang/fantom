//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Aug 2021 Matthew Giannini   Creation
//

package fan.cryptoJava;

import fan.sys.*;
import fan.concurrent.ConcurrentMap;
import fan.crypto.Cert;
import fanx.interop.Interop;

import java.util.Enumeration;
import java.util.HashMap;
import java.util.Set;
import java.io.InputStream;
import java.io.IOException;

import java.security.KeyStore.Entry;
import java.security.KeyStore.PrivateKeyEntry;
import java.security.KeyStore.PasswordProtection;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;

public class JKeyStorePeer
{

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  public static JKeyStore load(File file, Map opts)
  {
    // format option trumps file extension
    String format = (String)opts.get("format");
    if (format == null)
    {
      String ext = "p12";
      if (file != null)
      {
        // If the file doesn't have an extension, then default is pkcs12
        ext = file.ext();
        if (ext == null) ext = "p12";
      }
      switch(ext)
      {
        case "p12":
        case "pfx":
          format = "pkcs12";
          break;
        case "jks":
          format = "jks";
          break;
        default:
          throw UnsupportedErr.make("Unsupported file ext: " + file.ext());
      }
    }
    return file == null
      ? JKeyStore.make(format, ConcurrentMap.make())
      : JKeyStore.make(format, loadStream(format, file.in(), opts));
  }

  private static ConcurrentMap loadStream(final String format, final InStream fanIn, final Map opts)
  {
    try
    {
      // load java key store
      java.security.KeyStore ks = java.security.KeyStore.getInstance(format);
      char[] pwd = toPassword(opts);
      try (InputStream in = Interop.toJava(fanIn))
      {
        ks.load(in, pwd);
      }

      // translate entries and return as a concurrent map
      PasswordProtection protection = new PasswordProtection(pwd);
      return translateEntries(ks, protection);
    }
    catch (Err e) { throw e; }
    catch (Exception e) { throw Err.make(e); }
  }

  private static char[] toPassword(final Map opts)
  {
    String pwd = (String)opts.get("password");
    if (pwd == null) pwd = "changeit";
    return pwd.toCharArray();
  }

  private static ConcurrentMap translateEntries(java.security.KeyStore ks,
                                   PasswordProtection protection)
    throws Exception
  {
    ConcurrentMap store = ConcurrentMap.make();
    for (Enumeration<String> e = ks.aliases(); e.hasMoreElements(); )
    {
      // normalize all aliases to lower-case
      final String alias = e.nextElement().toLowerCase();
      if (ks.isKeyEntry(alias))
      {
        // PrivKeyEntry
        PrivateKeyEntry privEntry = (PrivateKeyEntry)ks.getEntry(alias, protection);
        JPrivKey privKey = new JPrivKey(privEntry.getPrivateKey());
        Certificate[] certs = privEntry.getCertificateChain();
        List chain = List.make(Type.find("crypto::Cert"), certs.length);
        for (int i=0; i<certs.length; ++i)
        {
          chain.add(new X509((X509Certificate)certs[i]));
        }
        store.set(alias, JPrivKeyEntry.make(privKey, chain, toAttrs(privEntry)));
      }
      else if (ks.isCertificateEntry(alias))
      {
        // TrustEntry
        X509 x509 = new X509((X509Certificate)ks.getCertificate(alias));
        store.set(alias, JTrustEntry.make(x509));
      }
      else throw Err.make("Secret keys not supported: " + alias);
    }
    return store;
  }

  private static Map toAttrs(Entry entry)
  {
    Set<Entry.Attribute> jattrs = entry.getAttributes();
    if (jattrs.isEmpty()) return emptyAttrs;

    Map attrs = Map.make(attrsType);
    for (Entry.Attribute attr: jattrs)
    {
      attrs.set(attr.getName(), attr.getValue());
    }
    return attrs;
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static JKeyStorePeer make(JKeyStore self)
  {
    return new JKeyStorePeer();
  }

//////////////////////////////////////////////////////////////////////////
// JKeyStore
//////////////////////////////////////////////////////////////////////////

  private static final MapType attrsType = new MapType(Type.find("sys::Str"), Type.find("sys::Str"));
  private static final Map emptyAttrs = Map.make(attrsType);

  private static final Map emptyOpts = Map.make(
    new MapType(Type.find("sys::Str"), Type.find("sys::Obj"))
  );

  public void save(JKeyStore self, OutStream fanOut) { save(self, fanOut, emptyOpts); }
  public void save(JKeyStore self, OutStream fanOut, Map opts)
  {
    try
    {
      // create a new empty java keystore
      java.security.KeyStore ks = java.security.KeyStore.getInstance(self.format());
      char[] pwd = toPassword(opts);
      PasswordProtection protection = new PasswordProtection(pwd);
      ks.load(null, pwd);

      // fill the store
      self.entries.each(new Func.Indirect2() {
        public Object call(Object a, Object b)
        {
          try
          {
            String alias = (String)b;
            JKeyStoreEntry  entry = (JKeyStoreEntry)a;
            if (entry instanceof JPrivKeyEntry)
            {
              // create java private key
              final JPrivKeyEntry privKeyEntry = (JPrivKeyEntry)entry;
              final JPrivKey privKey = (JPrivKey)JPrivKey.decode(privKeyEntry.priv.encoded(), privKeyEntry.priv.algorithm());

              // create java certificate chain
              Cert[] chain = (Cert[])privKeyEntry.certChain.asArray(Cert.class);
              Certificate[] certs = new Certificate[chain.length];
              for (int i = 0; i < chain.length; ++i)
              {

                certs[i] = ((X509)X509.load(chain[i].encoded().in()).first()).cert;
              }

              // store entry
              ks.setEntry(alias, new PrivateKeyEntry(privKey.priv(), certs), protection);
            }
            else if (entry instanceof JTrustEntry)
            {
              Cert cert = ((JTrustEntry)entry).cert;
              X509 x509 = (X509)X509.load(cert.encoded().in()).first();
              ks.setCertificateEntry(alias, x509.cert);
            }
            else throw UnsupportedErr.make("Unsupported entry: " + entry);
            return null;
          }
          catch (Exception x) { throw Err.make(x); }
        }
      });

      // write the store
      ks.store(Interop.toJava(fanOut), pwd);
    }
    catch (Err e) { throw e; }
    catch (Exception e) { throw Err.make(e); }
  }
}