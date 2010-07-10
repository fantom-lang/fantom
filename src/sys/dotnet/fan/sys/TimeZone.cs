//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Oct 07  Andy Frank   Creation
//  21 Jul 09  Brian Frank  Upgrade to more compressed format
//

using System;
using System.Collections;
using System.IO;
using Fanx.Util;

namespace Fan.Sys
{
  /// <summary>
  /// TimeZone.
  /// </summary>
  public sealed class TimeZone : FanObj
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
      for (int i=0; i<indexNames.Length; ++i)
      {
        string prefix = prefixes[indexPrefixes[i] & 0xff];
        string name = indexNames[i];
        if (prefix.Length != 0) name = prefix + "/" + name;
        list.add(name);
      }
      return list.ro();
    }

    public static TimeZone fromStr(string name) { return fromStr(name, true); }
    public static TimeZone fromStr(string name, bool check)
    {
      // check cache first
      TimeZone tz;
      lock (cache)
      {
        tz = (TimeZone)cache[name];
        if (tz != null) return tz;
      }

      // try to load from database
      try
      {
        tz = loadTimeZone(name);
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
        throw IOErr.make("Cannot load from timezone database: " + name).val;
      }

      // if found, then cache and return
      if (tz != null)
      {
        lock (cache)
        {
          cache[tz.m_name] = tz;
          cache[tz.m_fullName] = tz;
          return tz;
        }
      }

      // not found
      if (check) throw ParseErr.make("TimeZone not found: " + name).val;
      return null;
    }

    public static TimeZone defVal()
    {
      return m_utc;
    }

    public static TimeZone utc()
    {
      return m_utc;
    }

    public static TimeZone rel()
    {
      return m_rel;
    }

    public static TimeZone cur()
    {
      return m_cur;
    }

    /** Get generic GMT offset where offset is in seconds */
    public static TimeZone fromGmtOffset(int offset)
    {
      if (offset == 0)
        return TimeZone.utc();
      else
        return TimeZone.fromStr("GMT" + (offset < 0 ? ("+" + (-offset/3600)) : ("-" + (offset/3600))));
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override string toStr() { return m_name; }

    public override Type @typeof() { return Sys.TimeZoneType; }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public string name()
    {
      return m_name;
    }

    public string fullName()
    {
      return m_fullName;
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

    public string stdAbbr(long year)
    {
      return rule((int)year).stdAbbr;
    }

    public string dstAbbr(long year)
    {
      return rule((int)year).dstAbbr;
    }

    public string abbr(int year, bool inDST)
    {
      return inDST ? rule(year).dstAbbr : rule(year).stdAbbr;
    }

    internal Rule rule(int year)
    {
      // most hits should be in latest rule
      Rule rule = rules[0];
      if (year >= rule.startYear) return rule;

      // check historical time zones
      for (int i=1; i<rules.Length; ++i)
        if (year >= (rule = rules[i]).startYear) return rule;

      // return oldest rule
      return rules[rules.Length-1];
    }

    // This is mostly for testing right.
//    java.util.TimeZone java()
//    {
//      return java.util.TimeZone.getTimeZone(name.val);
//    }

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

    /// <summary>
    /// Load the name and file offset list from file into memory.
    /// </summary>
    static void loadIndex()
    {
      DataReader reader = new DataReader(new BufferedStream(dbFile.OpenRead()));
      try
      {
        // check magic "fantz 02"
        long magic = reader.ReadLong();
        if (magic != 0x66616e747a203032L)
          throw new IOException("Invalid magic 0x" + magic.ToString("X").ToLower());
        reader.ReadUTF();

        // load prefixes
        int numPrefixes = reader.ReadByte();
        prefixes = new string[numPrefixes];
        for (int i=0; i<numPrefixes; ++i)
          prefixes[i] = reader.ReadUTF();

        // load the zones and verify in sort order
        int num = reader.ReadUnsignedShort();
        indexPrefixes = new byte[num];
        indexNames    = new string[num];
        indexOffsets  = new int[num];
        for (int i=0; i<num; ++i)
        {
          indexPrefixes[i] = reader.ReadByte();
          indexNames[i]    = reader.ReadUTF();
          indexOffsets[i]  = reader.ReadInt();
          if (i != 0 && String.Compare(indexNames[i-1], indexNames[i], StringComparison.Ordinal) >= 0)
            throw new IOException("Index not sorted");
        }
      }
      finally
      {
        reader.Close();
      }
    }

    /// <summary>
    /// Find the specified name in the index and load a time zone
    /// definition.  If the name is not found then return null.
    /// </summary>
    static TimeZone loadTimeZone(string x)
    {
      string name = x;
      int slash = x.LastIndexOf('/');
      if (slash > 0) name = name.Substring(slash+1);

      // find index, which maps the file offset
      // TODO: why doesn't BinarySearch work?
      // int ix = Array.BinarySearch(indexNames, name);
      int ix = -1;
      for (int i=0; i<indexNames.Length; ++i)
        if (name == indexNames[i]) { ix = i; break; }
      if (ix < 0) return null;

      // map full name
      string fullName = name;
      string prefix = prefixes[indexPrefixes[ix] & 0xff];
      if (prefix.Length != 0) fullName = prefix + "/" + name;
      if (slash > 0 && x != fullName) return null;

      // create time zone instance
      TimeZone tz = new TimeZone();
      tz.m_name      = name;
      tz.m_fullName  = fullName;

      // read time zone definition from database file
      FileStream f = dbFile.OpenRead();
      DataReader d = new DataReader(f);
      try
      {
        f.Seek(indexOffsets[ix], SeekOrigin.Begin);
        int numRules  = d.ReadUnsignedShort();
        tz.rules = new Rule[numRules];
        for (int i=0; i<numRules; ++i)
        {
          Rule r = tz.rules[i] = new Rule();
          r.startYear = d.ReadUnsignedShort();
          r.offset    = d.ReadInt();
          r.stdAbbr   = d.ReadUTF();
          r.dstOffset = d.ReadInt();
          if (r.dstOffset == 0) continue;
          r.dstAbbr   = d.ReadUTF();
          r.dstStart  = loadDstTime(d);
          r.dstEnd    = loadDstTime(d);
          if (i != 0 && tz.rules[i-1].startYear <= r.startYear)
            throw new IOException("TimeZone rules not sorted: " + name);
        }
      }
      finally
      {
        f.Close();
      }
      return tz;
    }

    /*
    static void loadIndex()
    {
      DataReader reader = new DataReader(new BufferedStream(dbFile.OpenRead()));
      try
      {
        // check magic "fantz 01"
        long magic = reader.ReadLong();
        if (magic != 0x66616e747a203031L)
          throw new IOException("Invalid magic 0x" + magic.ToString("X").ToLower());
        reader.ReadUTF();

        // load the name/offset pairs and verify in sort order
        int num = reader.ReadInt();
        indexNames   = new string[num];
        indexTypes   = new byte[num];
        indexOffsets = new int[num];
        for (int i=0; i<num; ++i)
        {
          indexNames[i]   = reader.ReadUTF();
          indexTypes[i]   = (byte)reader.ReadByte();
          indexOffsets[i] = reader.ReadInt();
          if (i != 0 && String.Compare(indexNames[i-1], indexNames[i], StringComparison.Ordinal) >= 0)
            throw new IOException("Index not sorted");
        }
      }
      finally
      {
        reader.Close();
      }
    }

    static TimeZone loadTimeZone(string name)
    {
      // find index, which maps the file offset
      int ix = Array.BinarySearch(indexNames, name);
      if (ix < 0) return null;
      int seekOffset = indexOffsets[ix];

      // create time zone instance
      TimeZone tz = new TimeZone();
      tz.m_name = name;

      // read time zone definition from database file
      FileStream f = dbFile.OpenRead();
      DataReader d = new DataReader(f);
      try
      {
        f.Seek(seekOffset, SeekOrigin.Begin);
        tz.m_name     = d.ReadUTF();
        tz.m_fullName = d.ReadUTF();
        int numRules  = d.ReadUnsignedShort();
        tz.rules = new Rule[numRules];
        for (int i=0; i<numRules; ++i)
        {
          Rule r = tz.rules[i] = new Rule();
          r.startYear = d.ReadUnsignedShort();
          r.offset    = d.ReadInt();
          r.stdAbbr   = d.ReadUTF();
          r.dstOffset = d.ReadInt();
          if (r.dstOffset == 0) continue;
          r.dstAbbr   = d.ReadUTF();
          r.dstStart  = loadDstTime(d);
          r.dstEnd    = loadDstTime(d);
          if (i != 0 && tz.rules[i-1].startYear <= r.startYear)
            throw new IOException("TimeZone rules not sorted: " + name);
        }
      }
      finally
      {
        f.Close();
      }
      return tz;
    }
    */

    static DstTime loadDstTime(DataReader d)
    {
      DstTime t = new DstTime();
      t.mon       = d.ReadByte();
      t.onMode    = d.ReadByte();
      t.onWeekday = d.ReadByte();
      t.onDay     = d.ReadByte();
      t.atTime    = d.ReadInt();
      t.atMode    = d.ReadByte();
      return t;
    }

  //////////////////////////////////////////////////////////////////////////
  // DST Calculations
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Compute the daylight savings time offset (in seconds)
    /// for the specified parameters:
    ///  - Rule:    the rule for a given year
    ///  - mon:     month 0-11
    ///  - day:     day 1-31
    ///  - weekday: 0-6
    ///  - time:    seconds since midnight
    /// </summary>
    internal static int dstOffset(Rule rule, int year, int mon, int day, int time)
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

    /// <summary>
    /// Compare the specified time to the dst start/end time.
    /// Return -1 if x < specified time and +1 if x > specified time.
    /// </summary>
    static int compare(Rule rule, DstTime x, int year, int mon, int day, int time)
    {
      int c = compareMonth(x, mon);
      if (c != 0) return c;

      c = compareOnDay(rule, x, year, mon, day);
      if (c != 0) return c;

      return compareAtTime(rule, x, time);
    }

    /// <summary>
    /// Compare month
    /// </summary>
    static int compareMonth(DstTime x, int mon)
    {
      if (x.mon < mon) return -1;
      if (x.mon > mon) return +1;
      return 0;
    }

    /// <summary>
    /// Compare on day.
    ///     'd'  5        the fifth of the month
    ///     'l'  lastSun  the last Sunday in the month
    ///     'l'  lastMon  the last Monday in the month
    ///     '>'  Sun>=8   first Sunday on or after the eighth
    ///     '<'  Sun<=25  last Sunday on or before the 25th (not used)
    /// </summary>
    static int compareOnDay(Rule rule, DstTime x, int year, int mon, int day)
    {
      // universal atTime might push us into the previous day
      if (x.atMode == 'u' && rule.offset + x.atTime < 0)
        ++day;

      switch (x.onMode)
      {
        case (byte)'d':
          if (x.onDay < day) return -1;
          if (x.onDay > day) return +1;
          return 0;

        case (byte)'l':
          int last = DateTime.weekdayInMonth(year, mon, x.onWeekday, -1);
          if (last < day) return -1;
          if (last > day) return +1;
          return 0;

        case (byte)'>':
          int start = DateTime.weekdayInMonth(year, mon, x.onWeekday, 1);
          while (start < x.onDay) start += 7;
          if (start < day) return -1;
          if (start > day) return +1;
          return 0;

        default:
          throw new Exception(""+(char)x.onMode);
      }
    }

    /// <summary>
    /// Compare at time.
    /// </summary>
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

    internal class Rule
    {
      /// <summary>
      /// Return if this rule is wall time based.  We take a shortcut
      /// and assume that both start/end both use the same atMode - right
      /// now (2007) it appears this is a valid assumption with the
      /// single obscure exception being "Pacific/Tongatapu"
      /// </summary>
      public bool isWallTime() { return dstStart.atMode == 'w'; }

      public int startYear;     // year rule took effect
      public int offset;        // UTC offset in seconds
      public string stdAbbr;    // standard time abbreviation
      public int dstOffset;     // seconds
      public string dstAbbr;    // daylight time abbreviation
      public DstTime dstStart;  // starting time
      public DstTime dstEnd;    // end time
    }

    internal class DstTime
    {
      public byte mon;          // month (0-11)
      public byte onMode;       // 'd', 'l', '>', '<' (date, last, >=, and <=)
      public byte onWeekday;    // weekday (0-6)
      public byte onDay;        // weekday (0-6)
      public int  atTime;       // seconds
      public byte atMode;       // 'w' , 's', 'u' (wall, standard, universal)
    }

  //////////////////////////////////////////////////////////////////////////
  // Database Index
  //////////////////////////////////////////////////////////////////////////

    static FileInfo dbFile = new FileInfo(Sys.m_homeDir + "/etc/sys/timezones.ftz");
    static string[] prefixes = new string[0];
    static byte[] indexPrefixes = new byte[0];
    static string[] indexNames = new string[0];
    static int[] indexOffsets  = new int[0];

    static Hashtable cache = new Hashtable(); // string -> TimeZone
    internal static TimeZone m_utc;
    internal static TimeZone m_rel;
    internal static TimeZone m_cur = null;

    static TimeZone()
    {
      try
      {
        loadIndex();
      }
      catch (Exception e)
      {
        System.Console.WriteLine("ERROR: Cannot load timezone database");
        Err.dumpStack(e);
      }

      try
      {
        m_utc = fromStr("Etc/UTC");
      }
      catch (Exception e)
      {
        System.Console.WriteLine("ERROR: Cannot init UTC timezone");
        Err.dumpStack(e);

        m_utc = loadFallback("Etc/UTC", "UTC");
      }

      try
      {
        m_rel = fromStr("Etc/Rel");
      }
      catch (Exception e)
      {
        System.Console.WriteLine("ERROR: Cannot init Rel timezone");
        Err.dumpStack(e);

        m_rel = loadFallback("Etc/Rel", "Rel");
      }

      try
      {
        // first check system property
        string sysProp = (string)Env.cur().vars().get("fan.timezone");
        if (sysProp != null)
        {
          m_cur = fromStr(sysProp);
        }

        // we assume Java default uses Olson name
        else
        {
          // TODO - no clue how to auto map this yet
          //cur = fromStr(java.util.TimeZone.getDefault().getID());
          m_cur = fromStr("America/New_York");
        }
      }
      catch (Exception e)
      {
        System.Console.WriteLine("ERROR: Cannot init current timezone");
        Err.dumpStack(e);

        m_cur = m_utc;
      }
    }

    private static TimeZone loadFallback(string fullName, string name)
    {
      TimeZone tz = new TimeZone();
      tz.m_name = name;
      tz.m_fullName = fullName;
      tz.rules = new Rule[] { new Rule() };
      return tz;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private string m_name;       // time zone identifer
    private string m_fullName;   // identifer in zoneinfo database
    private Rule[] rules;     // reverse sorted by year

  }
}