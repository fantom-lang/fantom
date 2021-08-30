//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 2021 Matthew Giannini Creation
//

**
** KeyStore stores keys[`Key`] and certificates[`Cert`] in an aliased
** [keystore entry]`KeyStoreEntry`. Aliases are case-insensitive.
**
** See `Crypto.loadKeyStore`
**
const mixin KeyStore
{

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  ** Get the format that this keystore stores entries in.
  abstract Str format()

  ** Get all the aliases in the key store.
  abstract Str[] aliases()

  ** Get the number of [entries]`KeyStoreEntry` in the key store.
  abstract Int size()

//////////////////////////////////////////////////////////////////////////
// I/O
//////////////////////////////////////////////////////////////////////////

  ** Save the entries in the keystore to the output stream.
  abstract Void save(OutStream out, Str:Obj options := [:])

//////////////////////////////////////////////////////////////////////////
// Entries
//////////////////////////////////////////////////////////////////////////

  ** Get the entry with the given alias.
  abstract KeyStoreEntry? get(Str alias, Bool checked := true)

  ** Convenience to get a `TrustEntry` from the keystore.
  virtual TrustEntry? getTrust(Str alias, Bool checked := true) { get(alias, checked) }

  ** Convenience to get a `PrivKeyEntry` from the keystore.
  virtual PrivKeyEntry? getPrivKey(Str alias, Bool checked := true) { get(alias, checked) }

  ** Return ture if the key store has an entry with the given alias.
  virtual Bool containsAlias(Str alias) { get(alias, false) != null }

  ** Adds a `PrivKeyEntry` to the keystore with the given alias and returns it.
  abstract This setPrivKey(Str alias, PrivKey priv, Cert[] chain)

  ** Adds a `TrustEntry` to the keystore with the given alias and returns it.
  abstract This setTrust(Str alias, Cert cert)

  ** Set an alias to have the given entry. If the alias
  ** already exists, it is overwritten.
  **
  ** Throws Err if the key store is not writable.
  **
  ** Throws Err if the key store doesn't support writing the entry type.
  abstract This set(Str alias, KeyStoreEntry entry)

  ** Remove the entry with the given alias.
  **
  ** Throws Err if the key store is not writable.
  abstract Void remove(Str alias)

}

**************************************************************************
** KeyStoreEntry
**************************************************************************

**
** Marker mixin for an entry in a [keystore]`KeyStore`
**
const mixin KeyStoreEntry
{
  ** Get the attributes associated with this entry.
  ** The attributes are immutable.
  abstract Str:Str attrs()
}

**************************************************************************
** PrivKeyEntry
**************************************************************************

**
** A PrivKeyEntry stores a private key and the certificate chain
** for the corresponding public key.
**
const mixin PrivKeyEntry : KeyStoreEntry
{
  ** Get the private key from this entry.
  abstract PrivKey priv()

  ** Get the certificate chain from this entry.
  abstract Cert[] certChain()

  ** Get the end entity certificate from the certificate chain; this should
  ** be the first entry in the `certChain`.
  virtual Cert cert() { certChain.first }

  ** Convenience to get the public key from the `cert`.
  virtual PubKey pub() { cert.pub }

  ** Get the `KeyPair` for the entry. It consists of the `priv` and `pub`
  ** keys from this entry.
  abstract KeyPair keyPair()
}

**************************************************************************
** TrustEntry
**************************************************************************

**
** Keystore entry for a trusted certificate.
**
const mixin TrustEntry : KeyStoreEntry
{
  ** Get the trusted certificate from this entry.
  abstract Cert cert()
}
