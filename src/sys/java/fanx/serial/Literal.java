//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Aug 07  Brian Frank  Creation
//
package fanx.serial;

/**
 * Literal is implemented by sys objects which are encoded as literals.
 */
public interface Literal
{

  public void encode(ObjEncoder out);

}
