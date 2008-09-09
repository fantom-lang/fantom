//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jan 06  Brian Frank  Creation
//
package fanx.tools;

import java.io.File;
import fan.sys.*;
import fanx.fcode.*;

/**
 * Fan Disassembler
 */
public class Fanp
{

  public static void main(String[] args)
    throws Exception
  {
    new Fan().execute("compiler::Fanp.main", args);
  }

}