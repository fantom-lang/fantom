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
      lock (m_byId)
      {
        Unit unit = (Unit)m_byId[name];
        if (unit != null || !check) return unit;
        throw Err.make("Unit not found: " + name).val;
      }
    }

    public static List list()
    {
      lock (m_list)
      {
        return m_list.dup().ro();
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
      lock (m_byId)
      {
        // lookup by its ids
        for (int i=0; i<unit.m_ids.sz(); ++i)
        {
          string id = (string)unit.m_ids.get(i);
          if (m_byId[id] != null) throw Err.make("Unit id is already defined: " + id).val;
        }

        // this is a new definition
        for (int i=0; i<unit.m_ids.sz(); ++i)
           m_byId[(string)unit.m_ids.get(i)] = unit;
        m_list.add(unit);
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
      return dim.intern();
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

      public Dimension add(Dimension b)
      {
        Dimension r = new Dimension();
        r.kg  = (sbyte)(kg  + b.kg);
        r.m   = (sbyte)(m   + b.m);
        r.sec = (sbyte)(sec + b.sec);
        r.K   = (sbyte)(K   + b.K);
        r.A   = (sbyte)(A   + b.A);
        r.mol = (sbyte)(mol + b.mol);
        r.cd  = (sbyte)(cd  + b.cd);
        return r;
      }

      public Dimension subtract(Dimension b)
      {
        Dimension r = new Dimension();
        r.kg  = (sbyte)(kg  - b.kg);
        r.m   = (sbyte)(m   - b.m);
        r.sec = (sbyte)(sec - b.sec);
        r.K   = (sbyte)(K   - b.K);
        r.A   = (sbyte)(A   - b.A);
        r.mol = (sbyte)(mol - b.mol);
        r.cd  = (sbyte)(cd  - b.cd);
        return r;
      }

      public Dimension intern()
      {
        lock (m_dims)
        {
          Dimension cached = (Dimension)m_dims[this];
          if (cached != null) return cached;
          m_dims[this] = this;
          return this;
        }
      }

      internal string str;
      internal sbyte kg, m, sec, K, A, mol, cd;
    }

  //////////////////////////////////////////////////////////////////////////
  // Arithmetic
  //////////////////////////////////////////////////////////////////////////

    public Unit mult(Unit b)
    {
      lock (m_combos)
      {
        Combo key = new Combo(this, "*", b);
        Unit r = (Unit)m_combos[key];
        if (r == null)
        {
          r = findMult(this, b);
          m_combos[key] = r;
        }
        return r;
      }
    }

    private static Unit findMult(Unit a, Unit b)
    {
      // compute dim/scale of a * b
      Dimension dim = a.m_dim.add(b.m_dim).intern();
      double scale = a.m_scale * b.m_scale;

      // find all the matches
      Unit[] matches = match(dim, scale);
      if (matches.Length == 1) return matches[0];

      // right how our technique for resolving multiple matches is lame
      string expectedName = a.name() + "_" + b.name();
      for (int i=0; i<matches.Length; ++i)
        if (matches[i].name() == expectedName)
          return matches[i];

      // for now just give up
      throw Err.make("Cannot match to db: " + a + " * " + b).val;
    }

    public Unit div(Unit b)
    {
      lock (m_combos)
      {
        Combo key = new Combo(this, "/", b);
        Unit r = (Unit)m_combos[key];
        if (r == null)
        {
          r = findDiv(this, b);
          m_combos[key] = r;
        }
        return r;
      }
    }

    public Unit findDiv(Unit a, Unit b)
    {
      // compute dim/scale of a / b
      Dimension dim = a.m_dim.subtract(b.m_dim).intern();
      double scale = a.m_scale / b.m_scale;

      // find all the matches
      Unit[] matches = match(dim, scale);
      if (matches.Length == 1) return matches[0];

      // right how our technique for resolving multiple matches is lame
      string expectedName = a.name() + "_per_" + b.name();
      for (int i=0; i<matches.Length; ++i)
        if (matches[i].name().Contains(expectedName))
          return matches[i];

      // for now just give up
      throw Err.make("Cannot match to db: " + a + " / " + b).val;
    }

    private static Unit[] match(Dimension dim, double scale)
    {
      ArrayList acc = new ArrayList();
      lock (m_list)
      {
        for (int i=0; i<m_list.sz(); ++i)
        {
          Unit x = (Unit)m_list.get(i);
          if (x.m_dim == dim && approx(x.m_scale, scale))
            acc.Add(x);
        }
      }
      return (Unit[])acc.ToArray(System.Type.GetType("Fan.Sys.Unit"));
    }

    private static bool approx(double a, double b)
    {
      // pretty loose with our approximation because the database
      // doesn't have super great resolution for some normalizations
      if (a == b) return true;
      double t = Math.Min( Math.Abs(a/1e3), Math.Abs(b/1e3) );
      return Math.Abs(a - b) <= t;
    }

    internal class Combo
    {
      internal Combo(Unit a, String op, Unit b) { this.a  = a; this.op = op; this.b  = b; }
      public override int GetHashCode() { return a.GetHashCode() ^ op.GetHashCode() ^ (b.GetHashCode() << 13); }
      public override bool Equals(object that) { Combo x = (Combo)that; return a == x.a && op == x.op && b == x.b; }
      readonly Unit a;
      readonly string op;
      readonly Unit b;
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

    private static readonly List m_list = new List(Sys.UnitType);
    private static readonly Hashtable m_byId = new Hashtable(); // string id -> Unit
    private static readonly Hashtable m_dims = new Hashtable(); // Dimension -> Dimension
    private static readonly Hashtable m_quantities = new Hashtable(); // string -> List
    private static readonly List m_quantityNames;
    private static readonly Dimension m_dimensionless = new Dimension();
    private static readonly Hashtable m_combos = new Hashtable(); // Combo -> Unit
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