//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  08 Jun 2009  Andy Frank  Creation
//  25 Apr 2023  Matthew Giannini Refactor to ES
//

/**
 * Time
 */
class Time extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(hour, min, sec, ns) {
    super();
    if (hour < 0 || hour > 23)     throw ArgErr.make("hour " + hour);
    if (min < 0 || min > 59)       throw ArgErr.make("min " + min);
    if (sec < 0 || sec > 59)       throw ArgErr.make("sec " + sec);
    if (ns < 0 || ns > 999999999)  throw ArgErr.make("ns " + ns);

    this.#hour = hour;
    this.#min = min;
    this.#sec = sec;
    this.#ns = ns;
  }

  #hour;
  #min;
  #sec;
  #ns;
  
  static #defVal;
  static defVal() { 
    if (!Time.#defVal) Time.#defVal = new Time(0, 0, 0, 0);
    return Time.#defVal;
  }

  static make(hour, min, sec=0, ns=0) {
    return new Time(hour, min, sec, ns);
  }

  static now(tz=TimeZone.cur()) {
    return DateTime.makeTicks(DateTime.nowTicks(), tz).time();
  }

  static fromStr(s, checked=true) {
    try {
      const num = (x,index) => { return x.charCodeAt(index) - 48; }

      // hh:mm:ss
      const hour  = num(s, 0)*10  + num(s, 1);
      const min   = num(s, 3)*10  + num(s, 4);
      const sec   = num(s, 6)*10  + num(s, 7);

      // check separator symbols
      if (s.charAt(2) != ':' || s.charAt(5) != ':')
        throw new Error();

      // optional .FFFFFFFFF
      let i = 8;
      let ns = 0;
      let tenth = 100000000;
      const len = s.length;
      if (i < len && s.charAt(i) == '.') {
        ++i;
        while (i < len) {
          const c = s.charCodeAt(i);
          if (c < 48 || c > 57) break;
          ns += (c - 48) * tenth;
          tenth /= 10;
          ++i;
        }
      }

      // verify everything has been parsed
      if (i < s.length) throw new Error();

      // use local var to capture any exceptions
      const instance = new Time(hour, min, sec, ns);
      return instance;
    }
    catch (err) {
      if (!checked) return null;
      throw ParseErr.makeStr("Time", s);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(that) {
    if (that instanceof Time) {
      return this.#hour.valueOf() == that.#hour.valueOf() &&
            this.#min.valueOf() == that.#min.valueOf() &&
            this.#sec.valueOf() == that.#sec.valueOf() &&
            this.#ns.valueOf() == that.#ns.valueOf();
    }
    return false;
  }

  hash() { return (this.#hour << 28) ^ (this.#min << 21) ^ (this.#sec << 14) ^ this.#ns; }

  compare(that) {
    if (this.#hour.valueOf() == that.#hour.valueOf()) {
      if (this.#min.valueOf() == that.#min.valueOf()) {
        if (this.#sec.valueOf() == that.#sec.valueOf()) {
          if (this.#ns.valueOf() == that.#ns.valueOf()) return 0;
          return this.#ns < that.#ns ? -1 : +1;
        }
        return this.#sec < that.#sec ? -1 : +1;
      }
      return this.#min < that.#min ? -1 : +1;
    }
    return this.#hour < that.#hour ? -1 : +1;
  }

  toStr() { return this.toLocale("hh:mm:ss.FFFFFFFFF"); }

  

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  hour() { return this.#hour; }
  min() { return this.#min; }
  sec() { return this.#sec; }
  nanoSec() { return this.#ns; }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  toLocale(pattern=null, locale=Locale.cur()) {
    // locale specific default
    if (pattern == null) {
      const pod = Pod.find("sys");
      pattern = Env.cur().locale(pod, "time", "hh:mm:ss", locale);
    }

    return DateTimeStr.makeTime(pattern, locale, this).format();
    // why was he doing "new"
    // return new fan.sys.DateTimeStr.makeTime(pattern, locale, this).format();
  }

  static fromLocale(s, pattern, checked=true) {
    return DateTimeStr.make(pattern, null).parseTime(s, checked);
  }

//////////////////////////////////////////////////////////////////////////
// ISO 8601
//////////////////////////////////////////////////////////////////////////

  toIso() { return this.toStr(); }

  static fromIso(s, checked=true) {
    return Time.fromStr(s, checked);
  }

//////////////////////////////////////////////////////////////////////////
// Past/Future
//////////////////////////////////////////////////////////////////////////

  plus(d)  { return this.#plus(d.ticks()); }
  minus(d) { return this.#plus(-d.ticks()); }
  #plus(ticks) {
    if (ticks == 0) return this;
    if (ticks > Duration.nsPerDay$)
      throw ArgErr.make("Duration out of range: " + Duration.make(ticks));

    let newTicks = this.toDuration().ticks() + ticks;
    if (newTicks < 0) newTicks = Duration.nsPerDay$ + newTicks;
    if (newTicks >= Duration.nsPerDay$) newTicks %= Duration.nsPerDay$;
    return Time.fromDuration(Duration.make(newTicks));
  }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  static fromDuration(d) {
    let ticks = d.ticks();
    if (ticks == 0) return Time.defVal();

    if (ticks < 0 || ticks > Duration.nsPerDay$)
      throw ArgErr.make("Duration out of range: " + d);

    const hour = Int.div(ticks, Duration.nsPerHr$);  ticks %= Duration.nsPerHr$;
    const min  = Int.div(ticks, Duration.nsPerMin$); ticks %= Duration.nsPerMin$;
    const sec  = Int.div(ticks, Duration.nsPerSec$); ticks %= Duration.nsPerSec$;
    const ns   = ticks;

    return new Time(hour, min, sec, ns);
  }

  toDuration() {
    return Duration.make(this.#hour*Duration.nsPerHr$ +
                         this.#min*Duration.nsPerMin$ +
                         this.#sec*Duration.nsPerSec$ +
                         this.#ns);
  }

  toDateTime(d, tz=TimeZone.cur()) { return DateTime.__makeDT(d, this, tz); }

  toCode() {
    if (this.equals(Time.defVal())) return "Time.defVal";
    return "Time(\"" + this.toString() + "\")";
  }

  isMidnight() { return this.equals(Time.defVal()); }
}