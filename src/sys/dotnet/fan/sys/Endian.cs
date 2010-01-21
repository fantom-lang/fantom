//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Dec 09  Brian Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// Endian.
  /// </summary>
  public sealed class Endian : Enum
  {

    public static readonly Endian m_big    = new Endian(0, "big");
    public static readonly Endian m_little = new Endian(1, "little");

    internal static readonly Endian[] array =
    {
      m_big, m_little
    };

    public static readonly List m_vals = new List(Sys.EndianType, array).ro();

    private Endian(int ordinal, string name)
    {
      Enum.make_(this, ordinal, System.String.Intern(name));
    }

    public static Endian fromStr(string name) { return fromStr(name, true); }
    public static Endian fromStr(string name, bool check)
    {
      return (Endian)doFromStr(Sys.EndianType, name, check);
    }

    public override Type @typeof() { return Sys.EndianType; }
 }
}