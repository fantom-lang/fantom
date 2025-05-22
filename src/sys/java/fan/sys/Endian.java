//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Dec 09  Brian Frank  Creation
//
package fan.sys;

/**
 * Endian
 */
public final class Endian
  extends Enum
{

  public static final int BIG    = 0;
  public static final int LITTLE = 1;

  public static final Endian big    = new Endian(BIG, "big");
  public static final Endian little = new Endian(LITTLE, "little");

  static final Endian[] array = { big, little };

  public static final List<Endian> vals = (List)new List(Sys.EndianType, array).toImmutable();

  private Endian(int ordinal, String name)
  {
    Enum.make$(this, FanInt.pos[ordinal], name.intern());
  }

  public static Endian fromStr(String name) { return fromStr(name, true); }
  public static Endian fromStr(String name, boolean checked)
  {
    return (Endian)doFromStr(Sys.EndianType, name, checked);
  }

  public Type typeof() { return Sys.EndianType; }

}

