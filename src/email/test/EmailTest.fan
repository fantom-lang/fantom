//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 May 08  Brian Frank  Creation
//

**
** EmailTest
**
class EmailTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Validate
//////////////////////////////////////////////////////////////////////////

  Void testValidate()
  {
    // check valid configurations
    m := makeVal; m.validate
    m = makeVal { cc = null; bcc = null }; m.validate
    m = makeVal { to = null; bcc = null }; m.validate
    m = makeVal { to = null; cc = null }; m.validate

    // check null
    Str? x := null
    EmailPart? xpart := null
    EmailPart[]? xparts := null
    verifyErr(Err#) { m = makeVal { to = null; cc = null; bcc = null }; m.validate }
    verifyErr(NullErr#) { m = makeVal { from = x }; m.validate }
    verifyErr(NullErr#) { m = makeVal { subject = x }; m.validate }
    verifyErr(NullErr#) { m = makeVal { body = xpart }; m.validate }
    verifyErr(NullErr#) { m = makeVal { body = TextPart { text = x } }; m.validate }
    verifyErr(NullErr#) { m = makeVal { body = MultiPart { parts = xparts } }; m.validate }
    verifyErr(Err#)     { m = makeVal { body = MultiPart { } }; m.validate }

    // check charset defaults to utf-8
    m = makeVal { body = TextPart { text = "x" } }
    m.validate
    verifyEq(m.body.headers["Content-Type"], "text/plain; charset=utf-8")

    // check valid 7bit us-ascii
    m = makeVal
    {
      body = TextPart
      {
        text = "x";
        headers["Content-Transfer-Encoding"] = "7bit";
        headers["Content-Type"] = "text/plain; charset=us-ascii";
      }
    };
    m.validate

    // check invalid 7bit utf-8
    verifyErr(Err#) |->|
    {
      m = makeVal
      {
        body = TextPart
        {
          text = "x";
          headers["Content-Transfer-Encoding"] = "7bit"
        }
      };
      m.validate
    }

    // check multipart boundary
    m = makeVal { body = MultiPart { parts = [TextPart{text=""}] } }
    m.validate
    verify(MimeType(m.body.headers["Content-Type"]).params["boundary"] != null)

    // check file charset
    m = makeVal { body = FilePart { file = `test.png`.toFile } }
    m.validate
    verifyEq(m.body.headers["Content-Type"], "image/png; name=\"test.png\"")
  }

  Email makeVal()
  {
    return Email
    {
      to  = ["brian@foo.com"]
      cc  = ["brian@foo.com"]
      bcc = ["brian@foo.com"]
      from = "brian@foo.com"
      subject = "foo"
      body = TextPart { text = "text" }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  static Void main()
  {
    // setup
    to   := ["x@fantom.org"]
    from := "x@fantom.org"
    mailer := SmtpClient
    {
      host     = "webmail.richweb.com"
      username = "x@fantom.org"
      password = ""
      log.level = LogLevel.debug
    }

    mailer.open

    // 7-bit plain text
    mailer.send(Email
    {
      it.to = to
      it.from = from
      it.subject = "plain text (us-ascii)"
      it.body = TextPart
      {
        headers["Content-Type"] = "text/plain; charset=us-ascii";
        headers["Content-Transfer-Encoding"] = "7bit"
        text = "this is a simple plain message\nline2\n.\nline4"
      }
    })

    // plain unicode text
    mailer.send(Email
    {
      it.to = to
      it.from = from
      it.subject = "\u00A1Hola Se\u00F1or! unicode plain text"
      it.body = TextPart { text = "[E=\u0114 B=\u03B2 m=\u1000]\n\u00A1Hola Se\u00F1or!" }
    })

    // html/plain alternative
    mailer.send(Email
    {
      it.to = to
      it.from = from
      it.subject = "html/plain alternative"
      it.body = MultiPart
      {
        headers["Content-Type"] = "multipart/alternative"
        parts =
        [
          TextPart
          {
            text = "this is bold and italics! and y=\u00ff A=\u0102!"
          },
          TextPart
          {
            headers["Content-Type"] = "text/html; charset=\"utf-8\""
            text = "this is <b>bold</b> and <i>italics</i> and y=\u00ff A=\u0102!"
          },
        ]
      }
    })

    // image attachment
    mailer.send(Email
    {
      it.to = to
      it.from = from
      it.subject = "attachment"
      it.body = MultiPart
      {
        parts = [
          TextPart { text = "\u00A1Hola Se\u00F1or! This is the body!" },
          FilePart
          {
            headers["Content-Disposition"] = "inline"
            file = `/dev/fan/doc/reddit.gif`.toFile
          }
        ]
      }
    })

    mailer.close
  }

}