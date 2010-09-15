//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Dec 06  Andy Frank  Ported from Java
//

using System;
using System.Collections;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// Unit.
  /// </summary>
  public sealed class Unit : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Database
  //////////////////////////////////////////////////////////////////////////

    public static Unit fromStr(string name) { return fromStr(name, true); }
    public static Unit fromStr(string name, bool check)
    {
      lock (m_units)
      {
        Unit unit = (Unit)m_units[name];
        if (unit != null || !check) return unit;
        throw Err.make("Unit not found: " + name).val;
      }
    }

    public static List list()
    {
      lock (m_units)
      {
        Unit[] vals = new Unit[m_units.Count];
        m_units.Values.CopyTo(vals, 0);
        return new List(Sys.UnitType, vals);
      }
    }

    public static List quantities()
    {
      return m_quantityNames;
    }

    public static List quantity(string quantity)
    {
      List list = (List)m_quantities[quantity];
      if (list == null) throw Err.make("Unknown unit database quantity: " + quantity).val;
      return list;
    }

    private static List loadDatabase()
    {
      InStream input = null;
      List quantityNames = new List(Sys.StrType);
      try
      {
        // parse etc/sys/units.fog as big serialized list which contains
        // lists for each quantity (first item being the name)
        String path = "etc/sys/units.txt";
        input = Env.cur().findFile(path).@in();

        // parse each line
        string curQuantityName = null;
        List curQuantityList = null;
        string line;
        while ((line = input.readLine()) != null)
        {
          // skip comment and blank lines
          line = line.Trim();
          if (line.StartsWith("//") || line.Length == 0) continue;

          // quanity sections delimited as "-- name (dim)"
          if (line.StartsWith("--"))
          {
            if (curQuantityName != null) m_quantities[curQuantityName] = curQuantityList.toImmutable();
            curQuantityName = line.Substring(2, line.IndexOf('(')-2).Trim();
            curQuantityList = new List(Sys.UnitType);
            quantityNames.add(curQuantityName);
            continue;
          }

          // must be a unit
          try
          {
            Unit unit = Unit.define(line);
            curQuantityList.add(unit);
          }
          catch (Exception e)
          {
            System.Console.WriteLine("WARNING: Init unit in etc/sys/units.txt: " + line);
            System.Console.WriteLine("  " + e);
          }
        }
        m_quantities[curQuantityName] = curQuantityList.toImmutable();
      }
      catch (Exception e)
      {
        try { input.close(); } catch (Exception) {}
        System.Console.WriteLine("WARNING: Cannot load lib/units.txt");
        Err.dumpStack(e);
      }
      return (List)quantityNames.toImmutable();
    }

  //////////////////////////////////////////////////////////////////////////
  // Parsing
  //////////////////////////////////////////////////////////////////////////

    public static Unit define(string str)
    {
      // parse
      Unit unit = null;
      try
      {
        unit = parseUnit(str);
      }
      catch (Exception)
      {
        throw ParseErr.make("Unit", str).val;
      }

      // register
      lock (m_units)
      {
        // lookup by its ids
        for (int i=0; i<unit.m_ids.sz(); ++i)
        {
          string id = (string)unit.m_ids.get(i);
          if (m_units[id] != null) throw Err.make("Unit id is already defined: " + id).val;
        }

        // this is a new definition
        for (int i=0; i<unit.m_ids.sz(); ++i)
           m_units[(string)unit.m_ids.get(i)] = unit;
      }

      return unit;
    }

    /**
     * Parse an un-interned unit:
     *   unit := <name> [";" <symbol> [";" <dim> [";" <scale> [";" <offset>]]]]
     */
    private static Unit parseUnit(string s)
    {
      string idStrs = s;
      int c = s.IndexOf(';');
      if (c > 0) idStrs = s.Substring(0, c);
      List ids = FanStr.split(idStrs, Long.valueOf(','));
      if (c < 0) return new Unit(ids, m_dimensionless, 1, 0);

      string dim = s = s.Substring(c+1).Trim();
      c = s.IndexOf(';');
      if (c < 0) return new Unit(ids, parseDim(dim), 1, 0);

      dim = s.Substring(0, c).Trim();
      string scale = s = s.Substring(c+1).Trim();
      c = s.IndexOf(';');
      if (c < 0) return new Unit(ids, parseDim(dim), Double.parseDouble(scale), 0);

      scale = s.Substring(0, c).Trim();
      string offset = s.Substring(c+1).Trim();
      return new Unit(ids, parseDim(dim), Double.parseDouble(scale), Double.parseDouble(offset));
    }

    /**
     * Parse an dimension string and intern it:
     *   dim    := <ratio> ["*" <ratio>]*
     *   ratio  := <base> <exp>
     *   base   := "kg" | "m" | "sec" | "K" | "A" | "mol" | "cd"
     */
    private static Dimension parseDim(string s)
    {
      // handle empty string as dimensionless
      if (s.Length == 0) return m_dimensionless;

      // parse dimension
      Dimension dim = new Dimension();
      List ratios = FanStr.split(s, Long.valueOf((long)'*'), true);
      for (int i=0; i<ratios.sz(); ++i)
      {
        string r = (string)ratios.get(i);
        if (r.StartsWith("kg"))  { dim.kg  = SByte.Parse(r.Substring(2).Trim()); continue; }
        if (r.StartsWith("sec")) { dim.sec = SByte.Parse(r.Substring(3).Trim()); continue; }
        if (r.StartsWith("mol")) { dim.mol = SByte.Parse(r.Substring(3).Trim()); continue; }
        if (r.StartsWith("m"))   { dim.m   = SByte.Parse(r.Substring(1).Trim()); continue; }
        if (r.StartsWith("K"))   { dim.K   = SByte.Parse(r.Substring(1).Trim()); continue; }
        if (r.StartsWith("A"))   { dim.A   = SByte.Parse(r.Substring(1).Trim()); continue; }
        if (r.StartsWith("cd"))  { dim.cd  = SByte.Parse(r.Substring(2).Trim()); continue; }
        throw new Exception("Bad ratio '" + r + "'");
      }

      // intern
      lock (m_dims)
      {
        Dimension cached = (Dimension)m_dims[dim];
        if (cached != null) return cached;
        m_dims[dim] = dim;
        return dim;
      }
    }

    /**
     * Private constructor.
     */
    private Unit(List ids, Dimension dim, double scale, double offset)
    {
      this.m_ids    = checkIds(ids);
      this.m_dim    = dim;
      this.m_scale  = scale;
      this.m_offset = offset;
    }

    static List checkIds(List ids)
    {
      if (ids.sz() == 0) throw ParseErr.make("No unit ids defined").val;
      for (int i=0; i<ids.sz(); ++i) checkId((string)ids.get(i));
      return (List)ids.toImmutable();
    }

    static void checkId(string id)
    {
      if (id.Length == 0) throw ParseErr.make("Invalid unit id length 0").val;
      for (int i=0; i<id.Length; ++i)
      {
        int c = id[i];
        if (FanInt.isAlpha(c) || c == '_' || c == '%' || c == '/' || c > 128) continue;
        throw ParseErr.make("Invalid unit id " + id + " (invalid char '" + (char)c + "')").val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override sealed bool Equals(object obj) { return this == obj; }

    public override sealed int GetHashCode() { return toStr().GetHashCode(); }

    public override sealed long hash() { return FanObj.hash(toStr()); }

    public override sealed Type @typeof() { return Sys.UnitType; }

    public override sealed string toStr() { return (string)m_ids.last(); }

    public List ids() { return m_ids; }

    public string name() { return (string)m_ids.first(); }

    public string symbol() { return (string)m_ids.last(); }

    public double scale() { return m_scale; }

    public double offset() { return m_offset; }

    public string definition()
    {
      StringBuilder s = new StringBuilder();
      for (int i=0; i<m_ids.sz(); ++i)
      {
        if (i > 0) s.Append(", ");
        s.Append((string)m_ids.get(i));
      }
      if (m_dim != m_dimensionless)
      {
        s.Append("; ").Append(m_dim);
        if (m_scale != 1.0 || m_offset != 0.0)
        {
          s.Append("; ").Append(m_scale);
          if (m_offset != 0.0) s.Append("; ").Append(m_offset);
        }
      }
      return s.ToString();
    }

  //////////////////////////////////////////////////////////////////////////
  // Dimension
  //////////////////////////////////////////////////////////////////////////

    public long kg() { return m_dim.kg; }

    public long m() { return m_dim.m; }

    public long sec() { return m_dim.sec; }

    public long K() { return m_dim.K; }

    public long A() { return m_dim.A; }

    public long mol() { return m_dim.mol; }

    public long cd() { return m_dim.cd; }

    internal class Dimension
    {
      public override int GetHashCode()
      {
        return (kg << 28) ^ (m << 23) ^ (sec << 18) ^
               (K << 13) ^ (A << 8) ^ (mol << 3) ^ cd;
      }

      public override bool Equals(object o)
      {
        Dimension x = (Dimension)o;
        return kg == x.kg && m   == x.m   && sec == x.sec && K == x.K &&
               A  == x.A  && mol == x.mol && cd  == x.cd;
      }

      public override string ToString()
      {
        if (str == null)
        {
          StringBuilder s = new StringBuilder();
          append(s, "kg",  kg);  append(s, "m",   m);
          append(s, "sec", sec); append(s, "K",   K);
          append(s, "A",   A);   append(s, "mol", mol);
          append(s, "cd",  cd);
          str = s.ToString();
        }
        return str;
      }

      private void append(StringBuilder s, string key, int val)
      {
        if (val == 0) return;
        if (s.Length > 0) s.Append('*');
        s.Append(key).Append(val);
      }

      internal string str;
      internal sbyte kg, m, sec, K, A, mol, cd;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public double convertTo(double scalar, Unit to)
    {
      if (m_dim != to.m_dim) throw Err.make("Incovertable units: " + this + " and " + to).val;
      return ((scalar * this.m_scale + this.m_offset) - to.m_offset) / to.m_scale;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static readonly Hashtable m_units = new Hashtable(); // string name -> Unit
    private static readonly Hashtable m_dims = new Hashtable(); // Dimension -> Dimension
    private static readonly Hashtable m_quantities = new Hashtable(); // string -> List
    private static readonly List m_quantityNames;
    private static readonly Dimension m_dimensionless = new Dimension();
    static Unit()
    {
      m_dims[m_dimensionless] = m_dimensionless;
      m_quantityNames = loadDatabase();
    }

    private readonly List m_ids;
    private readonly double m_scale;
    private readonly double m_offset;
    private readonly Dimension m_dim;
  }
}