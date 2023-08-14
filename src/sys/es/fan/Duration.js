//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Feb 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   18 Apr 2023  Matthew Giannini  Refactor to ES
//

/**
 * Duration
 */
class Duration extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(ticks) {
    super();
    this.#ticks = ticks;
  }

  #ticks;

  static #defVal;
  static defVal() { 
    if (!Duration.#defVal) Duration.#defVal = new Duration(0);
    return Duration.#defVal;
  }

  static __boot;

  static nsPerYear$  = 365*24*60*60*1000000000;
  static nsPerDay$   = 86400000000000;
  static nsPerHr$    = 3600000000000;
  static nsPerMin$   = 60000000000;
  static nsPerSec$   = 1000000000;
  static nsPerMilli$ = 1000000;
  static secPerDay$  = 86400;
  static secPerHr$   = 3600;
  static secPerMin$  = 60;

  static minVal() { return new Duration(Int.minVal()); }
  static maxVal() { return new Duration(Int.maxVal()); }
  static oneDay$() { return new Duration(Duration.nsPerDay$); }
  static oneMin$() { return new Duration(Duration.nsPerMin$); }
  static oneSec$() { return new Duration(Duration.nsPerSec$); }
  static negOneDay$() { return new Duration(-Duration.nsPerDay$); }

  static fromStr(s, checked=true) {

    //   ns:   nanoseconds  (x 1)
    //   ms:   milliseconds (x 1,000,000)
    //   sec:  seconds      (x 1,000,000,000)
    //   min:  minutes      (x 60,000,000,000)
    //   hr:   hours        (x 3,600,000,000,000)
    //   day:  days         (x 86,400,000,000,000)
    try
    {
      const len = s.length;
      const x1  = s.charAt(len-1);
      const x2  = s.charAt(len-2);
      const x3  = s.charAt(len-3);
      const dot = s.indexOf('.') > 0;

      let mult = -1;
      let suffixLen  = -1;
      switch (x1)
      {
        case 's':
          if (x2 == 'n') { mult=1; suffixLen=2; } // ns
          if (x2 == 'm') { mult=1000000; suffixLen=2; } // ms
          break;
        case 'c':
          if (x2 == 'e' && x3 == 's') { mult=1000000000; suffixLen=3; } // sec
          break;
        case 'n':
          if (x2 == 'i' && x3 == 'm') { mult=60000000000; suffixLen=3; } // min
          break;
        case 'r':
          if (x2 == 'h') { mult=3600000000000; suffixLen=2; } // hr
          break;
        case 'y':
          if (x2 == 'a' && x3 == 'd') { mult=86400000000000; suffixLen=3; } // day
          break;
      }

      if (mult < 0) throw new Error();

      s = s.substring(0, len-suffixLen);
      if (dot) {
        const num = parseFloat(s);
        if (isNaN(num)) throw new Error();
        return Duration.make(Math.floor(num*mult));
      }
      else {
        const num = Int.fromStr(s);
        return Duration.make(num*mult);
      }
    }
    catch (err) {
      if (!checked) return null;
      throw ParseErr.makeStr("Duration", s);
    }
  }

  static now() {
    const ms = new js.Date().getTime();
    return Duration.make(ms * Duration.nsPerMilli$);
  }

  static nowTicks() { return Duration.now().ticks(); }

  static boot() { return Duration.__boot; }

  static uptime() { return Duration.now().minus(Duration.boot()); }

  static make(ticks) { return new Duration(ticks); }

  static makeMillis(ms) { return Duration.make(ms*1000000); }

  static makeSec(secs) { return Duration.make(secs*1000000000); }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(that) {
    if (that instanceof Duration)
      return this.#ticks == that.#ticks;
    else
      return false;
  }

  compare(that) {
    if (this.#ticks < that.#ticks) return -1;
    if (this.#ticks == that.#ticks) return 0;
    return +1;
  }

  hash() { return (this.#ticks ^ (this.#ticks >> 32)); }

  ticks() { return this.#ticks; }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  negate() { return Duration.make(-this.#ticks); }
  plus(x) { return Duration.make(this.#ticks + x.#ticks); }
  minus(x) { return Duration.make(this.#ticks - x.#ticks); }
  mult(x) { return Duration.make(this.#ticks * x); }
  multFloat(x) { return Duration.make(this.#ticks * x); }
  div(x) { return Duration.make(this.#ticks / x); }
  divFloat(x) { return Duration.make(this.#ticks / x); }

  floor(accuracy) {
    if (this.#ticks % accuracy.#ticks == 0) return this;
    return Duration.make(this.#ticks - (this.#ticks % accuracy.#ticks));
  }

  min(that) {
    if (this.#ticks <= that.#ticks) return this;
    else return that;
  }

  max(that) {
    if (this.#ticks >= that.#ticks) return this;
    else return that;
  }

  clamp(min, max) {
    if (this.#ticks < min.#ticks) return min;
    if (this.#ticks > max.#ticks) return max;
    return this;
  }

  abs() {
    if (this.#ticks >= 0) return this;
    return Duration.make(-this.#ticks);
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  toStr() {
    if (this.#ticks == 0) return "0ns";

    // if clean millisecond boundary
    const ns = this.#ticks;
    if (ns % Duration.nsPerMilli$ == 0)
    {
      if (ns % Duration.nsPerDay$ == 0) return ns/Duration.nsPerDay$ + "day";
      if (ns % Duration.nsPerHr$  == 0) return ns/Duration.nsPerHr$  + "hr";
      if (ns % Duration.nsPerMin$ == 0) return ns/Duration.nsPerMin$ + "min";
      if (ns % Duration.nsPerSec$ == 0) return ns/Duration.nsPerSec$ + "sec";
      return ns/Duration.nsPerMilli$ + "ms";
    }

    // return in nanoseconds
    return ns + "ns";
  }

  literalEncode$(out) { out.w(this.toStr()); }

  toCode() { return this.toStr(); }

  toMillis() { return Math.floor(this.#ticks / Duration.nsPerMilli$); }
  toSec() { return Math.floor(this.#ticks / Duration.nsPerSec$); }
  toMin() { return Math.floor(this.#ticks / Duration.nsPerMin$); }
  toHour() { return Math.floor(this.#ticks / Duration.nsPerHr$); }
  toDay() { return Math.floor(this.#ticks / Duration.nsPerDay$); }


//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  toLocale() {
    let ticks = this.#ticks;
    const pod = Duration.type$.pod();
    const env = Env.cur();
    const locale = Locale.cur();

    if (ticks < 0) return "-" + Duration.make(-ticks).toLocale();

    // less than 1000ns Xns
    if (ticks < 1000) return ticks + env.locale(pod, "nsAbbr", "ns",  locale);

    // less than 2ms X.XXXms
    if (ticks < 2*Duration.nsPerMilli$) {
      let s = '';
      const ms = Math.floor(ticks/Duration.nsPerMilli$);
      const us = Math.floor((ticks - ms*Duration.nsPerMilli$)/1000);
      s += ms;
      s += '.';
      if (us < 100) s += '0';
      if (us < 10)  s += '0';
      s += us;
      if (s.charAt(s.length-1) == '0') s = s.substring(0, s.length-1);
      if (s.charAt(s.length-1) == '0') s = s.substring(0, s.length-1);
      s += env.locale(pod, "msAbbr", "ms",  locale);;
      return s;
    }

    // less than 2sec Xms
    if (ticks < 2*Duration.nsPerSec$)
      return Math.floor(ticks/Duration.nsPerMilli$) + env.locale(pod, "msAbbr", "ms",  locale);

    // less than 2min Xsec
    if (ticks < 1*Duration.nsPerMin$)
      return Math.floor(ticks/Duration.nsPerSec$) + env.locale(pod, "secAbbr", "sec",  locale);

    // [Xdays] [Xhr] Xmin Xsec
    const days = Math.floor(ticks/Duration.nsPerDay$); ticks -= days*Duration.nsPerDay$;
    const hr   = Math.floor(ticks/Duration.nsPerHr$);  ticks -= hr*Duration.nsPerHr$;
    const min  = Math.floor(ticks/Duration.nsPerMin$); ticks -= min*Duration.nsPerMin$;
    const sec  = Math.floor(ticks/Duration.nsPerSec$);

    let s = '';
    if (days > 0) s += days + (days == 1 ? env.locale(pod, "dayAbbr", "day", locale) : env.locale(pod, "daysAbbr", "days", locale)) + " ";
    if (hr  > 0) s += hr  + env.locale(pod, "hourAbbr", "hr",  locale) + " ";
    if (min > 0) s += min + env.locale(pod, "minAbbr",  "min", locale) + " ";
    if (sec > 0) s += sec + env.locale(pod, "secAbbr",  "sec", locale) + " ";
    return s.substring(0, s.length-1);
  }

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

  toIso() {
    let s = '';
    let ticks = this.#ticks;
    if (ticks == 0) return "PT0S";

    if (ticks < 0) s += '-';
    s += 'P';
    const abs  = Math.abs(ticks);
    let sec  = Math.floor(abs / Duration.nsPerSec$);
    const frac = abs % Duration.nsPerSec$;

    // days
    if (sec > Duration.secPerDay$) {
      s += Math.floor(sec/Duration.secPerDay$) + 'D';
      sec = sec % Duration.secPerDay$;
    }
    if (sec == 0 && frac == 0) return s;
    s += 'T';

    // hours, minutes
    if (sec > Duration.secPerHr$) {
      s += Math.floor(sec/Duration.secPerHr$) + 'H';
      sec = sec % Duration.secPerHr$;
    }
    if (sec > Duration.secPerMin$) {
      s += Math.floor(sec/Duration.secPerMin$) + 'M';
      sec = sec % Duration.secPerMin$;
    }
    if (sec == 0 && frac == 0) return s;

    // seconds and fractional seconds
    s += sec;
    if (frac != 0) {
      s += '.';
      for (let i=10; i<=100000000; i*=10) if (frac < i) s += '0';
      s += frac;
      let x = s.length-1;
      while (s.charAt(x) == '0') x--;
      s = s.substring(0, x+1);
    }
    s += 'S';
    return s;
  }

  static fromIso(s, checked=true)
  {
    try
    {
      let ticks = 0;
      let neg = false;
      const p = new IsoParser(s);

      // check for negative
      if (p.cur == 45) { neg = true; p.consume(); }
      else if (p.cur == 43) { p.consume(); }

      // next char must be P
      p.consume(80);
      if (p.cur == -1) throw new Error();

      // D
      let num = 0;
      if (p.cur != 84) {
        num = p.num();
        p.consume(68);
        ticks += num * Duration.nsPerDay$;
        if (p.cur == -1) return Duration.make(ticks);
      }

      // next char must be T
      p.consume(84);
      if (p.cur == -1) throw new Error();
      num = p.num();

      // H
      if (num >= 0 && p.cur == 72) {
        p.consume();
        ticks += num * Duration.nsPerHr$;
        num = p.num();
      }

      // M
      if (num >= 0 && p.cur == 77) {
        p.consume();
        ticks += num * Duration.nsPerMin$;
        num = p.num();
      }

      // S
      if (num >= 0 && p.cur == 83 || p.cur == 46) {
        ticks += num * Duration.nsPerSec$;
        if (p.cur == 46) { p.consume(); ticks += p.frac(); }
        p.consume(83);
      }

      // verify we parsed everything
      if (p.cur != -1) throw new Error();

      // negate if necessary and return result
      if (neg) ticks = -ticks;
      return Duration.make(ticks);
    }
    catch (err) {
      if (!checked) return null;
      throw ParseErr.makeStr("ISO 8601 Duration",  s);
    }
  }
}

class IsoParser {

  constructor(s) {
    this.s = s;
    this.cur = s.charCodeAt(0);
    this.off = 0;
    this.curIsDigit = false;
  }

  s;
  cur;
  off;
  curIsDigit;

  num() {
    if (!this.curIsDigit && this.cur != -1 && this.cur != 46)
      throw new Error();
    let num = 0;
    while (this.curIsDigit) {
      num = num*10 + this.digit();
      this.consume();
    }
    return num;
  }

  frac() {
    // get up to nine decimal places as milliseconds within a fraction
    let ticks = 0;
    for (let i=100000000; i>=0; i/=10)
    {
      if (!this.curIsDigit) break;
      ticks += this.digit() * i;
      this.consume();
    }
    return ticks;
  }

  digit() { return this.cur - 48; }

  consume(ch) {
    if (ch != null && this.cur != ch) throw new Error();

    this.off++;
    if (this.off < this.s.length) {
      this.cur = this.s.charCodeAt(this.off);
      this.curIsDigit = 48 <= this.cur && this.cur <= 57;
    }
    else
    {
      this.cur = -1;
      this.curIsDigit = false;
    }
  }
}
