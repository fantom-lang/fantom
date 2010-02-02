#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 May 08  Brian Frank  Creation
//   08 Sep 09  Brian Frank  Rework fandoc -> example
//

using email

**
** Sending email via SMTP
**
class Sending
{
  // configure with your real SMTP host and account info
  Str testHost   := "smtp.acme.com"
  Str testUser   := "user"
  Str testPass   := "pass"
  Str testTo     := "to@acme.com"
  Str testFrom   := "from@acme.com"
  Bool debug     := true

  SmtpClient makeClient()
  {
    c := SmtpClient
    {
      host     = testHost
      username = testUser
      password = testPass
    }
    if (debug) c.log.level = LogLevel.debug
    return c
  }

  Void main()
  {
    simpleSend
    batchSend
    htmlMultiPart
    fileAttachments
    toCcBcc
  }

  Void simpleSend()
  {
    // create simple plain text email
    email := Email
    {
      to = [testTo]
      from = testFrom
      subject = "hi"
      body = TextPart { text = "hello world" }
    }

    // configure smtp mailer and send email
    makeClient.send(email)
  }

  Void batchSend()
  {
    // open a session, send multiple emails, and guarantee close
    mailer := makeClient
    mailer.open
    try
    {
      3.times |i|
      {
        email := Email
        {
          to=[testTo]
          from=testFrom
          subject="Batch #$i"
          body=TextPart { text = "Batch body #i" }
        }
        mailer.send(email)
      }
    }
    finally mailer.close
  }

  Void htmlMultiPart()
  {
    email := Email
    {
      to = [testTo]
      from = testFrom
      subject = "html/plain alternative"
      body = MultiPart
      {
        headers["Content-Type"] = "multipart/alternative"
        parts =
        [
          // put plain text first as backup
          TextPart
          {
            text = "this is bold and italics!"
          },

          // put html part last as best alternative
          TextPart
          {
            headers["Content-Type"] = "text/html"
            text = "this is <b>bold</b> and <i>italics</i>!"
          }
        ]
      }
    }
    makeClient.send(email)
  }

  Void fileAttachments()
  {
    icons := Pod.find("icons")
    email := Email
    {
      to = [testTo]
      from = testFrom
      subject = "file attachments"
      body = MultiPart
      {
        parts =
        [
          // put body first
          TextPart
          {
            text = "\u00A1Hola Se\u00F1or! This is the body!"
          },

          // attachment 1
          FilePart
          {
            headers["Content-Disposition"] = "inline"
            file = icons.file(`/x16/sun.png`)
          },

          // attachment 2
          FilePart
          {
            headers["Content-Disposition"] = "attachment; filename=image2.jpg"
            file = icons.file(`/x16/moon.png`)
          }
        ]
      }
    }
    makeClient.send(email)
  }

  Void toCcBcc()
  {
    email := Email
    {
      to = ["alice@foo.com", "charlie@foo.com"]
      cc = ["theboss@foo.com", "bob@foo.com"]
      bcc = ["zack@foo.com"]
      from = "bob@foo.com"
      subject = "hi"
      body = TextPart { text = "hello world" }
    }

    // dump email to standard out
    echo("--- To, CC, BCC ---")
    email.encode(Env.cur.out)
  }

}




