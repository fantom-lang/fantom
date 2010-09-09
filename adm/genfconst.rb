# Copyright (c) 2005, Brian Frank and Andy Frank
# Licensed under the Academic Free License version 3.0

#
# genfconst -- generate the FConst source file for Java and C#, allowing
#   us to maintain a single authoritative source in this Ruby script
#
# @author   Brian Frank
# @creation 26 Dec 05
#

require 'adm/env.rb'

class GenFConst < Env

#####################################################################
# Stuff
#####################################################################

 @@stuff = [

  "FCodeVersion = \"1.0.51\";",

 ]


#####################################################################
# Flags
#####################################################################

 @@flags = [

  "Abstract   = 0x00000001;",
  "Const      = 0x00000002;",
  "Ctor       = 0x00000004;",
  "Enum       = 0x00000008;",
  "Facet      = 0x00000010;",
  "Final      = 0x00000020;",
  "Getter     = 0x00000040;",
  "Internal   = 0x00000080;",
  "Mixin      = 0x00000100;",
  "Native     = 0x00000200;",
  "Override   = 0x00000400;",
  "Private    = 0x00000800;",
  "Protected  = 0x00001000;",
  "Public     = 0x00002000;",
  "Setter     = 0x00004000;",
  "Static     = 0x00008000;",
  "Storage    = 0x00010000;",
  "Synthetic  = 0x00020000;",
  "Virtual    = 0x00040000;",
  "FlagsMask  = 0x0007ffff;",

 ]

#####################################################################
# MethodVarFlags
#####################################################################

 @@methodVarFlags = [

  "Param = 0x0001;  // parameter or local variable",

 ]

#####################################################################
# Attributes
#####################################################################

 @@attributes = [

  "ErrTableAttr     = \"ErrTable\";",
  "FacetsAttr       = \"Facets\";",
  "LineNumberAttr   = \"LineNumber\";",
  "LineNumbersAttr  = \"LineNumbers\";",
  "SourceFileAttr   = \"SourceFile\";",
  "ParamDefaultAttr = \"ParamDefault\";",
  "EnumOrdinalAttr  = \"EnumOrdinal\";",

 ]

#####################################################################
# OpCodes
#####################################################################

 @@opcodes = [

   "Nop                 0  ()         // no operation",
   "LoadNull            0  ()         // load null literal onto stack",
   "LoadFalse           0  ()         // load false literal onto stack",
   "LoadTrue            0  ()         // load true literal onto stack",
   "LoadInt             2  (int)      // load Int const by index onto stack",
   "LoadFloat           2  (float)    // load Float const by index onto stack",
   "LoadDecimal         2  (decimal)  // load Decimal const by index onto stack",
   "LoadStr             2  (str)      // load Str const by index onto stack",
   "LoadDuration        2  (dur)      // load Duration const by index onto stack",
   "LoadType            2  (type)     // load Type instance by index onto stack",
   "LoadUri             2  (uri)      // load Uri const by index onto stack",

   "LoadVar             2  (reg)      // local var register index (0 is this)",
   "StoreVar            2  (reg)      // local var register index (0 is this)",

   "LoadInstance        2  (field)    // load field from storage",
   "StoreInstance       2  (field)    // store field to storage",
   "LoadStatic          2  (field)    // load static field from storage",
   "StoreStatic         2  (field)    // store static field to storage",
   "LoadMixinStatic     2  (field)    // load static on mixin field from storage",
   "StoreMixinStatic    2  (field)    // store static on mixin field to storage",

   "CallNew             2  (method)   // alloc new object and call constructor",
   "CallCtor            2  (method)   // call constructor (used for constructor chaining)",
   "CallStatic          2  (method)   // call static method",
   "CallVirtual         2  (method)   // call virtual instance method",
   "CallNonVirtual      2  (method)   // call instance method non-virtually (private or super only b/c of Java invokespecial)",
   "CallMixinStatic     2  (method)   // call static mixin method",
   "CallMixinVirtual    2  (method)   // call virtual mixin method",
   "CallMixinNonVirtual 2  (method)   // call instance mixin method non-virtually (named super)",

   "Jump                2  (jmp)      // unconditional jump",
   "JumpTrue            2  (jmp)      // jump if bool true",
   "JumpFalse           2  (jmp)      // jump if bool false",

   "CompareEQ           0  (typePair) // a.equals(b)",
   "CompareNE           0  (typePair) // !a.equals(b)",
   "Compare             0  (typePair) // a.compare(b)",
   "CompareLE           0  (typePair) // a.compare(b) <= 0",
   "CompareLT           0  (typePair) // a.compare(b) < 0",
   "CompareGT           0  (typePair) // a.compare(b) > 0",
   "CompareGE           0  (typePair) // a.compare(b) >= 0",
   "CompareSame         0  ()         // a === b",
   "CompareNotSame      0  ()         // a !== b",
   "CompareNull         0  (type)     // a == null",
   "CompareNotNull      0  (type)     // a != null",

   "Return              0  ()         // return from method",
   "Pop                 0  (type)     // pop top object off stack",
   "Dup                 0  (type)     // duplicate object ref on top of stack",
   "Is                  2  (type)     // is operator",
   "As                  2  (type)     // as operator",
   "Coerce              4  (typePair) // from->to coercion value/reference/nullable",
   "Switch              0  ()         // switch jump table 2 count + 2*count",

   "Throw               0  ()         // throw Err on top of stack",
   "Leave               2  (jmp)      // jump out of a try or catch block",
   "JumpFinally         2  (jmp)      // jump to a finally block",
   "CatchAllStart       0  ()         // start catch all block - do not leave Err on stack",
   "CatchErrStart       2  (type)     // start catch block - leave typed Err on stack",
   "CatchEnd            0  ()         // start catch block - leave typed Err on stack",
   "FinallyStart        0  ()         // starting instruction of a finally block",
   "FinallyEnd          0  ()         // ending instruction of a finally block",
 ]

#####################################################################
# Fan
#####################################################################

def fanHeader(typeKeyword, className)
<<FAN_HEADER
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   #{Time.now.strftime("%d %b %y")}  Auto-generated by /adm/genfcode.rb
//

**
** #{className} provides all the fcode constants
**
#{typeKeyword} #{className}
{
FAN_HEADER
end

@@fanOpFooter = <<FAN_OP_FOOTER

  private new make(FOpArg arg := FOpArg.None) { this.arg = arg }

  const FOpArg arg
}

**************************************************************************
** FOpArg
**************************************************************************

enum class FOpArg
{
  None,
  Int,
  Float,
  Decimal,
  Str,
  Duration,
  Uri,
  Register,
  TypeRef,
  FieldRef,
  MethodRef,
  Jump,
  TypePair
}
FAN_OP_FOOTER

  def genFan()
    filename = File.join(@src_compiler, "fan", "fcode", "FConst.fan")
    File.open(filename, "w") do |f|
      f << fanHeader("mixin", "FConst")
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// Stuff\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@stuff.each {|s| f << "  const static Str #{s.gsub('=', ':=').gsub(';', '')}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// Flags\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@flags.each {|s| f << "  const static Int #{s.gsub('=', ':=').gsub(';', '')}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// MethodVarFlags\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@methodVarFlags.each {|s| f << "  const static Int #{s.gsub('=', ':=').gsub(';', '')}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// Attributes\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@attributes.each {|s| f << "  const static Str #{s.gsub('=', ':=').gsub(';', '')}\n"}

#      f << "\n"
#      f << "//////////////////////////////////////////////////////////////////////////\n"
#      f << "// OpCodes\n"
#      f << "//////////////////////////////////////////////////////////////////////////\n"
#      f << "\n"
#      @@opcodes.each_index do |i|
#        line = @@opcodes[i];
#        line, comment = line.split("//")
#        name, skip, sig = line.split(' ')
#        name = name.gsub("Compare", "Cmp").ljust(16)
#        istr = i.to_s.rjust(3)
#        sig = sig.ljust(8)
#        f << "  static readonly Int #{name} := #{istr} // #{sig} #{comment}\n"
#      end

      f << "\n"
      f << "}\n"
    end

    filename = File.join(@src_compiler, "fan", "fcode", "FOp.fan")
    File.open(filename, "w") do |f|
      f << fanHeader("enum class", "FOp")
      @@opcodes.each_index do |i|
        line = @@opcodes[i];
        line, comment = line.split("//")
        name, size, sig = line.split(' ')
        name = name.gsub("Compare", "Cmp").ljust(18)
        id = i.to_s.rjust(3)
        sig = sig[1..-2]

        arg = {""=>"",
               "int"=>"FOpArg.Int",
               "float"=>"FOpArg.Float",
               "decimal"=>"FOpArg.Decimal",
               "str"=>"FOpArg.Str",
               "dur"=>"FOpArg.Duration",
               "uri"=>"FOpArg.Uri",
               "reg"=>"FOpArg.Register",
               "jmp"=>"FOpArg.Jump",
               "type"=>"FOpArg.TypeRef",
               "field"=>"FOpArg.FieldRef",
               "method"=>"FOpArg.MethodRef",
               "typePair"=>"FOpArg.TypePair"}[sig]
        arg = "(" + arg + ")"
        arg = arg + "," unless (i == @@opcodes.length-1)
        arg = arg.ljust(20)

        f << "  #{name} #{arg} // #{id} #{comment}\n"
      end
      f << @@fanOpFooter
    end

  end

#####################################################################
# Java
#####################################################################

@@javaHeader = <<JAVA_HEADER
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   #{Time.now.strftime("%d %b %y")}  Auto-generated by /adm/genfcode.rb
//
package fanx.fcode;

/**
 * FConst provides all the fcode constants
 */
public interface FConst
{
JAVA_HEADER

  def genJava()
    filename = File.join(@src_jfan, "fanx", "fcode", "FConst.java")
    File.open(filename, "w") do |f|
      f << @@javaHeader
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// Stuff\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@stuff.each {|s| f << "  public static final String #{s}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// Flags\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@flags.each {|s| f << "  public static final int #{s}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// MethodVarFlags\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@methodVarFlags.each {|s| f << "  public static final int #{s}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// Attributes\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@attributes.each {|s| f << "  public static final String #{s}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// OpCodes\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@opcodes.each_index do |i|
        line = @@opcodes[i];
        line, comment = line.split("//")
        name, skip, sig = line.split(' ')
        name = name.ljust(15)
        istr = i.to_s.rjust(3)
        sig = sig.ljust(8)
        f << "  public static final int #{name} = #{istr}; // #{sig} #{comment}\n"
      end
      f << "\n"

      f << "  public static final String[] OpNames =\n"
      f << "  {\n"
      @@opcodes.each_index do |i|
        line = @@opcodes[i];
        line, comment = line.split("//");
        name, skip, sig = line.split(' ');
        name = ("\"" + name + "\",").ljust(20)
        istr = i.to_s.rjust(3)
        f << "    #{name}  // #{istr} \n"
      end
      f << "  };\n";
      f << "\n"

      f << "  public static final int[] OpSkips =\n"
      f << "  {\n"
      @@opcodes.each_index do |i|
        line = @@opcodes[i];
        line, comment = line.split("//");
        name, skip, sig = line.split(' ');
        istr = i.to_s.rjust(3)
        f << "    #{skip},  // #{istr} #{name} \n"
      end
      f << "  };\n";
      f << "\n"

      f << "  public static final String[] OpSigs =\n"
      f << "  {\n"
      @@opcodes.each_index do |i|
        line = @@opcodes[i];
        line, comment = line.split("//");
        name, skip, sig = line.split(' ');
        sig = ("\"" + sig  + "\",").ljust(12)
        istr = i.to_s.rjust(3)
        f << "    #{sig}  // #{istr} #{name}\n"
      end
      f << "  };\n";
      f << "\n"
      f << "}\n"
    end
  end

#####################################################################
# .NET
#####################################################################

@@netHeader = <<NET_HEADER
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   #{Time.now.strftime("%d %b %y")}  Auto-generated by /adm/genfcode.rb
//
namespace Fanx.Fcode
{

/**
 * FConst provides all the fcode constants
 */
public class FConst
{
NET_HEADER

  def genNet()
    filename = File.join(@src_nfan, "fanx", "fcode", "FConst.cs")
    File.open(filename, "w") do |f|
      f << @@netHeader
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// Stuff\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@stuff.each {|s| f << "  public const string #{s}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// Flags\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@flags.each {|s| f << "  public const int #{s}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// MethodVarFlags\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@methodVarFlags.each {|s| f << "  public const int #{s}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// Attributes\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@attributes.each {|s| f << "  public const string #{s}\n"}
      f << "\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "// OpCodes\n"
      f << "//////////////////////////////////////////////////////////////////////////\n"
      f << "\n"
      @@opcodes.each_index do |i|
        line = @@opcodes[i];
        line, comment = line.split("//")
        name, skip, sig = line.split(' ')
        name = name.ljust(16)
        istr = i.to_s.rjust(3)
        sig = sig.ljust(8)
        f << "  public const int #{name} = #{istr}; // #{sig} #{comment}\n"
      end
      f << "\n"

      f << "  public static readonly string[] OpNames =\n"
      f << "  {\n"
      @@opcodes.each_index do |i|
        line = @@opcodes[i];
        line, comment = line.split("//");
        name, skip, sig = line.split(' ');
        name = ("\"" + name + "\",").ljust(20)
        istr = i.to_s.rjust(3)
        f << "    #{name}  // #{istr} \n"
      end
      f << "  };\n";
      f << "\n"

      f << "  public static readonly int[] OpSkips =\n"
      f << "  {\n"
      @@opcodes.each_index do |i|
        line = @@opcodes[i];
        line, comment = line.split("//");
        name, skip, sig = line.split(' ');
        istr = i.to_s.rjust(3)
        f << "    #{skip},  // #{istr} #{name} \n"
      end
      f << "  };\n";
      f << "\n"

      f << "  public static readonly string[] OpSigs =\n"
      f << "  {\n"
      @@opcodes.each_index do |i|
        line = @@opcodes[i];
        line, comment = line.split("//");
        name, skip, sig = line.split(' ');
        sig = ("\"" + sig  + "\",").ljust(12)
        istr = i.to_s.rjust(3)
        f << "    #{sig}  // #{istr} #{name}\n"
      end
      f << "  };\n";
      f << "\n"
      f << "} // FConst\n"
      f << "\n\n} // Fanx.Fcode\n"
    end
  end

#####################################################################
# Main
#####################################################################

  # main
  def main()
    genJava()
    genFan()
    genNet()
  end

end


# script
GenFConst.new.main