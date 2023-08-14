//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   07 Jul 2009  Andy Frank  Creation
//   25 Feb 2016  Matthew Giannini  - binary decode time zone
//   25 Apr 2023  Matthew Giannini  - Refactor for ES
//

/**
 * TimeZone
 */
class TimeZone extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(name, fullName, rules) {
    super();
    this.#name = name;
    this.#fullName = fullName;
    this.#rules = rules;
  }

  #name;
  #fullName;
  #rules;

  static #cache = {};
  static #names = [];
  static #fullNames = [];
  static #aliases = {};
  static #utc = undefined;
  static #rel = undefined;
  static #cur = undefined;
  static #defVal = undefined;

  static defVal() {
    if (TimeZone.#defVal === undefined) TimeZone.#defVal = TimeZone.#utc;
    return TimeZone.#defVal;
  }

  static listNames() {
    return List.make(Str.type$, TimeZone.#names).ro();
  }

  static listFullNames() {
    return List.make(Str.type$, TimeZone.#fullNames).ro();
  }

  static fromStr(name, checked=true) {
    // check cache first
    let tz = TimeZone.#fromCache(name);
    if (tz != null) return tz;

    // check aliases
    let target = TimeZone.#aliases[name];
    tz = TimeZone.#fromCache(target);
    if (tz != null) return tz;

    // not found
    if (checked) throw ParseErr.make("TimeZone not found: " + name);
    return null;
  }

  static utc() { 
    if (TimeZone.#utc === undefined) TimeZone.#utc = TimeZone.fromStr("UTC");
    return TimeZone.#utc; 
  }

  static rel() { 
    if (TimeZone.#rel === undefined) TimeZone.#rel = TimeZone.fromStr("Rel");
    return TimeZone.#rel; 
  }

  static cur() {
    if (TimeZone.#cur === undefined) {
      try {
        // check for explicit tz from Env.vars or fallback to local if avail
        let tz = Env.cur().vars().get("timezone");
        if (tz == null) tz = Intl.DateTimeFormat().resolvedOptions().timeZone.split("/")[1];
        if (tz == null) tz = "UTC"
        TimeZone.#cur = TimeZone.fromStr(tz);
      }
      catch (err) {
        // fallback to UTC if we get here
        console.log(Err.make(err).msg());
        TimeZone.cur = TimeZone.#utc;
        throw Err.make(err);
      }
    }

    return TimeZone.#cur;
  }

  static __fromGmtOffset(offset=0) {
    if (offset == 0)
      return TimeZone.utc();
    else
      return TimeZone.fromStr("GMT" + (offset < 0 ? "+" : "-") + Int.div(Math.abs(offset), 3600));
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  toStr() { return this.#name; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  name() { return this.#name; }

  fullName() { return this.#fullName; }

  offset(year) {
    return Duration.make(this.__rule(year).offset * Duration.nsPerSec$);
  }

  dstOffset(year) {
    const r = this.__rule(year);
    if (r.dstOffset == 0) return null;
    return Duration.make(r.dstOffset * Duration.nsPerSec$);
  }

  stdAbbr(year) { return this.__rule(year).stdAbbr; }

  dstAbbr(year) { return this.__rule(year).dstAbbr; }

  abbr(year, inDST) {
    return inDST ? this.__rule(year).dstAbbr : this.__rule(year).stdAbbr;
  }

  __rule(year) {
    // most hits should be in latest rule
    let rule = this.#rules[0];
    if (year >= rule.startYear) return rule;

    // check historical time zones
    for (let i=1; i<this.#rules.length; ++i)
      if (year >= (rule = this.#rules[i]).startYear) return rule;

    // return oldest rule
    return this.#rules[this.#rules.length-1];
  }

//////////////////////////////////////////////////////////////////////////
// DST Calculations
//////////////////////////////////////////////////////////////////////////

  /**
   * Compute the daylight savings time offset (in seconds)
   * for the specified parameters:
   *  - Rule:    the rule for a given year
   *  - mon:     month 0-11
   *  - day:     day 1-31
   *  - weekday: 0-6
   *  - time:    seconds since midnight
   */
  static __dstOffset(rule, year, mon, day, time) {
    const start = rule.dstStart;
    const end   = rule.dstEnd;

    if (start == null) return 0;

    const s = TimeZone.#compare(rule, start, year, mon, day, time);
    const e = TimeZone.#compare(rule, end,   year, mon, day, time);

    // if end month comes earlier than start month,
    // then this is dst in southern hemisphere
    if (end.mon < start.mon) {
      if (e > 0 || s <= 0) return rule.dstOffset;
    }
    else {
      if (s <= 0 && e > 0) return rule.dstOffset;
    }

    return 0;
  }

  /**
   * Compare the specified time to the dst start/end time.
   * Return -1 if x < specified time and +1 if x > specified time.
   */
  static #compare(rule, x, year, mon, day, time) {
    let c = TimeZone.#compareMonth(x, mon);
    if (c != 0) return c;

    c = TimeZone.#compareOnDay(rule, x, year, mon, day);
    if (c != 0) return c;

    return TimeZone.#compareAtTime(rule, x, time);
  }

  /**
   * Return if given date is the DstTime transition date
   */
  static __isDstDate(rule, x, year, mon, day) {
    return TimeZone.#compareMonth(x, mon) == 0 &&
           TimeZone.#compareOnDay(rule, x, year, mon, day) == 0;
  }

  /**
   * Compare month
   */
  static #compareMonth(x, mon) {
    if (x.mon < mon) return -1;
    if (x.mon > mon) return +1;
    return 0;
  }

  /**
   * Compare on day.
   *     'd'  5        the fifth of the month
   *     'l'  lastSun  the last Sunday in the month
   *     'l'  lastMon  the last Monday in the month
   *     '>'  Sun>=8   first Sunday on or after the eighth
   *     '<'  Sun<=25  last Sunday on or before the 25th (not used)
   */
  static #compareOnDay(rule, x, year, mon, day) {
    // universal atTime might push us into the previous day
    if (x.atMode == 'u' && rule.offset + x.atTime < 0)
      ++day;

    switch (x.onMode) {
      case 'd':
        if (x.onDay < day) return -1;
        if (x.onDay > day) return +1;
        return 0;

      case 'l':
        const last = DateTime.weekdayInMonth(year, Month.vals().get(mon), Weekday.vals().get(x.onWeekday), -1);
        if (last < day) return -1;
        if (last > day) return +1;
        return 0;

      case '>':
        let start = DateTime.weekdayInMonth(year, Month.vals().get(mon), Weekday.vals().get(x.onWeekday), 1);
        while (start < x.onDay) start += 7;
        if (start < day) return -1;
        if (start > day) return +1;
        return 0;

      case '<':
        let lastw = DateTime.weekdayInMonth(year, Month.vals().get(mon), Weekday.vals().get(x.onWeekday), -1);
        while (lastw > x.onDay) lastw -= 7;
        if (lastw < day) return -1;
        if (lastw > day) return +1;
        return 0;

      default:
        throw new Error('' + x.onMode);
    }
  }

  /**
   * Compare at time.
   */
  static #compareAtTime(rule, x, time) {
    let atTime = x.atTime;

    // if universal time, then we need to move atTime back to
    // local time (we might cross into the previous day)
    if (x.atMode == 'u') {
      if (rule.offset + x.atTime < 0)
        atTime = 24*60*60 + rule.offset + x.atTime;
      else
        atTime += rule.offset;
    }

    if (atTime < time) return -1;
    if (atTime > time) return +1;
    return 0;
  }

//////////////////////////////////////////////////////////////////////////
// Cache
//////////////////////////////////////////////////////////////////////////

  static __cache(fullName, encoded) {
    // this handles cases where full name has multiple slashses
    const city = fullName.split("/").reverse()[0];
    TimeZone.#cache[city] = encoded;
    TimeZone.#cache[fullName] = encoded;
    TimeZone.#names.push(city);
    TimeZone.#fullNames.push(fullName);
  }

  static #fromCache(name) {
    let entry = TimeZone.#cache[name];
    if (entry == null || entry === undefined) return null;

    // check if already decoded
    if ((typeof entry) !== 'string') return entry;

    // need to decode base64 entry into TimeZone
    const buf = Buf.fromBase64(entry);

    // decode full name
    const fullName = buf.readUtf();
    const city = fullName.split("/").reverse()[0];

    // helper for decoding DST
    const decodeDst = () => {
      const dst = new TimeZoneDstTime(
        buf.read(),   // mon
        buf.read(),   // onMode
        buf.read(),   // onWeekday
        buf.read(),   // onDay
        buf.readS4(), // atTime
        buf.read()    // atMode
      );
      return dst;
    };

    // decode rules
    let rule;
    const rules = [];
    while (buf.more()) {
      rule = new TimeZoneRule();
      rule.startYear = buf.readS2();
      rule.offset    = buf.readS4();
      rule.stdAbbr   = buf.readUtf();
      rule.dstOffset = buf.readS4();
      if (rule.dstOffset != 0) {
        rule.dstAbbr  = buf.readUtf();
        rule.dstStart = decodeDst();
        rule.dstEnd   = decodeDst();
      }
      rules.push(rule);
    }

    const tz = new TimeZone(city, fullName, rules);

    // update cache
    TimeZone.#cache[city] = tz;
    TimeZone.#cache[fullName] = tz;

    return tz;
  }

  static __alias(alias, target) {
    const parts = alias.split("/");
    TimeZone.#aliases[alias] = target;
    // if alias contains slashses, also alias the city
    if (parts.length > 1) TimeZone.#aliases[parts[parts.length-1]] = target;
  }
}

/*************************************************************************
 * Rule
 ************************************************************************/

class TimeZoneRule {
  constructor() { }
  startYear = null;  // year rule took effect
  offset = null;     // UTC offset in seconds
  stdAbbr = null;    // standard time abbreviation
  dstOffset = null;  // seconds
  dstAbbr = null;    // daylight time abbreviation
  dstStart = null;   // starting time
  dstEnd = null;     // end time
  isWallTime() { return this.dstStart.atMode == 'w'; }
}

/*************************************************************************
 * DstTime
 ************************************************************************/

class TimeZoneDstTime  {
  constructor(mon, onMode, onWeekday, onDay, atTime, atMode) {
    this.mon = mon;              // month (0-11)
    this.onMode = String.fromCharCode(onMode);  // 'd', 'l', '>', '<' (date, last, >=, and <=)
    this.onWeekday = onWeekday;  // weekday (0-6)
    this.onDay = onDay;          // weekday (0-6)
    this.atTime = atTime;        // seconds
    this.atMode = String.fromCharCode(atMode); // 'w' , 's', 'u' (wall, standard, universal)
  }

  mon;
  onMode;
  onWeekday;
  onDay;
  atTime;
  atMode;
}