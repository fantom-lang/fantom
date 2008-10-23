//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Apr 08  Auto-generated by /adm/genfcode.rb
//
namespace Fanx.Fcode
{

/**
 * FConst provides all the fcode constants
 */
public class FConst
{

//////////////////////////////////////////////////////////////////////////
// Stuff
//////////////////////////////////////////////////////////////////////////

  public const int FCodeMagic    = 0x0FC0DE05;
  public const int FCodeVersion  = 0x01000016;
  public const int TypeDbMagic   = 0x0FC0DEDB;
  public const int TypeDbVersion = 0x01000018;

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  public const int Abstract   = 0x00000001;
  public const int Const      = 0x00000002;
  public const int Ctor       = 0x00000004;
  public const int Enum       = 0x00000008;
  public const int Final      = 0x00000010;
  public const int Getter     = 0x00000020;
  public const int Internal   = 0x00000040;
  public const int Mixin      = 0x00000080;
  public const int Native     = 0x00000100;
  public const int Override   = 0x00000200;
  public const int Private    = 0x00000400;
  public const int Protected  = 0x00000800;
  public const int Public     = 0x00001000;
  public const int Setter     = 0x00002000;
  public const int Static     = 0x00004000;
  public const int Storage    = 0x00008000;
  public const int Synthetic  = 0x00010000;
  public const int Virtual    = 0x00020000;
  public const int FlagsMask  = 0x0003ffff;

//////////////////////////////////////////////////////////////////////////
// MethodVarFlags
//////////////////////////////////////////////////////////////////////////

  public const int Param = 0x0001;  // parameter or local variable

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  public const string ErrTableAttr     = "ErrTable";
  public const string FacetsAttr       = "Facets";
  public const string LineNumberAttr   = "LineNumber";
  public const string LineNumbersAttr  = "LineNumbers";
  public const string SourceFileAttr   = "SourceFile";
  public const string ParamDefaultAttr = "ParamDefault";

//////////////////////////////////////////////////////////////////////////
// OpCodes
//////////////////////////////////////////////////////////////////////////

  public const int Nop              =   0; // ()        no operation
  public const int LoadNull         =   1; // ()        load null literal onto stack
  public const int LoadFalse        =   2; // ()        load false literal onto stack
  public const int LoadTrue         =   3; // ()        load true literal onto stack
  public const int LoadInt          =   4; // (int)     load Int const by index onto stack
  public const int LoadFloat        =   5; // (float)   load Float const by index onto stack
  public const int LoadStr          =   6; // (str)     load Str const by index onto stack
  public const int LoadDuration     =   7; // (dur)     load Duration const by index onto stack
  public const int LoadType         =   8; // (type)    load Type instance by index onto stack
  public const int LoadUri          =   9; // (uri)     load Uri const by index onto stack
  public const int LoadVar          =  10; // (reg)     local var register index (0 is this)
  public const int StoreVar         =  11; // (reg)     local var register index (0 is this)
  public const int LoadInstance     =  12; // (field)   load field from storage
  public const int StoreInstance    =  13; // (field)   store field to storage
  public const int LoadStatic       =  14; // (field)   load static field from storage
  public const int StoreStatic      =  15; // (field)   store static field to storage
  public const int Unused1          =  16; // ()        unsed opcode
  public const int Unused2          =  17; // ()        unsed opcode
  public const int LoadMixinStatic  =  18; // (field)   load static on mixin field from storage
  public const int StoreMixinStatic =  19; // (field)   store static on mixin field to storage
  public const int CallNew          =  20; // (method)  alloc new object and call constructor
  public const int CallCtor         =  21; // (method)  call constructor (used for constructor chaining)
  public const int CallStatic       =  22; // (method)  call static method
  public const int CallVirtual      =  23; // (method)  call virtual instance method
  public const int CallNonVirtual   =  24; // (method)  call instance method non-virtually (private or super only b/c of Java invokespecial)
  public const int CallMixinStatic  =  25; // (method)  call static mixin method
  public const int CallMixinVirtual =  26; // (method)  call virtual mixin method
  public const int CallMixinNonVirtual =  27; // (method)  call instance mixin method non-virtually (named super)
  public const int Jump             =  28; // (jmp)     unconditional jump
  public const int JumpTrue         =  29; // (jmp)     jump if bool true
  public const int JumpFalse        =  30; // (jmp)     jump if bool false
  public const int CompareEQ        =  31; // ()        a.equals(b)
  public const int CompareNE        =  32; // ()        !a.equals(b)
  public const int Compare          =  33; // ()        a.compare(b)
  public const int CompareLE        =  34; // ()        a.compare(b) <= 0
  public const int CompareLT        =  35; // ()        a.compare(b) < 0
  public const int CompareGT        =  36; // ()        a.compare(b) > 0
  public const int CompareGE        =  37; // ()        a.compare(b) >= 0
  public const int CompareSame      =  38; // ()        a === b
  public const int CompareNotSame   =  39; // ()        a !== b
  public const int CompareNull      =  40; // ()        a == null
  public const int CompareNotNull   =  41; // ()        a != null
  public const int ReturnVoid       =  42; // ()        return nothing
  public const int ReturnObj        =  43; // ()        return object
  public const int Pop              =  44; // ()        pop top object off stack
  public const int Dup              =  45; // ()        duplicate object ref on top of stack
  public const int DupDown          =  46; // ()        TODO - remove when we axe Java compiler
  public const int Is               =  47; // (type)    is operator
  public const int As               =  48; // (type)    as operator
  public const int Cast             =  49; // (type)    type cast
  public const int Switch           =  50; // ()        switch jump table 2 count + 2*count
  public const int Throw            =  51; // ()        throw Err on top of stack
  public const int Leave            =  52; // (jmp)     jump out of a try or catch block
  public const int JumpFinally      =  53; // (jmp)     jump to a finally block
  public const int CatchAllStart    =  54; // ()        start catch all block - do not leave Err on stack
  public const int CatchErrStart    =  55; // (type)    start catch block - leave typed Err on stack
  public const int CatchEnd         =  56; // ()        start catch block - leave typed Err on stack
  public const int FinallyStart     =  57; // ()        starting instruction of a finally block
  public const int FinallyEnd       =  58; // ()        ending instruction of a finally block
  public const int LoadDecimal      =  59; // (decimal)  load Decimal const by index onto stack

  public static readonly string[] OpNames =
  {
    "Nop",                //   0
    "LoadNull",           //   1
    "LoadFalse",          //   2
    "LoadTrue",           //   3
    "LoadInt",            //   4
    "LoadFloat",          //   5
    "LoadStr",            //   6
    "LoadDuration",       //   7
    "LoadType",           //   8
    "LoadUri",            //   9
    "LoadVar",            //  10
    "StoreVar",           //  11
    "LoadInstance",       //  12
    "StoreInstance",      //  13
    "LoadStatic",         //  14
    "StoreStatic",        //  15
    "Unused1",            //  16
    "Unused2",            //  17
    "LoadMixinStatic",    //  18
    "StoreMixinStatic",   //  19
    "CallNew",            //  20
    "CallCtor",           //  21
    "CallStatic",         //  22
    "CallVirtual",        //  23
    "CallNonVirtual",     //  24
    "CallMixinStatic",    //  25
    "CallMixinVirtual",   //  26
    "CallMixinNonVirtual",  //  27
    "Jump",               //  28
    "JumpTrue",           //  29
    "JumpFalse",          //  30
    "CompareEQ",          //  31
    "CompareNE",          //  32
    "Compare",            //  33
    "CompareLE",          //  34
    "CompareLT",          //  35
    "CompareGT",          //  36
    "CompareGE",          //  37
    "CompareSame",        //  38
    "CompareNotSame",     //  39
    "CompareNull",        //  40
    "CompareNotNull",     //  41
    "ReturnVoid",         //  42
    "ReturnObj",          //  43
    "Pop",                //  44
    "Dup",                //  45
    "DupDown",            //  46
    "Is",                 //  47
    "As",                 //  48
    "Cast",               //  49
    "Switch",             //  50
    "Throw",              //  51
    "Leave",              //  52
    "JumpFinally",        //  53
    "CatchAllStart",      //  54
    "CatchErrStart",      //  55
    "CatchEnd",           //  56
    "FinallyStart",       //  57
    "FinallyEnd",         //  58
    "LoadDecimal",        //  59
  };

  public static readonly int[] OpSkips =
  {
    0,  //   0 Nop
    0,  //   1 LoadNull
    0,  //   2 LoadFalse
    0,  //   3 LoadTrue
    2,  //   4 LoadInt
    2,  //   5 LoadFloat
    2,  //   6 LoadStr
    2,  //   7 LoadDuration
    2,  //   8 LoadType
    2,  //   9 LoadUri
    2,  //  10 LoadVar
    2,  //  11 StoreVar
    2,  //  12 LoadInstance
    2,  //  13 StoreInstance
    2,  //  14 LoadStatic
    2,  //  15 StoreStatic
    0,  //  16 Unused1
    0,  //  17 Unused2
    2,  //  18 LoadMixinStatic
    2,  //  19 StoreMixinStatic
    2,  //  20 CallNew
    2,  //  21 CallCtor
    2,  //  22 CallStatic
    2,  //  23 CallVirtual
    2,  //  24 CallNonVirtual
    2,  //  25 CallMixinStatic
    2,  //  26 CallMixinVirtual
    2,  //  27 CallMixinNonVirtual
    2,  //  28 Jump
    2,  //  29 JumpTrue
    2,  //  30 JumpFalse
    0,  //  31 CompareEQ
    0,  //  32 CompareNE
    0,  //  33 Compare
    0,  //  34 CompareLE
    0,  //  35 CompareLT
    0,  //  36 CompareGT
    0,  //  37 CompareGE
    0,  //  38 CompareSame
    0,  //  39 CompareNotSame
    0,  //  40 CompareNull
    0,  //  41 CompareNotNull
    0,  //  42 ReturnVoid
    0,  //  43 ReturnObj
    0,  //  44 Pop
    0,  //  45 Dup
    0,  //  46 DupDown
    2,  //  47 Is
    2,  //  48 As
    2,  //  49 Cast
    0,  //  50 Switch
    0,  //  51 Throw
    2,  //  52 Leave
    2,  //  53 JumpFinally
    0,  //  54 CatchAllStart
    2,  //  55 CatchErrStart
    0,  //  56 CatchEnd
    0,  //  57 FinallyStart
    0,  //  58 FinallyEnd
    2,  //  59 LoadDecimal
  };

  public static readonly string[] OpSigs =
  {
    "()",         //   0 Nop
    "()",         //   1 LoadNull
    "()",         //   2 LoadFalse
    "()",         //   3 LoadTrue
    "(int)",      //   4 LoadInt
    "(float)",    //   5 LoadFloat
    "(str)",      //   6 LoadStr
    "(dur)",      //   7 LoadDuration
    "(type)",     //   8 LoadType
    "(uri)",      //   9 LoadUri
    "(reg)",      //  10 LoadVar
    "(reg)",      //  11 StoreVar
    "(field)",    //  12 LoadInstance
    "(field)",    //  13 StoreInstance
    "(field)",    //  14 LoadStatic
    "(field)",    //  15 StoreStatic
    "()",         //  16 Unused1
    "()",         //  17 Unused2
    "(field)",    //  18 LoadMixinStatic
    "(field)",    //  19 StoreMixinStatic
    "(method)",   //  20 CallNew
    "(method)",   //  21 CallCtor
    "(method)",   //  22 CallStatic
    "(method)",   //  23 CallVirtual
    "(method)",   //  24 CallNonVirtual
    "(method)",   //  25 CallMixinStatic
    "(method)",   //  26 CallMixinVirtual
    "(method)",   //  27 CallMixinNonVirtual
    "(jmp)",      //  28 Jump
    "(jmp)",      //  29 JumpTrue
    "(jmp)",      //  30 JumpFalse
    "()",         //  31 CompareEQ
    "()",         //  32 CompareNE
    "()",         //  33 Compare
    "()",         //  34 CompareLE
    "()",         //  35 CompareLT
    "()",         //  36 CompareGT
    "()",         //  37 CompareGE
    "()",         //  38 CompareSame
    "()",         //  39 CompareNotSame
    "()",         //  40 CompareNull
    "()",         //  41 CompareNotNull
    "()",         //  42 ReturnVoid
    "()",         //  43 ReturnObj
    "()",         //  44 Pop
    "()",         //  45 Dup
    "()",         //  46 DupDown
    "(type)",     //  47 Is
    "(type)",     //  48 As
    "(type)",     //  49 Cast
    "()",         //  50 Switch
    "()",         //  51 Throw
    "(jmp)",      //  52 Leave
    "(jmp)",      //  53 JumpFinally
    "()",         //  54 CatchAllStart
    "(type)",     //  55 CatchErrStart
    "()",         //  56 CatchEnd
    "()",         //  57 FinallyStart
    "()",         //  58 FinallyEnd
    "(decimal)",  //  59 LoadDecimal
  };

} // FConst


} // Fanx.Fcode