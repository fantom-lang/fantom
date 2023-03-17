//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2023  Matthew Giannini  Creation
//

/**
 * SeededRandom.
 */
fan.util.SeededRandom = fan.sys.Obj.$extend(fan.util.Random);

fan.util.SeededRandom.prototype.$ctor = function() {}
fan.util.SeededRandom.prototype.$typeof = function() { return fan.util.SeededRandom.$type; }