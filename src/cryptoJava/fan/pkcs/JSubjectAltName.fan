//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Apr 2026 Ross Schwalm Creation
//

using asn1
using crypto
using inet

const class JSubjectAltName : SubjectAltName
{
  static new fromTag(Int tagId, Obj value)
  {
    type := SubjectAltNameType.fromTagId(tagId)

    // For otherName (tag 0), parse DER-encoded bytes using BerReader
    if (tagId == 0 && value is Buf)
    {
      value = parseOtherName((Buf)value)
    }

    // For registeredID (tag 8), handle string conversion
    if (tagId == 8 && value is Str)
    {
      oidStr := (Str)value
      if (oidStr.isEmpty)
        throw Err("Empty OID string for registeredID")
      value = Asn.oid(oidStr)
    }

    return make(value, type)
  }

  **
  ** Parse otherName from DER-encoded bytes using Fantom's ASN.1 library
  ** AnotherName ::= SEQUENCE {
  **     type-id    OBJECT IDENTIFIER,
  **     value      [0] EXPLICIT ANY DEFINED BY type-id }
  **
  internal static Map parseOtherName(Buf der)
  {
    reader := BerReader(der.in)
    seq := reader.readObj as AsnSeq

    if (seq.vals.size < 2)
      throw Err("Invalid otherName SEQUENCE - expected 2 elements, got ${seq.vals.size}")

    // First element is the OID
    oid := seq.vals[0] as AsnOid
    if (oid == null)
      throw Err("Expected OID as first element of otherName, got ${seq.vals[0].typeof}")

    // Second element is [0] EXPLICIT containing the value
    contextTag := seq.vals[1]

    // Extract the value - it's wrapped in a context tag
    valueStr := extractOtherNameValue(contextTag)

    return ["oid": oid.oidStr, "value": valueStr]
  }

  **
  ** Extract the actual value from the context-tagged wrapper
  **
  private static Str extractOtherNameValue(AsnObj contextTag)
  {
    // The value is typically a string type (UTF8String, IA5String, etc.)
    // wrapped in the context tag [0]

    // If it's AsnBin (raw/unknown type), decode it
    if (contextTag is AsnBin)
    {
      bin := (AsnBin)contextTag
      // Read the inner content - use buf() to get a safe copy
      innerReader := BerReader(bin.buf.in)
      innerObj := innerReader.readObj
      return extractStringValue(innerObj)
    }

    // Try to extract as string directly
    return extractStringValue(contextTag)
  }

  **
  ** Extract string value from various ASN.1 types
  **
  private static Str extractStringValue(AsnObj obj)
  {
    val := obj.val

    // Handle direct string values
    if (val is Str) return ((Str)val).trim

    // Handle Buf - read as string
    if (val is Buf) return ((Buf)val).readAllStr.trim

    // Handle Unsafe wrapper (common in ASN.1)
    if (val.typeof.name == "Unsafe")
    {
      unsafe := (Unsafe)val
      innerVal := unsafe.val
      if (innerVal is Str) return ((Str)innerVal).trim
      if (innerVal is Buf) return ((Buf)innerVal).readAllStr.trim
    }

    // Fallback
    return val.toStr.trim
  }

  static new fromValue(Obj value, SubjectAltNameType? type := null)
  {
    if (type == null)
    {
      if (value is Str)         return make(value, SubjectAltNameType.dNSName)
      else if (value is Uri)    return make(value, SubjectAltNameType.uniformResourceIdentifier)
      else if (value is IpAddr) return make(value, SubjectAltNameType.iPAddress)
      else if (value is AsnOid) return make(value, SubjectAltNameType.registeredID)
      else if (value is Map)
      {
        if (((Map)value).containsKey("type")) return fromMap((Map)value)
        return make(value, SubjectAltNameType.otherName)
      }
      else if (value is SubjectAltName) return make(value, ((SubjectAltName)value).type)
      else throw UnsupportedErr("Unsupported value: ${value} (${value.typeof})")
    }

    return make(value, type)
  }

  private static new fromMap(Map san)
  {
    value := san["value"]
    type := (SubjectAltNameType)san["type"]

    return make(value, type)
  }

  new make(Obj value, SubjectAltNameType type)
  {
    this.type = type

    if (value is AsnOid)
    {
      this.oidValue = (AsnOid)value
      this.strValue = ((AsnOid)value).oidStr
      this.mapValue = null
      this.ipValue = null
    }
    else if (value is Map)
    {
      this.mapValue = (Map)value
      this.strValue = mapValue.toStr
      this.oidValue = null
      this.ipValue = null
    }
    else if (value is IpAddr)
    {
      // Store IP address directly
      this.ipValue = (IpAddr)value
      this.strValue = value.toStr
      this.oidValue = null
      this.mapValue = null
    }
    else if (value is SubjectAltName)
    {
      this.strValue = ((SubjectAltName)value).value.toStr
      this.oidValue = null
      this.mapValue = null
      this.ipValue = null
    }
    else
    {
      this.strValue = value.toStr
      this.oidValue = null
      this.mapValue = null
      this.ipValue = null
    }
  }

  ** RFC5280 Type
  override const SubjectAltNameType type
  private const Str strValue
  private const AsnOid? oidValue
  private const Map? mapValue
  private const IpAddr? ipValue

  ** ASN Tag Id
  override Int tagId() { type.tagId }

  ** ASN encode the SubjectAltName
  AsnObj asn()
  {
    switch(tagId)
    {
      case 0:   // otherName - SEQUENCE { type-id OID, value [0] EXPLICIT ANY }
        throw UnsupportedErr("Encoding otherName to ASN.1 not supported")

      case 1:   // rfc822Name - email address (IA5String)
      case 2:   // dNSName (IA5String)
      case 6:   // uniformResourceIdentifier (IA5String)
        return Asn.tag(AsnTag.context(tagId).implicit).str(strValue, AsnTag.univIa5Str)

      case 4:   // directoryName - Name (DN)
        // Encoding directoryName requires [4] EXPLICIT tag wrapping of the DN's ASN.1 structure.
        throw UnsupportedErr("Encoding directoryName to ASN.1 not supported")

      case 7:   // iPAddress (OCTET STRING)
        return Asn.tag(AsnTag.context(tagId).implicit).octets(IpAddr(strValue).bytes)

      case 8:   // registeredID (OBJECT IDENTIFIER)
        oidStr := oidValue != null ? oidValue.oidStr : strValue
        return Asn.tag(AsnTag.context(tagId).implicit).oid(oidStr)

      case 3:   // x400Address - not implemented
      case 5:   // ediPartyName - not implemented
      default:
        throw UnsupportedErr("Encoding SubjectAltNameType ${type.text} (tag ${tagId}) not supported")
    }

    throw Err("Unknown tagId: ${tagId}")
  }

  ** Get the value (Str, Uri, IpAddr, AsnOid, or Map)
  **
  ** Returns:
  **  - Map for otherName (with "oid" and "value" keys)
  **  - Str for rfc822Name, dNSName, directoryName
  **  - Uri for uniformResourceIdentifier
  **  - IpAddr for iPAddress
  **  - AsnOid for registeredID
  once override Obj value()
  {
    switch(tagId)
    {
      case 0:   // otherName - return Map
        return mapValue ?: ["oid": "unknown", "value": strValue]

      case 1:   // rfc822Name - return email as Str
      case 2:   // dNSName - return hostname as Str
      case 4:   // directoryName - return DN as Str
        return strValue

      case 6:   // uniformResourceIdentifier - return as Uri
        return Uri.fromStr(strValue)

      case 7:   // iPAddress - return as IpAddr
        if (ipValue != null) return ipValue
        if (strValue.isEmpty) throw Err("Empty IP address string")
        return IpAddr(strValue)

      case 8:   // registeredID - return as AsnOid
        return oidValue ?: Asn.oid(strValue)

      default:
        return strValue
    }
  }

  ** Get a friendly encoding using the format: {SubjectAltNameType.text}:{value}
  override Str toStr()
  {
    val := formatValue
    return "${type.text}:${val}"
  }

  private Str formatValue()
  {
    switch(tagId)
    {
      case 0:   // otherName - format as "oid=X, value=Y"
        if (mapValue != null)
        {
          oid := mapValue["oid"] ?: "unknown"
          val := mapValue["value"]
          if (val != null)
          {
            // Value should already be extracted as a string by parseOtherName
            valStr := val is Str ? val : val.toStr
            return "oid=${oid}, value=${valStr}"
          }
          return "oid=${oid}"
        }
        return strValue

      case 1:   // rfc822Name - email address
      case 2:   // dNSName - hostname
      case 6:   // uniformResourceIdentifier - URI
        return strValue

      case 4:   // directoryName - DN
        // DN is decoded in SubjectAltNames class
        return strValue

      case 7:   // iPAddress
        return ipValue?.toStr ?: strValue

      case 8:   // registeredID - OID
        // Just return the OID string without ASN.1 tag info
        if (oidValue != null)
          return oidValue.oidStr
        return strValue

      default:
        return strValue
    }
  }
}
