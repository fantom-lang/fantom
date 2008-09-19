//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Sep 07  Brian Frank  Creation
//

namespace Fanx.Serial
{
  /// <summary>
  /// Literal is implemented by sys objects which are encoded as literals.
  /// </summary>
  public interface Literal
  {

    void encode(ObjEncoder @out);

  }
}
