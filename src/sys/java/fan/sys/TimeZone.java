//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Sep 07  Brian Frank  Creation
//   21 Jul 09  Brian Frank  Upgrade to more compressed format
//
package fan.sys;

import java.io.BufferedInputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map.Entry;

/**
 * TimeZone
 */
public final class TimeZone
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  public static List listNames()
  {
    return new List(Sys.StrType, indexNames).ro();
  }

  public static List listFullNames()
  {
    List list = new List(Sys.StrType);
    for (int i=0; i<indexNames.length; ++i)
    {
      String prefix = prefixes[indexPrefixes[i] & 0xff];
      String name = indexNames[i];
      if (prefix.length() != 0) name = prefix + "/" + name;
      list.add(name);
    }
    return list.ro();
  }

  public static TimeZone fromStr(String name) { return fromStr(name, true); }
  public static TimeZone fromStr(String name, boolean checked)
  {
    // check cache first
    TimeZone tz;
    synchronized (cache)
    {
      tz = (TimeZone)cache.get(name);
      if (tz != null) return tz;
    }

    // try to load from database
    try
    {
      tz = loadTimeZone(name);
    }
    catch (Exception e)
    {
      e.printStackTrace();
      throw IOErr.make("Cannot load from timezone database: " + name).val;
    }

    // if not found, check aliases
    if (tz == null)
    {
      if (aliases == null) loadAliases();
      String alias = (String)aliases.get(name);
      if (alias != null)
      {
        tz = fromStr(alias);  // better be found
        synchronized (cache)
        {
          cache.put(name, tz);
          return tz;
        }
      }
    }

    // if found, then cache and return
    if (tz != null)
    {
      synchronized (cache)
      {
        cache.put(tz.name, tz);
        cache.put(tz.fullName, tz);
        return tz;
      }
    }

    // not found
    if (checked) throw ParseErr.make("TimeZone not found: " + name).val;
    return null;
  }

  public static TimeZone defVal()
  {
    return utc;
  }

  public static TimeZone utc()
  {
    return utc;
  }

  public static TimeZone rel()
  {
    return rel;
  }

  public static TimeZone cur()
  {
    return cur;
  }

  /** Get generic GMT offset where offset is in seconds */
  static TimeZone fromGmtOffset(int offset)
  {
    if (offset == 0)
      return TimeZone.utc();
    else
      return TimeZone.fromStr("GMT" + (offset < 0 ? "+" : "-") + Math.abs(offset)/3600);
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public String toStr() { return name; }

  public Type typeof() { return Sys.TimeZoneType; }

  public Object trap(String name, List args)
  {
    // private undocumented access
    if (name.equals("rules")) return rules();
    return super.trap(name, args);
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public String name()
  {
    return name;
  }

  public String fullName()
  {
    return fullName;
  }

  public Duration offset(long year)
  {
    return Duration.make(rule((int)year).offset * Duration.nsPerSec);
  }

  public Duration dstOffset(long year)
  {
    Rule r = rule((int)year);
    if (r.dstOffset == 0) return null;
    return Duration.make(r.dstOffset * Duration.nsPerSec);
  }

  public String stdAbbr(long year)
  {
    return rule((int)year).stdAbbr;
  }

  public String dstAbbr(long year)
  {
    return rule((int)year).dstAbbr;
  }

  public String abbr(int year, boolean inDST)
  {
    return inDST ? rule(year).dstAbbr : rule(year).stdAbbr;
  }

  final Rule rule(int year)
  {
    // most hits should be in latest rule
    Rule rule = rules[0];
    if (year >= rule.startYear) return rule;

    // check historical time zones
    for (int i=1; i<rules.length; ++i)
      if (year >= (rule = rules[i]).startYear) return rule;

    // return oldest rule
    return rules[rules.length-1];
  }

  private List rules()
  {
    List list = new List(Sys.ObjType);
    for (int i=0; i<rules.length; i++)
    {
      Rule r = rules[i];
      Map map = new Map(Sys.StrType, Sys.ObjType);
      map.set("startYear", Long.valueOf(r.startYear));
      map.set("offset",    Long.valueOf(r.offset));
      map.set("stdAbbr",   r.stdAbbr);
      map.set("dstOffset", Long.valueOf(r.dstOffset));
      if (r.dstOffset != 0)
      {
        map.set("dstAbbr",  r.dstAbbr);
        map.set("dstStart", dstTimeToMap(r.dstStart));
        map.set("dstEnd",   dstTimeToMap(r.dstEnd));
      }
      list.add(map);
    }
    return list;
  }

  private Map dstTimeToMap(DstTime t)
  {
    Map map = new Map(Sys.StrType, Sys.ObjType);
    map.set("mon",       Long.valueOf(t.mon));
    map.set("onMode",    Long.valueOf(t.onMode));
    map.set("onWeekday", Long.valueOf(t.onWeekday));
    map.set("onDay",     Long.valueOf(t.onDay));
    map.set("atTime",    Long.valueOf(t.atTime));
    map.set("atMode",    Long.valueOf(t.atMode));
    return map;
  }

//////////////////////////////////////////////////////////////////////////
// Aliases
//////////////////////////////////////////////////////////////////////////

  private static void loadAliases()
  {
    HashMap map = new HashMap();
    try
    {
      // read as props file
      String sep = java.io.File.separator;
      Map props = Env.cur().props(Sys.sysPod, Uri.fromStr("timezone-aliases.props"), Duration.Zero);

      // map both simple name and full names to aliases map
      Iterator it = props.pairsIterator();
      while (it.hasNext())
      {
        Entry e = (Entry)it.next();
        String key = (String)e.getKey();
        String val = (String)e.getValue();

        // map by fullName
        map.put(key, val);

        // map by simple name
        int slash = key.lastIndexOf('/');
        if (slash > 0) map.put(key.substring(slash+1), val);
      }
    }
    catch (Throwable e)
    {
      System.out.println("ERROR: Cannot read timezone-aliases.props");
      e.printStackTrace();
    }

    // save to field and force memory barrier sync
    TimeZone.aliases = map;
    synchronized(TimeZone.aliases) {}
  }

//////////////////////////////////////////////////////////////////////////
// Database
//////////////////////////////////////////////////////////////////////////

  //
  // TimeZone database format:
  //
  // ftz
  // {
  //   u8    magic ("fantz 02")
  //   utf   summary
  //   u1    numPrefixes
  //   utf[] prefixes
  //   u2    numIndexItems
  //   indexItems[]   // sorted by name
  //   {
  //     u1   prefix id
  //     utf  name
  //     u4   fileOffset
  //   }
  //   timeZones[]
  //   {
  //     u2   numRules
  //     rules[]
  //     {
  //       u2   startYear
  //       i4   utcOffset (seconds)
  //       utf  stdAbbr
  //       i4   dstOffset (seconds); if zero rest is skipped
  //       [
  //         utf       dstAbbr
  //         dstTime   dstStart
  //         dstTime   dstEnd
  //       ]
  //     }
  //   }
  //
  //   dstTime
  //   {
  //     u1  month
  //     u1  onMode 'd', 'l', '>', '<' (date, last, >=, and <=)
  //     u1  onWeekday (0-6)
  //     u1  onDay
  //     i4  atTime (seconds)
  //     u1  atMode 'w' , 's', 'u' (wall, standad, universal)
  //   }
  //
  //  The timezone database is generated by the "/adm/buildtz.fan"
  //  script.  Refer to the "zic.8.txt" source file the code
  //  distribution of the Olson database to further describe
  //  model of the original data.
  //

  /**
   * Load the name and file offset list from file into memory.
   */
  static void loadIndex()
    throws IOException
  {
    DataInputStream in = openDb();
    try
    {
      // check magic "fantz 02"
      long magic = in.readLong();
      if (magic != 0x66616e747a203032L)
        throw new java.io.IOException("Invalid magic 0x" + Long.toHexString(magic));
      String summary = in.readUTF();

      // load prefixes
      int numPrefixes = in.readUnsignedByte();
      prefixes = new String[numPrefixes];
      for (int i=0; i<numPrefixes; ++i)
        prefixes[i] = in.readUTF();

      // load the zones and verify in sort order
      int num = in.readUnsignedShort();
      indexPrefixes = new byte[num];
      indexNames    = new String[num];
      indexOffsets  = new int[num];
      for (int i=0; i<num; ++i)
      {
        indexPrefixes[i] = (byte)in.read();
        indexNames[i]    = in.readUTF();
        indexOffsets[i]  = in.readInt();
        if (i != 0 && indexNames[i-1].compareTo(indexNames[i]) >= 0)
          throw new java.io.IOException("Index not sorted");
      }
    }
    finally
    {
      in.close();
    }
  }

  /**
   * Find the specified name in the index and load a time zone
   * definition.  If the name is not found then return null.
   */
  static TimeZone loadTimeZone(String x)
    throws IOException
  {
    String name = x;
    int slash = x.lastIndexOf('/');
    if (slash > 0) name = name.substring(slash+1);

    // find index, which maps the file offset
    int ix = Arrays.binarySearch(indexNames, name);
    if (ix < 0) return null;

    // map full name
    String fullName = name;
    String prefix = prefixes[indexPrefixes[ix] & 0xff];
    if (prefix.length() != 0) fullName = prefix + "/" + name;
    if (slash > 0 && !x.equals(fullName)) return null;

    // create time zone instance
    TimeZone tz = new TimeZone();
    tz.name      = name;
    tz.fullName  = fullName;

    // read time zone definition from database file
    DataInputStream in = openDb();
    try
    {
      in.skip(indexOffsets[ix]);
      int numRules = in.readUnsignedShort();
      tz.rules = new Rule[numRules];
      for (int i=0; i<numRules; ++i)
      {
        Rule r = tz.rules[i] = new Rule();
        r.startYear = in.readUnsignedShort();
        r.offset    = in.readInt();
        r.stdAbbr   = in.readUTF();
        r.dstOffset = in.readInt();
        if (r.dstOffset == 0) continue;
        r.dstAbbr   = in.readUTF();
        r.dstStart  = loadDstTime(in);
        r.dstEnd    = loadDstTime(in);
        if (i != 0 && tz.rules[i-1].startYear <= r.startYear)
          throw new java.io.IOException("TimeZone rules not sorted: " + name);
      }
    }
    finally
    {
      in.close();
    }
    return tz;
  }

  static DstTime loadDstTime(DataInputStream in)
    throws IOException
  {
    DstTime t = new DstTime();
    t.mon       = in.readByte();
    t.onMode    = in.readByte();
    t.onWeekday = in.readByte();
    t.onDay     = in.readByte();
    t.atTime    = in.readInt();
    t.atMode    = in.readByte();
    return t;
  }

  static DataInputStream openDb()
    throws IOException
  {
    if (Sys.isJarDist)
      return new DataInputStream(new BufferedInputStream(
        TimeZone.class.getClassLoader().getResourceAsStream("etc/sys/timezones.ftz")));
    else
      return new DataInputStream(new BufferedInputStream(
        new FileInputStream(dbFile)));
  }

//////////////////////////////////////////////////////////////////////////
// Java
//////////////////////////////////////////////////////////////////////////

  // This is mostly for testing right.
  java.util.TimeZone java()
  {
    return java.util.TimeZone.getTimeZone(name);
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
  static int dstOffset(Rule rule, int year, int mon, int day, int time)
  {
    DstTime start = rule.dstStart;
    DstTime end   = rule.dstEnd;

    if (start == null) return 0;

    int s = compare(rule, start, year, mon, day, time);
    int e = compare(rule, end,   year, mon, day, time);

    // if end month comes earlier than start month,
    // then this is dst in southern hemisphere
    if (end.mon < start.mon)
    {
      if (e > 0 || s <= 0) return rule.dstOffset;
    }
    else
    {
      if (s <= 0 && e > 0) return rule.dstOffset;
    }

    return 0;
  }

  /**
   * Compare the specified time to the dst start/end time.
   * Return -1 if x < specified time and +1 if x > specified time.
   */
  static int compare(Rule rule, DstTime x, int year, int mon, int day, int time)
  {
    int c = compareMonth(x, mon);
    if (c != 0) return c;

    c = compareOnDay(rule, x, year, mon, day);
    if (c != 0) return c;

    return compareAtTime(rule, x, time);
  }

  /**
   * Compare month
   */
  static int compareMonth(DstTime x, int mon)
  {
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
  static int compareOnDay(Rule rule, DstTime x, int year, int mon, int day)
  {
    // universal atTime might push us into the previous day
    if (x.atMode == 'u' && rule.offset + x.atTime < 0)
      ++day;

    switch (x.onMode)
    {
      case 'd':
        if (x.onDay < day) return -1;
        if (x.onDay > day) return +1;
        return 0;

      case 'l':
        int last = DateTime.weekdayInMonth(year, mon, x.onWeekday, -1);
        if (last < day) return -1;
        if (last > day) return +1;
        return 0;

      case '>':
        int start = DateTime.weekdayInMonth(year, mon, x.onWeekday, 1);
        while (start < x.onDay) start += 7;
        if (start < day) return -1;
        if (start > day) return +1;
        return 0;

      default:
        throw new IllegalStateException(""+(char)x.onMode);
    }
  }

  /**
   * Compare at time.
   */
  static int compareAtTime(Rule rule, DstTime x, int time)
  {
    int atTime = x.atTime;

    // if universal time, then we need to move atTime back to
    // local time (we might cross into the previous day)
    if (x.atMode == 'u')
    {
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
// Rule
//////////////////////////////////////////////////////////////////////////

  static class Rule
  {
    /**
     * Return if this rule is wall time based.  We take a shortcut
     * and assume that both start/end both use the same atMode - right
     * now (2007) it appears this is a valid assumption with the
     * single obscure exception being "Pacific/Tongatapu"
     */
    boolean isWallTime() { return dstStart.atMode == 'w'; }

    int startYear;     // year rule took effect
    int offset;        // UTC offset in seconds
    String stdAbbr;    // standard time abbreviation
    int dstOffset;     // seconds
    String dstAbbr;    // daylight time abbreviation
    DstTime dstStart;  // starting time
    DstTime dstEnd;    // end time
  }

  static class DstTime
  {
    byte  mon;          // month (0-11)
    byte  onMode;       // 'd', 'l', '>', '<' (date, last, >=, and <=)
    byte  onWeekday;    // weekday (0-6)
    byte  onDay;        // weekday (0-6)
    int   atTime;       // seconds
    byte  atMode;       // 'w' , 's', 'u' (wall, standard, universal)
  }

//////////////////////////////////////////////////////////////////////////
// Database Index
//////////////////////////////////////////////////////////////////////////

  static File dbFile = new File(Sys.homeDir, "etc" + java.io.File.separator + "sys" + java.io.File.separator + "timezones.ftz");
  static String[] prefixes    = new String[0];
  static byte[] indexPrefixes = new byte[0];
  static String[] indexNames  = new String[0];
  static int[] indexOffsets   = new int[0];
  static HashMap aliases;

  static HashMap cache = new HashMap(); // String -> TimeZone
  static TimeZone utc;
  static TimeZone rel;
  static TimeZone cur;

//////////////////////////////////////////////////////////////////////////
// Initialization
//////////////////////////////////////////////////////////////////////////

  static
  {
    try
    {
      loadIndex();
    }
    catch (Throwable e)
    {
      System.out.println("ERROR: Cannot load timezone database");
      e.printStackTrace();
    }

    try
    {
      utc = fromStr("Etc/UTC");
    }
    catch (Throwable e)
    {
      System.out.println("ERROR: Cannot init UTC timezone");
      e.printStackTrace();
      utc = loadFallback("Etc/UTC", "UTC");
    }

    try
    {
      rel = fromStr("Etc/Rel");
    }
    catch (Throwable e)
    {
      System.out.println("ERROR: Cannot init Rel timezone");
      e.printStackTrace();
      rel = loadFallback("Etc/Rel", "Rel");
    }

    try
    {
      // first check system property, otherwise try to use Java timezone
      String sysProp = Sys.sysConfig("timezone");
      if (sysProp != null)
      {
        cur = fromStr(sysProp);
      }
      else
      {
        cur = fromJava(java.util.TimeZone.getDefault().getID());
      }
    }
    catch (Throwable e)
    {
      System.out.println("ERROR: Cannot init current timezone");
      e.printStackTrace();

      cur = utc;
    }
  }

  private static TimeZone loadFallback(String fullName, String name)
  {
    TimeZone tz = new TimeZone();
    tz.name = name;
    tz.fullName = fullName;
    tz.rules = new Rule[] { new Rule() };
    return tz;
  }

  /**
   * Convert a Java timezone name to a Olson timezone identifier
   * as used by Fan.  For Windows and OS X, Java reports the timezone
   * correctly.  However Unix variants all seems to do things a bit
   * differently and do it wrong.  Instead of reporting a real timezone,
   * many Unix variants report a GMT offset (which doesn't map to a
   * political region's DST rules).
   */
  public static TimeZone fromJava(String javatz)
  {
    // handle various UTC (we haven't seen all these, but just to be safe)
    if (javatz.equals("GMT0")) return utc;
    if (javatz.equals("GMT+00:00")) return utc;
    if (javatz.equals("GMT-00:00")) return utc;

    // Solarsis and many Linux distros seem to use
    // use GMT+/-hh:mm which we map to Etc
    if (javatz.startsWith("GMT"))
    {
      if (javatz.endsWith(":00")) javatz = javatz.substring(0, javatz.length()-3);
      if (javatz.startsWith("GMT-0")) javatz = "GMT-" + javatz.substring(5);
      if (javatz.startsWith("GMT+0")) javatz = "GMT+" + javatz.substring(5);
      return fromStr(javatz);
    }

    // we've had reports that Ubuntu uses timezone names
    // deprecated back in 1993, but handle some of the common ones
    if (javatz.equals("US/Eastern"))  return fromStr("New_York");
    if (javatz.equals("US/Central"))  return fromStr("Chicago");
    if (javatz.equals("US/Mountain")) return fromStr("Denver");
    if (javatz.equals("US/Pacific"))  return fromStr("Los_Angeles");
    if (javatz.equals("US/Arizona"))  return fromStr("Phoenix");

    // assume we have an actual timezone or throw exception
    return fromStr(javatz);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private String name;        // time zone identifer
  private String fullName;    // identifer in zoneinfo database
  private Rule[] rules;    // reverse sorted by year

}