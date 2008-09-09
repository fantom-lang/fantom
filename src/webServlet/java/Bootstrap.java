//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 06  Andy Frank  Creation
//
package fan.webServlet;

import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;

/**
 * Bootstrap handles bootstrapping a servlet request into the Fan env.  To
 * bootstrap a Fan Weblet in a servlet engine, use the following web.xml:
 *
 *   <web-app xmlns="http://caucho.com/ns/resin">
 *     <servlet servlet-name="boot" servlet-class="fan.webServlet.Bootstrap"/>
 *     <servlet-mapping url-pattern="*" servlet-name="boot"/>
 *   </web-app>
 */
public class Bootstrap
  extends HttpServlet
{
  public void service(HttpServletRequest req, HttpServletResponse res)
    throws ServletException, IOException
  {
    System.setProperty("fan.home", getServletContext().getRealPath("/WEB-INF/fan"));
    System.setProperty("fan.usePrecompiledOnly", "true");

    ServletEnv env = ServletEnv.make();
    env.peer.nreq = req;
    env.peer.nres = res;
    env.service();
  }
}