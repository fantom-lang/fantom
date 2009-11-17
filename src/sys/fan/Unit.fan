//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Dec 08  Brian Frank  Creation
//

**
** Unit models a unit of measurement.  Units are represented as:
**
**  - name: identifier for the unit within the VM.  Units are typically
**    defined in the unit database "etc/sys/units.fog" or can be defined
**    by the 'fromStr' method
**
**  - symbol: the abbreviated symbol - for example "kilogram" has
**    the symbol "kg"
**
**  - dimension: defines the ratio of the seven SI base units: m, kg,
**    sec, A, K, mol, and cd
**
**  - scale/factor: defines the normalization equations for unit conversion
**
** Units with equal dimensions are considered to the measure the same
** physical quantity.  This is not always true, but good enough for
** practice. Conversions with the 'convertTo' method are expressed with
** the following equations:
**
**   unit       = dimension * scale + offset
**   toNormal   = scalar * scale + offset
**   fromNormal = (scalar - offset) / scale
**   toUnit     = fromUnit.fromNormal( toUnit.toNormal(sclar) )
**
** As a simple, pragmatic solution for modeling Units, there are some
** units which don't fit this model including logarithm and angular units.
** Units which don't cleanly fit this model should be represented as
** dimensionless (all ratios set to zero).
**
** Fantom's model for units of measurement and the unit database are
** derived from the OASIS oBIX specification.
**
@simple
const class Unit
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the string format of a Unit instance.  If invalid format
  ** and checked is false return null, otherwise throw ParseErr.
  ** The string format of a unit is:
  **
  **   unit   := <name> [";" <symbol> [";" <dim> [";" <scale> [";" <offset>]]]]
  **   name   := <str>
  **   symbol := <str>
  **   dim    := <ratio> ["*" <ratio>]*   // no whitespace allowed
  **   ratio  := <base> <exp>
  **   base   := "kg" | "m" | "sec" | "K" | "A" | "mol" | "cd"
  **   exp    := <int>
  **   scale  := <float>
  **   offset := <float>
  **
  ** If the unit is not defined yet, this method defines the unit for the VM.
  ** If a compatible unit is already defined by the name then it is returned.  If an
  ** incompatible unit is already defined by the name then Err is thrown.
  **
  static Unit? fromStr(Str s, Bool checked := true)

  **
  ** Find a unit by its name if it has been defined in this VM.  If the
  ** unit isn't defined yet and checked is false then return null, otherwise
  ** throw Err.  Any units declared in "etc/sys/units.fog" are implicitly defined.
  **
  static Unit? find(Str s, Bool checked := true)

  **
  ** List all the units currently defined in the VM.  Any units
  ** declared in "etc/sys/units.fog" are implicitly defined.
  **
  static Unit[] list()

  **
  ** List the quantity names used to organize the unit database in
  ** "etc/sys/units.fog".  Quantities are merely a convenient mechanism
  ** to organize the unit database - there is no guarantee that they
  ** include all current VM definitions.
  **
  static Str[] quantities()

  **
  ** Get the units organized under a specific quantity name in the
  ** unit database "etc/sys/units.fog".  Quantities are merely a convenient
  ** mechanism to organize the unit database - there is no guarantee that
  ** they include all current VM definitions.
  **
  static Unit[] quantity(Str quantity)

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Two units are equal if they have reference equality
  ** because all units are interned during definition.
  **
  override Bool equals(Obj? that)

  **
  ** Return 'toStr.hash'.
  **
  override Int hash()

  **
  ** Return the string format of this unit. See `fromStr` for the format.
  **
  override Str toStr()

  **
  ** Return the identifier of this unit.
  **
  Str name()

  **
  ** Return the abbreviated symbol for this unit.  If the
  ** symbol was not defined then return `name`.
  **
  Str symbol()

  **
  ** Return the scale factor used to convert this unit "from normal".
  ** For example the scale factor for kilometer is 1000 because it is
  ** defined as a 1000 meters where meter is the normalized unit for
  ** length.  See class header for normalization and conversion equations.
  ** The scale factor the normalized unit is always one.
  **
  Float scale()

  **
  ** Return the offset factor used to convert this unit "from normal".
  ** See class header for normalization and conversion equations.  Offset
  ** is used most commonly with temperature units.  The offset for
  ** normalized unit is always zero.
  **
  Float offset()

//////////////////////////////////////////////////////////////////////////
// Dimension
//////////////////////////////////////////////////////////////////////////

  **
  ** Kilogram (mass) component of the unit dimension.
  **
  Int kg()

  **
  ** Meter (length) component of the unit dimension.
  **
  Int m()

  **
  ** Second (time) component of the unit dimension.
  **
  Int sec()

  **
  ** Kelvin (thermodynamic temperature) component of the unit dimension.
  **
  Int K()

  **
  ** Ampere (electric current) component of the unit dimension.
  **
  Int A()

  **
  ** Mole (amount of substance) component of the unit dimension.
  **
  Int mol()

  **
  ** Candela (luminous intensity) component of the unit dimension.
  **
  Int cd()

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  **
  ** Convert a scalar value from this unit to the given unit.  If
  ** the units do not have the same dimension then throw Err.
  ** For example, to convert 3km to meters:
  **   m  := Unit.find("meter")
  **   km := Unit.find("kilometer")
  **   km.convertTo(3f, m)  =>  3000f
  **
  Float convertTo(Float scalar, Unit unit)

}