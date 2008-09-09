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
import fan.sys.Type;
import fan.web.*;

/**
 * ServletEnvPeer.
 */
public class ServletEnvPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer
//////////////////////////////////////////////////////////////////////////

  public static ServletEnvPeer make(ServletEnv env)
  {
    return new ServletEnvPeer();
  }

  public Uri prefixUri(ServletEnv env)
  {
    //return Str.make(getServletContext().getContextPath()).toUri();
    return Str.make("/fandoc/").toUri();
  }

  public Str product(ServletEnv env)
  {
    //return Str.make(getServletContext().getServerInfo());
    return Str.make("todo");
  }

  public void service(ServletEnv env)
    throws Exception
  {
    InputStream nin = nreq.getInputStream();
    OutputStream nout = nres.getOutputStream();

    SysInStream in = new SysInStream(nin);
    WebSysOutStream out = new WebSysOutStream(nout);

    ServletWebReq req = ServletWebReq.make(env, in);
    ServletWebRes res = ServletWebRes.make(env, out);
    res.peer.nres = nres;

    // copy req
    String uri = nreq.getRequestURI();
    String pre = "/fandoc/"; //request.getContextPath();
    String suf = nreq.getRequestURI().substring(pre.length());
    String qs  = nreq.getQueryString();
    if (qs != null)
    {
      uri += "?" + qs;
      suf += "?" + qs;
    }

    req._method(Str.make("GET"));
    req._uri(Str.make(uri).toUri());
    req._prefixUri(Str.make(pre).toUri());
    req._suffixUri(Str.make(suf).toUri());
    Enumeration headers = nreq.getHeaderNames();
    while (headers.hasMoreElements())
    {
      String name  = (String)headers.nextElement();
      String value = nreq.getHeader(name);
      req._headers.set(Str.make(name), Str.make(value));
    }

    // cache req/res
    fan.sys.Thread.locals().set(Str.make("web.req"), req);
    fan.sys.Thread.locals().set(Str.make("web.res"), res);

    // hard code fandoc::FandocWeblet for now
    Pod pod = Pod.find("fandoc", true, null);
    Type type = pod.findType("FandocWeblet", true);
    Class cls = type.emit();

    java.lang.reflect.Method m = cls.getMethod("make");
    Weblet weblet = (Weblet)m.invoke(cls);
    weblet.service();

    // cleanup
    nin.close();
    nout.flush();
    nout.close();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public HttpServletRequest nreq;
  public HttpServletResponse nres;

}