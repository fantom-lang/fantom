//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   17 Apr 2023  Andy Frank  Refactor for ES
//

/**
 * Month
 */
class Month extends Enum {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(ordinal, name, quarter) {
    super();
    Enum.make$(this, ordinal, name);
    this.#quarter = quarter;
    this.#localeAbbrKey = `${name}Abbr`
    this.#localeFullKey = `${name}Full`
  }

  #quarter;
  __quarter() { return this.#quarter; }

  #localeAbbrKey;
  #localeFullKey;

  static jan() { return Month.vals().get(0); }
  static feb() { return Month.vals().get(1); }
  static mar() { return Month.vals().get(2); }
  static apr() { return Month.vals().get(3); }
  static may() { return Month.vals().get(4); }
  static jun() { return Month.vals().get(5); }
  static jul() { return Month.vals().get(6); }
  static aug() { return Month.vals().get(7); }
  static sep() { return Month.vals().get(8); }
  static oct() { return Month.vals().get(9); }
  static nov() { return Month.vals().get(10); }
  static dec() { return Month.vals().get(11); }

  static #vals = undefined;
  static vals() {
    if (Month.#vals === undefined) {
      Month.#vals = List.make(Month.type$,
        [new Month(0, "jan", 1), new Month(1, "feb", 1), new Month(2, "mar", 1),
         new Month(3, "apr", 2), new Month(4, "may", 2), new Month(5, "jun", 2),
         new Month(6, "jul", 3), new Month(7, "aug", 3), new Month(8, "sep", 3),
         new Month(9, "oct", 4), new Month(10, "nov", 4), new Month(11, "dec", 4)]).toImmutable();
    }
    return Month.#vals;
  }

  static fromStr(name, checked=true) {
    return Enum.doFromStr(Month.type$, Month.vals(), name, checked);
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  increment() { return Month.vals().get((this.ordinal()+1) % 12); }

  decrement() {
    const arr = Month.vals();
    return this.ordinal() == 0 ? arr.get(11) : arr.get(this.ordinal()-1);
  }

  numDays(year) { return DateTime.__numDaysInMonth(year, this.ordinal()); }

  toLocale(pattern=null, locale=Locale.cur()) {
    if (pattern == null) return this.__abbr(locale);
    if (Str.isEveryChar(pattern, 77)) // 'M'
    {
      switch (pattern.length)
      {
        case 1: return ""+(this.ordinal()+1);
        case 2: return this.ordinal() < 9 ? "0" + (this.ordinal()+1) : ""+(this.ordinal()+1);
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
}