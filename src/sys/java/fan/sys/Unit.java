//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Dec 08  Brian Frank  Creation
//
package fan.sys;

import java.util.HashMap;

/**
 * Unit
 */
public final class Unit
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Database
//////////////////////////////////////////////////////////////////////////

  public static Unit find(String name) { return find(name, true); }
  public static Unit find(String name, boolean checked)
  {
    synchronized (units)
    {
      Unit unit = (Unit)units.get(name);
      if (unit != null || !checked) return unit;
      throw Err.make("Unit not found: " + name).val;
    }
  }

  public static List list()
  {
    synchronized (units)
    {
      return new List(Sys.UnitType, units.values().toArray());
    }
  }

  public static List quantities()
  {
    return quantityNames;
  }

  public static List quantity(String quantity)
  {
    List list = (List)quantities.get(quantity);
    if (list == null) throw Err.make("Unknown unit database quantity: " + quantity).val;
    return list;
  }

  private static List loadDatabase()
  {
    try
    {
      // parse etc/sys/units.fog as big serialized list which contains
      // lists for each quantity (first item being the name)
      String path = "etc/sys/units.fog";
      InStream in;
      if (Sys.isJarDist)
        in = new SysInStream(Unit.class.getClassLoader().getResourceAsStream(path));
      else
        in = Env.cur().findFile(path).in();
      List all = (List)in.readObj();
      in.close();

      // map lists to quantity data structures
      List quantityNames = new List(Sys.StrType);
      for (int i=0; i<all.sz(); ++i)
      {
        List q = (List)all.get(i);
        String name = (String)q.get(0);
        q.removeAt(0);
        q = (List)q.toImmutable();
        quantityNames.add(name);
        quantities.put(name, q);
      }

      // return quantity names
      return (List)quantityNames.toImmutable();
    }
    catch (Throwable e)
    {
      System.out.println("WARNING: Cannot load etc/sys/units.fog");
      e.printStackTrace();
      return (List)new List(Sys.StrType).toImmutable();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  public static Unit fromStr(String str) { return fromStr(str, true); }
  public static Unit fromStr(String str, boolean checked)
  {
    Unit unit = null;
    try
    {
      unit = parseUnit(str);
    }
    catch (Throwable e)
    {
      if (!checked) return null;
      throw ParseErr.make("Unit", str).val;
    }
    return define(unit);
  }

  /**
   * Parse an un-interned unit:
   *   unit := <name> [";" <symbol> [";" <dim> [";" <scale> [";" <offset>]]]]
   */
  private static Unit parseUnit(String s)
  {
    String name = s;
    int c = s.indexOf(';');
    if (c < 0) return new Unit(name, name, dimensionless, 1, 0);

    name = s.substring(0, c).trim();
    String symbol = s = s.substring(c+1).trim();
    c = s.indexOf(';');
    if (c < 0) return new Unit(name, symbol, dimensionless, 1, 0);

    symbol = s.substring(0, c).trim();
    if (symbol.length() == 0) symbol = name;
    String dim = s = s.substring(c+1).trim();
    c = s.indexOf(';');
    if (c < 0) return new Unit(name, symbol, parseDim(dim), 1, 0);

    dim = s.substring(0, c).trim();
    String scale = s = s.substring(c+1).trim();
    c = s.indexOf(';');
    if (c < 0) return new Unit(name, symbol, parseDim(dim), Double.parseDouble(scale), 0);

    scale = s.substring(0, c).trim();
    String offset = s.substring(c+1).trim();
    return new Unit(name, symbol, parseDim(dim), Double.parseDouble(scale), Double.parseDouble(offset));
  }

  /**
   * Parse an dimension string and intern it:
   *   dim    := <ratio> ["*" <ratio>]*
   *   ratio  := <base> <exp>
   *   base   := "kg" | "m" | "sec" | "K" | "A" | "mol" | "cd"
   */
  private static Dimension parseDim(String s)
  {
    // handle empty string as dimensionless
    if (s.length() == 0) return dimensionless;

    // parse dimension
    Dimension dim = new Dimension();
    List ratios = FanStr.split(s, (long)'*', true);
    for (int i=0; i<ratios.sz(); ++i)
    {
      String r = (String)ratios.get(i);
      if (r.startsWith("kg"))  { dim.kg  = Byte.parseByte(r.substring(2).trim()); continue; }
      if (r.startsWith("sec")) { dim.sec = Byte.parseByte(r.substring(3).trim()); continue; }
      if (r.startsWith("mol")) { dim.mol = Byte.parseByte(r.substring(3).trim()); continue; }
      if (r.startsWith("m"))   { dim.m   = Byte.parseByte(r.substring(1).trim()); continue; }
      if (r.startsWith("K"))   { dim.K   = Byte.parseByte(r.substring(1).trim()); continue; }
      if (r.startsWith("A"))   { dim.A   = Byte.parseByte(r.substring(1).trim()); continue; }
      if (r.startsWith("cd"))  { dim.cd  = Byte.parseByte(r.substring(2).trim()); continue; }
      throw new RuntimeException("Bad ratio '" + r + "'");
    }

    // intern
    synchronized (dims)
    {
      Dimension cached = (Dimension)dims.get(dim);
      if (cached != null) return cached;
      dims.put(dim, dim);
      return dim;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Definition
//////////////////////////////////////////////////////////////////////////

  /**
   * Define a new unit.  If the unit is already defined then we check
   * that it is compatible with our existing definition and intern it.
   */
  private static Unit define(Unit unit)
  {
    synchronized (units)
    {
      // lookup by name
      Unit existing = (Unit)units.get(unit.name);

      // if we have an existing check if compatible
      if (existing != null)
      {
        if (!existing.isCompatibleDefinition(unit))
          throw Err.make("Attempt to define incompatible units: " + existing + " != " + unit).val;
        return existing;
      }

      // this is a new definition
      units.put(unit.name, unit);
      return unit;
    }
  }

  /**
   * Return if this unit is compatible with the other unit's definition.
   * We provide a little flexibility on the scale and offset because
   * doubles are so imprecise.
   */
  private boolean isCompatibleDefinition(Unit x)
  {
    return symbol.equals(x.symbol) &&
           dim == x.dim &&
           FanFloat.approx(scale, x.scale) &&
           FanFloat.approx(offset, x.offset);
  }

  /**
   * Private constructor.
   */
  private Unit(String name, String symbol, Dimension dim, double scale, double offset)
  {
    this.name   = name;
    this.symbol = symbol;
    this.dim    = dim;
    this.scale  = scale;
    this.offset = offset;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final boolean equals(Object obj) { return this == obj; }

  public final int hashCode() { return toStr().hashCode(); }

  public final long hash() { return FanObj.hash(toStr()); }

  public final Type typeof() { return Sys.UnitType; }

  public String toStr()
  {
    if (str == null)
    {
      StringBuilder s = new StringBuilder();
      s.append(name);
      s.append("; ").append(symbol);
      if (dim != dimensionless)
      {
        s.append("; ").append(dim);
        if (scale != 1.0 || offset != 0.0)
        {
          s.append("; ").append(scale);
          if (offset != 0.0) s.append("; ").append(offset);
        }
      }
      str = s.toString();
    }
    return str;
  }

  public final String name() { return name; }

  public final String symbol() { return symbol; }

  public final double scale() { return scale; }

  public final double offset() { return offset; }

//////////////////////////////////////////////////////////////////////////
// Dimension
//////////////////////////////////////////////////////////////////////////

  public final long kg() { return dim.kg; }

  public final long m() { return dim.m; }

  public final long sec() { return dim.sec; }

  public final long K() { return dim.K; }

  public final long A() { return dim.A; }

  public final long mol() { return dim.mol; }

  public final long cd() { return dim.cd; }

  static class Dimension
  {
    public int hashCode()
    {
      return (kg << 28) ^ (m << 23) ^ (sec << 18) ^
             (K << 13) ^ (A << 8) ^ (mol << 3) ^ cd;
    }

    public boolean equals(Object o)
    {
      Dimension x = (Dimension)o;
      return kg == x.kg && m   == x.m   && sec == x.sec && K == x.K &&
             A  == x.A  && mol == x.mol && cd  == x.cd;
    }

    public String toString()
    {
      if (str == null)
      {
        StringBuilder s = new StringBuilder();
        append(s, "kg",  kg);  append(s, "m",   m);
        append(s, "sec", sec); append(s, "K",   K);
        append(s, "A",   A);   append(s, "mol", mol);
        append(s, "cd",  cd);
        str = s.toString();
      }
      return str;
    }

    private void append(StringBuilder s, String key, int val)
    {
      if (val == 0) return;
      if (s.length() > 0) s.append('*');
      s.append(key).append(val);
    }

    String str;
    byte kg, m, sec, K, A, mol, cd;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public final double convertTo(double scalar, Unit to)
  {
    if (dim != to.dim) throw Err.make("Incovertable units: " + this + " and " + to).val;
    return ((scalar * this.scale + this.offset) - to.offset) / to.scale;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final HashMap units = new HashMap(); // String name -> Unit
  private static final HashMap dims = new HashMap(); // Dimension -> Dimension
  private static final HashMap quantities = new HashMap(); // String -> List
  private static final List quantityNames;
  private static final Dimension dimensionless = new Dimension();
  static
  {
    dims.put(dimensionless, dimensionless);
    quantityNames = loadDatabase();
  }

  private final String name;
  private final String symbol;
  private final double scale;
  private final double offset;
  private final Dimension dim;
  private String str;

}