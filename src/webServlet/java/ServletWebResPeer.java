//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Mar 06  Andy Frank  Creation
//
package fan.webServlet;

import java.io.*;
import java.lang.reflect.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;
import fan.sys.*;
import fan.sys.List;
import fan.sys.Map;
import fan.web.*;

/**
 * ServletWebResPeer.
 */
public class ServletWebResPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer
//////////////////////////////////////////////////////////////////////////

  public static ServletWebResPeer make(ServletWebRes res)
  {
    return new ServletWebResPeer();
  }

  public void setStatus(ServletWebRes res, Int sc)
  {
    nres.setStatus((int)sc.val);
  }

  public Bool isCommitted(ServletWebRes res)
  {
    return nres.isCommitted() ? Bool.True : Bool.False;
  }

  public void commit(ServletWebRes res)
    throws IOException
  {
    Map map = res._headers;
    List keys = map.keys();
    int size  = (int)keys.size().val;

    for (int i=0; i<size; i++)
    {
      Str key = (Str)keys.get(i);
      Str val = (Str)map.get(key);
      nres.setHeader(key.val, val.val);
    }

    nres.flushBuffer();
  }

  public void sendError(ServletWebRes res, Int sc)
    throws IOException
  {
    // TODO...
    // IOErr.make(IOException e)

    sendError(res, sc, null);
  }

  public void sendError(ServletWebRes res, Int sc, Str msg)
    throws IOException
  {
    nres.sendError((int)sc.val, (msg == null) ? null : msg.val);
  }

  public HttpServletResponse nres;

}