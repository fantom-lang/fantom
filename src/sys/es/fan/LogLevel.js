//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  03 Dec 2009  Andy Frank  Creation
//  20 Apr 2023  Matthew Giannini Refactor for ES
//

/**
 * LogLevel
 */
class LogLevel extends Enum {
  constructor(ordinal, name) {
    super();
    Enum.make$(this, ordinal, name);
  }

  static debug() { return LogLevel.vals().get(0); }
  static info() { return LogLevel.vals().get(1); }
  static warn() { return LogLevel.vals().get(2); }
  static err() { return LogLevel.vals().get(3); }
  static silent() { return LogLevel.vals().get(4); }

  static #vals = undefined;
  static vals() {
    if (LogLevel.#vals === undefined) {
      LogLevel.#vals = List.make(LogLevel.type$,
        [new LogLevel(0, "debug"), new LogLevel(1, "info"),
         new LogLevel(2, "warn"), new LogLevel(3, "err"),
         new LogLevel(4, "silent")]).toImmutable();
    }
    return LogLevel.#vals;
  }

  static fromStr(name, checked=true) {
    return Enum.doFromStr(LogLevel.type$, LogLevel.vals(), name, checked);
  }

  

}
