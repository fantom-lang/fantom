//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 2010  Andy Frank  Creation
//   25 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * RegexMatcher.
 */
class RegexMatcher extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(regexp, source, str) {
    super();
    this.#regexp = regexp;
    this.#source = source;
    this.#str = str + "";
    this.#match = null;
    this.#regexpForMatching = undefined;
    this.#wasMatch = null;
  }

  #regexp;
  #source;
  #str;
  #match;
  #regexpForMatching;
  #wasMatch;

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(that) { return this === that; }

  toStr() { return this.#source; }

  

//////////////////////////////////////////////////////////////////////////
// Matching
//////////////////////////////////////////////////////////////////////////

  matches() {
    if (!this.#regexpForMatching)
      this.#regexpForMatching = RegexMatcher.#recompile(this.#regexp, true);
    this.#match = this.#regexpForMatching.exec(this.#str);
    this.#wasMatch = this.#match != null && this.#match[0].length === this.#str.length;
    return this.#wasMatch;
  }

  find() {
    if (!this.#regexpForMatching)
      this.#regexpForMatching = RegexMatcher.#recompile(this.#regexp, true);
    this.#match = this.#regexpForMatching.exec(this.#str);
    this.#wasMatch = this.#match != null;
    return this.#wasMatch;
  }

//////////////////////////////////////////////////////////////////////////
// Replace
//////////////////////////////////////////////////////////////////////////

  replaceFirst(replacement) {
    return this.#str.replace(RegexMatcher.#recompile(this.#regexp, false), replacement);
  }

  replaceAll(replacement) {
    return this.#str.replace(RegexMatcher.#recompile(this.#regexp, true), replacement);
  }

//////////////////////////////////////////////////////////////////////////
// Group
//////////////////////////////////////////////////////////////////////////

  groupCount() {
    if (!this.#wasMatch)
      return 0;
    return this.#match.length - 1;
  }

  group(group=0) {
    if (!this.#wasMatch)
      throw Err.make("No match found");
    if (group < 0 || group > this.groupCount())
      throw IndexErr.make(group);
    return this.#match[group];
  }

  start(group=0) {
    if (!this.#wasMatch)
      throw Err.make("No match found");
    if (group < 0 || group > this.groupCount())
      throw IndexErr.make(group);
    if (group === 0)
      return this.#match.index;
    throw UnsupportedErr.make("Not implemented in javascript");
  }

  end(group=0) {
    if (!this.#wasMatch)
      throw Err.make("No match found");
    if (group < 0 || group > this.groupCount())
      throw IndexErr.make(group);
    if (group === 0)
      return this.#match.index + this.#match[group].length;
    throw UnsupportedErr.make("Not implemented in javascript");
  }

//////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////

  static #recompile(regexp, global) {
    let flags = global ? "g" : "";
    if (regexp.ignoreCase) flags += "i";
    if (regexp.multiline)  flags += "m";
    if (regexp.unicode)    flags += "u";
    return new RegExp(regexp.source, flags);
  }
}