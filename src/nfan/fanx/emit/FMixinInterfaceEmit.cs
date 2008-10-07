//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 07  Andy Frank  Creation
//

using Fan.Sys;
using Fanx.Fcode;

namespace Fanx.Emit
{
  /// <summary>
  /// FMixinInterfaceEmit emits the interface of a mixin type.
  /// </summary>
  public class FMixinInterfaceEmit : FTypeEmit
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FMixinInterfaceEmit(Emitter emitter, Type parent, FType type)
      : base(emitter, parent, type)
    {
    }

  //////////////////////////////////////////////////////////////////////////
  // Overrides
  //////////////////////////////////////////////////////////////////////////

    public override void emit()
    {
      init(nname(type.m_self), @base(), mixins(), type.m_flags);
      this.selfName = className;
      emitType();

      // make sure type has been read
      if (type.m_hollow) type.read();

      for (int i=0; i<type.m_methods.Length; i++) emit(type.m_methods[i]);
    }

    protected override string[] mixins()
    {
      string[] mixins = new string[type.m_mixins.Length];
      for (int i=0; i<mixins.Length; i++)
        mixins[i] = nname(type.m_mixins[i]);
      return mixins;
    }

    protected override string @base()
    {
      return null;
    }

    protected override void emitType()
    {
      emitter.emitClass(baseClassName, className, interfaces,
        PERWAPI.TypeAttr.Public | PERWAPI.TypeAttr.Interface | PERWAPI.TypeAttr.Abstract);
    }

    protected override void emit(FMethod m)
    {
      new FMethodEmit(this, m).emitMixinInterface();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

  }
}