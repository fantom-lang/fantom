//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Aug 2021 Matthew Giannini   Creation
//

using concurrent
using crypto

const class JKeyStore : KeyStore
{
  native static JKeyStore load(File? file, Str:Obj opts)

  internal new make(Str format, ConcurrentMap entries)
  {
    this.format  = format
    this.entries = entries
  }

  internal const ConcurrentMap entries

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  override const Str format

  override Str[] aliases() { entries.keys(Str#) }

  override Int size() { entries.size }

//////////////////////////////////////////////////////////////////////////
// I/O
//////////////////////////////////////////////////////////////////////////

  native override Void save(OutStream out, Str:Obj options := [:])

//////////////////////////////////////////////////////////////////////////
// Entries
//////////////////////////////////////////////////////////////////////////

  override KeyStoreEntry? get(Str alias, Bool checked := true)
  {
    entry := entries.get(normAlias(alias)) as KeyStoreEntry
    if (entry != null) return entry
    if (checked) throw Err("No entry with alias: '$alias'")
    return null
  }

  override This setPrivKey(Str alias, PrivKey privKey, Cert[] chain)
  {
    set(alias, JPrivKeyEntry(privKey, chain))
  }

  override This setTrust(Str alias, Cert cert)
  {
    set(alias, JTrustEntry(cert))
  }

  override This set(Str alias, KeyStoreEntry entry)
  {
    // store normalized to lower-case
    entries.set(normAlias(alias), entry)
    return this
  }

  override Void remove(Str alias) { entries.remove(alias) }

  ** Normalize alias to lower-case
  private Str normAlias(Str alias) { alias.lower }
}

**************************************************************************
** JKeyStoreEntry
**************************************************************************

const class JKeyStoreEntry : KeyStoreEntry
{
  new make(Str:Str attrs) { this.attrs = attrs }

  override const Str:Str attrs
}

**************************************************************************
** JPrivKeyEntry
**************************************************************************

**
** A PrivKeyEntry stores a private key and the certificate chain
** for the corresponding public key.
**
const class JPrivKeyEntry : JKeyStoreEntry, PrivKeyEntry
{
  new make(PrivKey priv, Cert[] chain, Str:Str attrs := [:]) : super(attrs)
  {
    this.priv      = priv
    this.certChain = chain
  }

  override const PrivKey priv

  override const Cert[] certChain

  override JKeyPair keyPair() { JKeyPair(priv, pub) }
}

**************************************************************************
** JTrustEntry
**************************************************************************

const class JTrustEntry : JKeyStoreEntry, TrustEntry
{
  new make(Cert cert, Str:Str attrs := [:]) : super(attrs)
  {
    this.cert = cert
  }

  override const Cert cert
}