//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Mar 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   18 Apr 2023  Andy Frank  Refactor for ES
//

/**
 * Weekday
 */
class Weekday extends Enum {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(ordinal, name) { 
    super();
    Enum.make$(this, ordinal, name);
    this.#localeAbbrKey = name + "Abbr";
    this.#localeFullKey = name + "Full";
  }

  #localeAbbrKey;
  #localeFullKey;

  static sun() { return Weekday.vals().get(0); }
  static mon() { return Weekday.vals().get(1); }
  static tue() { return Weekday.vals().get(2); }
  static wed() { return Weekday.vals().get(3); }
  static thu() { return Weekday.vals().get(4); }
  static fri() { return Weekday.vals().get(5); }
  static sat() { return Weekday.vals().get(6); }

  static #vals = undefined;
  static vals() {
    if (Weekday.#vals === undefined) {
      Weekday.#vals = List.make(Weekday.type$,
        [new Weekday(0, "sun"), new Weekday(1, "mon"), new Weekday(2, "tue"),
         new Weekday(3, "wed"), new Weekday(4, "thu"), new Weekday(5, "fri"),
         new Weekday(6, "sat")]).toImmutable();
    }
    return Weekday.#vals;
  }

  static #localeVals = [];

  static fromStr(name, checked=true) {
    return Enum.doFromStr(Weekday.type$, Weekday.vals(), name, checked);
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  increment() { return Weekday.vals().get((this.ordinal()+1) % 7); }

  decrement() {
    const arr = Weekday.vals();
    return this.ordinal() == 0 ? arr.get(6) : arr.get(this.ordinal()-1);
  }

  toLocale(pattern=null, locale=Locale.cur()) {
    if (pattern == null) return this.__abbr(locale);
    if (Str.isEveryChar(pattern, 87)) // 'W'
    {
      switch (pattern.length) {
        case 3: return this.__abbr(locale);
        case 4: return this.__full(locale);
      }
    }
    throw ArgErr.make("Invalid pattern: " + pattern);
  }

  localeAbbr() { return this.__abbr(Locale.cur()); }
  __abbr(locale) {
    const pod = Pod.find("sys");
    return Env.cur().locale(pod, this.#localeAbbrKey, this.name(), locale);
  }

  localeFull() { return this.__full(Locale.cur()); }
  __full(locale) {
    const pod = Pod.find("sys");
    return Env.cur().locale(pod, this.#localeFullKey, this.name(), locale);
  }

  static localeStartOfWeek() {
    const locale = Locale.cur();
    const pod = Pod.find("sys");
    return Weekday.fromStr(Env.cur().locale(pod, "weekdayStart", "sun", locale));
  }

  static localeVals() {
    const start = Weekday.localeStartOfWeek();
    let list = Weekday.#localeVals[start.ordinal()];
    if (list == null) {
      list = List.make(Weekday.type$);
      for (let i=0; i<7; ++i)
        list.add(Weekday.vals().get((i + start.ordinal()) % 7));
      Weekday.#localeVals[start.ordinal()] = list.toImmutable();
    }
    return list;
  }
}