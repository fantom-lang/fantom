//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Apr 2026 Ross Schwalm Creation
//

// SubjectAlternativeName ::= GeneralNames
//
// GeneralNames ::= SEQUENCE SIZE (1..MAX) OF GeneralName
//
// GeneralName ::= CHOICE {
//      otherName                 [0]  AnotherName,
//      rfc822Name                [1]  IA5String,
//      dNSName                   [2]  IA5String,
//      x400Address               [3]  ORAddress,
//      directoryName             [4]  Name,
//      ediPartyName              [5]  EDIPartyName,
//      uniformResourceIdentifier [6]  IA5String,
//      iPAddress                 [7]  OCTET STRING,
//      registeredID              [8]  OBJECT IDENTIFIER }
//
// -- AnotherName replaces OTHER-NAME ::= TYPE-IDENTIFIER, as
// -- TYPE-IDENTIFIER is not supported in the '88 ASN.1 syntax
//
// AnotherName ::= SEQUENCE {
//     type-id    OBJECT IDENTIFIER,
//     value      [0] EXPLICIT ANY DEFINED BY type-id }
//
// EDIPartyName ::= SEQUENCE {
//      nameAssigner              [0]  DirectoryString OPTIONAL,
//      partyName                 [1]  DirectoryString }
**
** SubjectAltName defines the api for a Subject Alternative Name.
**
const mixin SubjectAltName
{

  ** ASN Tag Id
  abstract Int tagId()

  ** RFC5280 Type
  abstract SubjectAltNameType type()

  ** Get the value (Str, Uri, or IpAddr)
  abstract Obj value()

}

**************************************************************************
** SubjectAltNameType
**************************************************************************

enum class SubjectAltNameType
{
  otherName("othername", 0),
  rfc822Name("email", 1),
  dNSName("DNS", 2),
  x400Address("X400", 3),
  directoryName("DirName", 4),
  ediPartyName("EdiPartyName", 5),
  uniformResourceIdentifier("URI", 6),
  iPAddress("IP Address", 7),
  registeredID("Registered ID", 8)

  private new make(Str text, Int tagId)
  {
    this.text = text
    this.tagId = tagId
  }

  static new fromTagId(Int tagId)
  {
    find(tagId) ?: throw UnsupportedErr("Unsupported tag id: ${tagId}")
  }

  static SubjectAltNameType? find(Int tagId)
  {
    vals.find { it.tagId == tagId }
  }

  const Str text
  const Int tagId
}