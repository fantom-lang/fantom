//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Apr 08  Brian Frank  Creation
//

using web
using fand

**
** LogStep is used log requests according to the W3C extended log file format.
**
** See [docLib::WebApp]`docLib::WebApp#logStep`
**
const class LogStep : WebAppStep
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor with it-block.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  **
  ** Output log file.
  **
  const File? file

  **
  ** Format of the log records as a string of #Fields names.
  ** See [docLib::WebApp]`docLib::WebApp#logStep`
  **
  const Str fields := "date time c-ip cs-method cs-uri-stem cs-uri-query sc-status time-taken cs(User-Agent) cs(Referer)"

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  override Void onStart(WebService service)
  {
    if (file == null)
    {
      log.error("LogStep.file not configured")
      return
    }

    // init logger
    logger.open(file)

    // write prefix
    logger.writeStr("#Remark ==========================================================================")
    logger.writeStr("#Remark " + DateTime.now.toLocale)
    logger.writeStr("#Version 1.0")
    logger.writeStr("#Software webapp::LogStep ${type.pod.version}")
    logger.writeStr("#Start-Date " + DateTime.nowUtc.toLocale("DD-MM-YYYY hh:mm:ss"))
    logger.writeStr("#Fields $fields")
  }

  override Void onStop(WebService service)
  {
    logger.stop
  }

//////////////////////////////////////////////////////////////////////////
// Service
//////////////////////////////////////////////////////////////////////////

  override Void onBeforeService(WebReq req, WebRes res)
  {
    req.stash["webapp.startTime"] = Duration.now
  }

  override Void onAfterService(WebReq req, WebRes res)
  {
    try
    {
      s := StrBuf(256)
      fields.split.each |Str field, Int i|
      {
        if (i != 0) s.add(" ")

        // lookup format method for field
        m := formatters[field]
        if (m != null)
        {
          s.add(m.call(req, res))
          return;
        }

        // cs(HeaderName)
        if (field.startsWith("cs("))
        {
          s.add(formatCsHeader(req, field[3..-2]))
          return
        }

        // unknown field name
        s.add("-")
      }

      logger.writeStr(s.toStr)
    }
    catch (Err e)
    {
      log.error("LogStep", e)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Formatters
//////////////////////////////////////////////////////////////////////////

  internal static const Str:Method formatters :=
  [
    "date":         (&formatDate).method,
    "time":         (&formatTime).method,
    "c-ip":         (&formatCIp).method,
    "c-port":       (&formatCPort).method,
    "cs-method":    (&formatCsMethod).method,
    "cs-uri":       (&formatCsUri).method,
    "cs-uri-stem":  (&formatCsUriStem).method,
    "cs-uri-query": (&formatCsUriQuery).method,
    "sc-status":    (&formatScStatus).method,
    "time-taken":   (&formatTimeTaken).method,
  ]

  internal static Str formatDate(WebReq req, WebRes res)
  {
    return DateTime.nowUtc.toLocale("DD-MM-YYYY")
  }

  internal static Str formatTime(WebReq req, WebRes res)
  {
    return DateTime.nowUtc.toLocale("hh:mm:ss")
  }

  internal static Str formatCIp(WebReq req, WebRes res)
  {
    return req.remoteAddress.numeric
  }

  internal static Str formatCPort(WebReq req, WebRes res)
  {
    return req.remotePort.toStr
  }

  internal static Str formatCsMethod(WebReq req, WebRes res)
  {
    return req.method
  }

  internal static Str formatCsUri(WebReq req, WebRes res)
  {
    return req.uri.encode
  }

  internal static Str formatCsUriStem(WebReq req, WebRes res)
  {
    return req.uri.pathOnly.encode
  }

  internal static Str formatCsUriQuery(WebReq req, WebRes res)
  {
    if (req.uri.query.isEmpty) return "-"
    return Uri.encodeQuery(req.uri.query)
  }

  internal static Str formatScStatus(WebReq req, WebRes res)
  {
    return res.statusCode.toStr
  }

  internal static Str formatTimeTaken(WebReq req, WebRes res)
  {
    d := Duration.now - req.stash["webapp.startTime"]
    return d.toMillis.toStr
  }

  internal static Str formatCsHeader(WebReq req, Str headerName)
  {
    s := req.headers[headerName]
    if (s == null || s.isEmpty) return "-"
    return "\"" + s.replace("\"", "\"\"") + "\""
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const FileLogger logger := FileLogger()

}