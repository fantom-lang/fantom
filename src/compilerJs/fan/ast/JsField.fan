//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsField
**
class JsField : JsSlot
{
  new make(JsCompilerSupport s, FieldDef f) : super(s, f)
  {
    this.ftype = JsTypeRef(s, f.fieldType)
  }

  override Void write(JsWriter out)
  {
    if (!isNative)
    {
      defVal := "null"
      if (!ftype.isNullable)
      {
        switch (ftype.qname)
        {
          case "fan.sys.Bool":    defVal = "false"
          case "fan.sys.Decimal": defVal = "fan.sys.Decimal.make(0)"
          case "fan.sys.Float":   defVal = "fan.sys.Float.make(0)"
          case "fan.sys.Int":     defVal = "0"
        }
      }

      out.w(parent)
      if (!isStatic) out.w(".prototype")
      out.w(".m_$name = $defVal;").nl
    }
  }

  JsTypeRef ftype  // field type
}

