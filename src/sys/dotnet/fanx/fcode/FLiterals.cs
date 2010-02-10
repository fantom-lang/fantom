//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 07  Brian Frank  Creation
//

using Fan.Sys;

namespace Fanx.Fcode
{
  /// <summary>
  /// FLiterals manages the long, double, Duration, string,
  /// and Uri literal constants.
  /// </summary>
  public sealed class FLiterals
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FLiterals(FPod fpod)
    {
      this.m_fpod = fpod;
      this.m_ints       = new FTable.Ints(fpod);
      this.m_floats     = new FTable.Floats(fpod);
      this.m_decimals   = new FTable.Decimals(fpod);
      this.m_strs       = new FTable.Strs(fpod);
      this.m_durations  = new FTable.Durations(fpod);
      this.m_uris       = new FTable.Uris(fpod);
    }

  //////////////////////////////////////////////////////////////////////////
  // Read
  //////////////////////////////////////////////////////////////////////////

    public FLiterals read()
    {
      m_ints.read(m_fpod.m_store.read("fcode/ints.def"));
      m_floats.read(m_fpod.m_store.read("fcode/floats.def"));
      m_decimals.read(m_fpod.m_store.read("fcode/decimals.def"));
      m_strs.read(m_fpod.m_store.read("fcode/strs.def"));
      m_durations.read(m_fpod.m_store.read("fcode/durations.def"));
      m_uris.read(m_fpod.m_store.read("fcode/uris.def"));
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // Tables
  //////////////////////////////////////////////////////////////////////////

    public long integer(int index)      { return (long)m_ints.get(index); }
    public double floats(int index)     { return (double)m_floats.get(index); }
    public BigDecimal decimals(int index)  { return (BigDecimal)m_decimals.get(index); }
    public string str(int index)           { return (string)m_strs.get(index); }
    public Duration duration(int index) { return (Duration)m_durations.get(index); }
    public Uri uri(int index)           { return (Uri)m_uris.get(index); }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public FPod m_fpod;         // parent pod
    public FTable m_ints;       // long literals
    public FTable m_floats;     // double literals
    public FTable m_decimals;   // BigDecimal literals
    public FTable m_strs;       // string literals
    public FTable m_durations;  // Duration literals
    public FTable m_uris;       // Uri literals

  }
}