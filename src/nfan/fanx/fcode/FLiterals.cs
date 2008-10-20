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
  /// FLiterals manages the Long, Double, Duration, Str,
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
      m_ints.read(m_fpod.m_store.read("ints.def"));
      m_floats.read(m_fpod.m_store.read("floats.def"));
      m_decimals.read(m_fpod.m_store.read("decimals.def"));
      m_strs.read(m_fpod.m_store.read("strs.def"));
      m_durations.read(m_fpod.m_store.read("durations.def"));
      m_uris.read(m_fpod.m_store.read("uris.def"));
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // Tables
  //////////////////////////////////////////////////////////////////////////

    public Long integer(int index)      { return (Long)m_ints.get(index); }
    public Double floats(int index)     { return (Double)m_floats.get(index); }
    public Decimal decimals(int index)  { return (Decimal)m_decimals.get(index); }
    public Str str(int index)           { return (Str)m_strs.get(index); }
    public Duration duration(int index) { return (Duration)m_durations.get(index); }
    public Uri uri(int index)           { return (Uri)m_uris.get(index); }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public FPod m_fpod;         // parent pod
    public FTable m_ints;       // Long literals
    public FTable m_floats;     // Double literals
    public FTable m_decimals;   // Decimal literals
    public FTable m_strs;       // Str literals
    public FTable m_durations;  // Duration literals
    public FTable m_uris;       // Uri literals

  }
}