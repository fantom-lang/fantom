//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

using asn1

const class Rdn
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(AsnOid type, Str val)
  {
    this.type = type
    this.val  = val
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  const AsnOid type
  const Str val

//////////////////////////////////////////////////////////////////////////
// Rdn
//////////////////////////////////////////////////////////////////////////

  Str? shortName()
  {
    keywords.eachWhile |oid, n| { oid == this.type ? n : null }
  }

  ** Get the attribute value as an ASN.1 string type according
  ** to its specification. If the attribute type is not recognized,
  ** then encode it as a `Utf8Str`.
  AsnObj asnVal()
  {
    switch (shortName)
    {
      // PrintableStr
      case "C":
      case "DNQUALIFIER":
      case "SERIALNUMBER":
        return Asn.str(val, AsnTag.univPrintStr)
      // IA5Str
      case "DC":
      case "EMAIL":
        return Asn.str(val, AsnTag.univIa5Str)
      // Utf8
      default:
        return Asn.utf8(val)
    }
  }

  AsnSet asn()
  {
    Asn.set([Asn.seq([type, asnVal])])
  }

  override Str toStr()
  {
    name := shortName ?: type.oidStr
    return "${name}=${val}"
  }

  ** Maps attribute type "short names" to their OIDs
  const static Str:AsnOid keywords
  static
  {
    id_at := "2.5.4"
    pkcs9 := "1.2.840.113549.1.9"

    m := Str:AsnOid[:]
    m["CN"] = Asn.oid("${id_at}.3")
    m["SURNAME"] = Asn.oid("${id_at}.4")
    m["SERIALNUMBER"] = Asn.oid("${id_at}.5")
    m["C"]  = Asn.oid("${id_at}.6")
    m["L"]  = Asn.oid("${id_at}.7")
    m["S"]  = Asn.oid("${id_at}.8")
    m["ST"] = Asn.oid("${id_at}.8")
    m["STREET"] = Asn.oid("${id_at}.9")
    m["O"]  = Asn.oid("${id_at}.10")
    m["OU"] = Asn.oid("${id_at}.11")
    m["TITLE"] = Asn.oid("${id_at}.12")
    m["NAME"] = Asn.oid("${id_at}.41")
    m["GIVENNAME"] = Asn.oid("${id_at}.42")
    m["INITIALS"] = Asn.oid("${id_at}.43")
    m["GENERATIONQUALIFIER"] = Asn.oid("${id_at}.44")
    m["DNQUALIFIER"] = Asn.oid("${id_at}.46")
    m["PSEUDONYM"] = Asn.oid("${id_at}.65")
    m["DC"]  = Asn.oid("0.9.2342.19200300.100.1.25")
    m["UID"] = Asn.oid("0.9.2342.19200300.100.1.1")
    m["EMAIL"] = Asn.oid("${pkcs9}.1")
    keywords = m
  }
}
