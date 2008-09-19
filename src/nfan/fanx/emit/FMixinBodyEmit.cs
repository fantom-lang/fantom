//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Jan 07  Andy Frank  Creation
//

using Fan.Sys;
using Fanx.Fcode;

namespace Fanx.Emit
{
  /// <summary>
  /// FMixinBodyEmit emits the class body of a mixin type.
  /// </summary>
  public class FMixinBodyEmit : FClassEmit
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FMixinBodyEmit(Emitter emitter, Type parent, FType type)
      : base(emitter, parent, type)
    {
    }

  //////////////////////////////////////////////////////////////////////////
  // Overrides
  //////////////////////////////////////////////////////////////////////////

    public override void emit()
    {
      init(nname(type.m_self)+"_", @base(), new string[0], FConst.Public | FConst.Final);
      this.selfName = className;
      //preview();
      emitType();

      // make sure type has been read
      if (type.m_hollow) type.read();

      // emit class body
      for (int i=0; i<type.m_fields.Length;  i++) emit(type.m_fields[i]);
      for (int i=0; i<type.m_methods.Length; i++) emit(type.m_methods[i]);
      emitTypeConstFields();

      if (!ctorEmit)  ctor.CreateCodeBuffer().Inst(PERWAPI.Op.ret);
      if (!cctorEmit) cctor.CreateCodeBuffer().Inst(PERWAPI.Op.ret);
    }

    protected override string @base()
    {
      return "System.Object";
    }

    /// <summary>
    /// Only emit static fields (stored on body, not interface)
    /// </summary>
    protected override void emit(FField f)
    {
      if ((f.m_flags & FConst.Static) != 0)
        base.emit(f);
    }

    protected override void emitType()
    {
      base.emitType();
    }

    protected override void emit(FMethod m)
    {
      string name = m.m_name;
      if (name == "static$init") { emitStaticInit(m); cctorEmit = true; return; }

      new FMethodEmit(this, m).emitMixinBody();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    bool ctorEmit  = false;
    bool cctorEmit = false;

  }
}
