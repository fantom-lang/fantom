//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Apr 2026 Ross Schwalm Creation
//

**
** San defines the api for a Subject Alternative Name based on RFC 5280.
**
const class San
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Create as `SanType.dnsName`
  static new dnsName(Str name) { San(SanType.dnsName, name) }

  ** Create as `SanType.uri` - Accepts Uri or Str (value stored as Str)
  static new uri(Obj uri)
  {
    //Store uri as a string to avoid adding trailing slash
    if (uri is Str)
    {
      if (Uri.fromStr(uri).isRel) throw ArgErr("Parameter must not be a relative Uri")
      return San(SanType.uri, uri.toStr)
    }
    else if (uri is Uri) return San.uri(uri.toStr)
    throw ArgErr("Parameter must be Uri or Str")
  }

  ** Create as `SanType.ipAddr` - Accepts IpAddr or Str (value stored as IpAddr)
  static new ipAddr(Obj ip)
  {
    IpAddr := Type.find("inet::IpAddr")
    if (ip is Str) return San(SanType.ipAddr, IpAddr.make([ip]))
    else if (IpAddr.fits(ip.typeof)) return San(SanType.ipAddr, ip)
    throw ArgErr("Parameter must be IpAddr or Str")
  }

  ** Create as `SanType.rfc822Name`
  static new rfc822Name(Str email) { San(SanType.rfc822Name, email) }

  ** Create as `SanType.dirName`
  static new dirName(Str dn) { San(SanType.dirName, dn) }

  ** Create as `SanType.otherName`
  static new otherName(Buf buf) { San(SanType.otherName, buf.toImmutable) }

  ** Create as `SanType.registeredId` - Accepts AsnOid or Str (value stored as Str)
  static new registeredId(Obj oid)
  {
    AsnOid := Type.find("asn1::AsnOid")
    if (AsnOid.fits(oid.typeof)) return San(SanType.registeredId, oid->oidStr)
    else if (oid is Str) return San(SanType.registeredId, (Str)oid)
    throw ArgErr("Parameter must be AsnOid or Str")
  }

  private new make(SanType type, Obj val)
  {
    this.type = type
    this.val = val
  }

  ** Convenience for creating a San from a value.
  **
  ** The 'value' may be one of the following types:
  **  - 'Str':    returns San.dnsName
  **  - 'Uri':    returns San.uri
  **  - 'AsnOid': returns San.registeredId
  **  - 'Buf':    returns San.otherName
  **  - 'IpAddr': returns San.ipAddr
  **  - 'San':    returns itself
  static new fromValue(Obj value)
  {
    if (value is Str)         return San.dnsName(value)
    else if (value is Uri)    return San.uri(value)
    else if (value is Buf)    return San.otherName(((Buf)value).toImmutable)
    else if (value is San)    return value
    else if (Type.find("asn1::AsnOid").fits(value.typeof))
      return San.registeredId(value)
    else if (Type.find("inet::IpAddr").fits(value.typeof))
      return San.ipAddr(value)
    else throw ArgErr("Unsupported value: ${value} (${value.typeof})")
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** RFC5280 Type
  const SanType type

  ** Get the value determined by the SanType:
  **  - `SanType.dnsName`:        Str
  **  - `SanType.rfc822Name`:     Str
  **  - `SanType.uri`:            Str
  **  - `SanType.registeredId`:   Str
  **  - `SanType.dirName`:        Str
  **  - `SanType.ipAddr`:         IpAddr
  **  - `SanType.otherName`:      Buf (DER-encoded SEQUENCE)
  const Obj val

  ** Get a friendly encoding using the format: {SanType.text}:{value}
  override Str toStr()
  {
    if (type == SanType.otherName) return "${type.text}:<bytes>"
    return "${type.text}:${val}"
  }

}

**************************************************************************
** SanType
**************************************************************************

enum class SanType
{
  otherName(0, "otherName"),
  rfc822Name(1, "email"),
  dnsName(2, "DNS"),
  x400Addr(3, "X400"),
  dirName(4, "dirName"),
  ediPartyName(5, "ediPartyName"),
  uri(6, "URI"),
  ipAddr(7, "IP"),
  registeredId(8, "registeredId")

  private new make(Int tagId, Str text)
  {
    this.text = text
    this.tagId = tagId
  }

  static SanType? fromTagId(Int tagId, Bool checked := true)
  {
    v := vals.find { it.tagId == tagId }
    if (v != null) return v
    if (checked) throw UnsupportedErr("Unsupported tag id: ${tagId}")
    return null
  }

  const Int tagId
  const Str text
}