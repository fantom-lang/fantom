//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 2023  Matthew Giannini  Creation
//

/**
 * UriScheme
 */
class UriScheme extends Obj {
  constructor() { super(); }

  static find(scheme, checked=true) {
    if (checked) throw UnresolvedErr.make(`${scheme}`);
    return null;
  }

  get(uri, base) {
    throw UnresolvedErr.make(`uri=${uri} base=${base}`);
  }
}