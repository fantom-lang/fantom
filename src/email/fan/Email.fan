//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Apr 08  Brian Frank  Creation
//

using inet

**
** Email models a top level MIME message.
**
** See [pod doc]`pod-doc` and [examples]`examples::email-sending`.
**
@Serializable
class Email
{

  **
  ** Unique identifier for message (auto-generated).
  **
  Str msgId := "<${DateTime.now.ticks/1ms.ticks}.${Buf.random(4).toHex}@${IpAddr.local.hostname}>"

  **
  ** From email address.
  **
  Str? from

  **
  ** List of "to" email addresses.
  **
  Str[]? to

  **
  ** List of "cc" email addresses.
  **
  Str[]? cc

  **
  ** List of "bcc" email addresses.
  **
  Str[]? bcc

  **
  ** Subject of the email.  This string can be any Unicode
  ** and is automatically translated into an encoded word.
  **
  Str subject := ""

  **
  ** Body of the email - typically an instance of `TextPart`
  ** or `MultiPart`.
  **
  EmailPart? body

  **
  ** Return the aggregation of `to`, `cc`, and `bcc`.
  **
  Str[] recipients()
  {
    acc := Str[,]
    if (to != null) acc.addAll(to)
    if (cc != null) acc.addAll(cc)
    if (bcc != null) acc.addAll(bcc)
    return acc
  }

  **
  ** Validate this email message - throw Err if not configured correctly.
  **
  virtual Void validate()
  {
    if ((to == null || to.isEmpty) &&
        (cc == null || cc.isEmpty) &&
        (bcc == null || bcc.isEmpty)) throw Err("no recipients")
    if ((Obj?)from == null) throw NullErr("from is null")
    if ((Obj?)body == null) throw NullErr("body is null")
    body.validate
  }

  **
  ** Encode as a MIME message according to RFC 822.
  **
  virtual Void encode(OutStream out)
  {
    out.print("Message-ID: $msgId\r\n")
    out.print("From: $from\r\n")
    if (to != null && !to.isEmpty) out.print("To: " + to.join(",") + "\r\n")
    if (cc != null && !cc.isEmpty) out.print("Cc: " + cc.join(",") + "\r\n")
    out.print("Subject: " + MimeUtil.toEncodedWord(subject) + "\r\n")
    out.print("Date: ${DateTime.now.toHttpStr}\r\n")
    out.print("MIME-Version: 1.0\r\n")
    body.encode(out)
    out.print("\r\n.\r\n")
    out.flush
  }

}