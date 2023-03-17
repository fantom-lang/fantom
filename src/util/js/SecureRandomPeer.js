//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2023  Matthew Giannini  Creation
//

/**
 * SecureRandom.
 */
fan.util.SecureRandom = fan.sys.Obj.$extend(fan.util.Random);

fan.util.SecureRandom.prototype.$ctor = function() {}
fan.util.SecureRandom.prototype.$typeof = function() { return fan.util.SecureRandom.$type; }