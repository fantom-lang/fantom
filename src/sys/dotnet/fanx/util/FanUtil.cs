//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.Text;

namespace Fanx.Util
{
  /// <summary>
  /// Utilites for dealing with type names in .NET.
  /// </summary>
  public class FanUtil
  {
    /// <summary>
    /// Convert .NET type to Fantom type.
    /// </summary>
    public static Fan.Sys.Type toFanType(Type dotnetType, bool check)
    {
      Fan.Sys.Type t = (Fan.Sys.Type)dotnetToFanTypes[dotnetType.FullName];
      if (t != null) return t;
      if (!check) return null;
      throw Fan.Sys.Err.make("Not a Fantom type: " + dotnetType).val;
    }

    /// <summary>
    /// Return if the specified .NET type represents an immutable type.
    /// </summary>
    public static bool isDotnetImmutable(Type dotnetType)
    {
      return dotnetImmutables[dotnetType.FullName] != null;
    }

    /// <summary>
    /// Return if the Fantom Type is represented as a .NET class
    /// such as sys::Int as Fan.Sys.Long.
    /// </summary>
    public static bool isDotnetRepresentation(Fan.Sys.Type t)
    {
      if (t.pod() != Fan.Sys.Sys.m_sysPod) return false;
      return t == Fan.Sys.Sys.ObjType   ||
             t == Fan.Sys.Sys.BoolType  ||
             t == Fan.Sys.Sys.StrType   ||
             t == Fan.Sys.Sys.IntType   ||
             t == Fan.Sys.Sys.FloatType ||
             t == Fan.Sys.Sys.NumType   ||
             t == Fan.Sys.Sys.DecimalType;
    }

    /// <summary>
    /// Return the .NET type name for this Fantom type.
    /// </summary>
    public static string toDotnetTypeName(Fan.Sys.Type type)
    {
      return toDotnetTypeName(type.pod().name(), type.name(), type.isNullable());
    }

    /// <summary>
    /// Return the .NET type name for this Fantom pod and type.
    /// </summary>
    public static string toDotnetTypeName(string podName, string typeName, bool nullable)
    {
      if (podName == "sys")
      {
        switch (typeName[0])
        {
          case 'B':
            if (typeName == "Bool") return nullable ? "Fan.Sys.Boolean" : "System.Boolean";
            break;
          case 'D':
            if (typeName == "Decimal") return "Fan.Sys.BigDecimal";
            break;
          case 'F':
            if (typeName == "Float") return nullable ? "Fan.Sys.Double" : "System.Double";
            break;
          case 'I':
            if (typeName == "Int") return nullable ? "Fan.Sys.Long" : "System.Int64";
            break;
          case 'N':
            if (typeName == "Num") return "Fan.Sys.Number";
            break;
          case 'O':
            if (typeName == "Obj") return "System.Object";
            break;
          case 'S':
            if (typeName == "Str") return "System.String";
            break;
          //case 'V':
          //  if (typeName.equals("Void")) return "System.Void";
          //  break;
        }
      }
      return "Fan." + FanUtil.upper(podName, false) + "." + typeName;
    }

    /// <summary>
    /// Given a Fantom qname, get the .NET implementation class name:
    /// </summary>
    public static string toDotnetImplTypeName(string podName, string typeName)
    {
      if (podName == "sys")
      {
        switch (typeName[0])
        {
          case 'B':
            if (typeName == "Bool") return "Fan.Sys.FanBool";
            break;
          case 'D':
            if (typeName == "Decimal") return "Fan.Sys.FanDecimal";
            break;
          case 'F':
            if (typeName == "Float") return "Fan.Sys.FanFloat";
            break;
          case 'I':
            if (typeName == "Int") return "Fan.Sys.FanInt";
            break;
          case 'N':
            if (typeName == "Num") return "Fan.Sys.FanNum";
            break;
          case 'O':
            if (typeName == "Obj") return "Fan.Sys.FanObj";
            break;
          case 'S':
            if (typeName == "Str") return "Fan.Sys.FanStr";
            break;
        }
      }
      return "Fan." + FanUtil.upper(podName, false) + "." + typeName;
    }

    /// <summary>
    /// Given a .NET type signature, return the implementation
    /// class signature for methods and fields:
    /// </summary>
    public static string toDotnetImplTypeName(string ntype)
    {
      if (ntype[0] == 'S')
      {
        if (ntype == "System.Boolean") return "Fan.Sys.FanBool";
        if (ntype == "System.Double") return "Fan.Sys.FanFloat";
        if (ntype == "System.Int64") return "Fan.Sys.FanInt";
        if (ntype == "System.String") return "Fan.Sys.FanStr";
        if (ntype == "System.Object") return "Fan.Sys.FanObj";
      }
      if (ntype[0] == 'F')
      {
        if (ntype == "Fan.Sys.BigDecimal") return "Fan.Sys.FanDecimal";
        if (ntype == "Fan.Sys.Number") return "Fan.Sys.FanNum";
      }
      return ntype;
    }

    /// <summary>
    /// Return the .NET method name for this Fantom method name.
    /// </summary>
    public static string toDotnetMethodName(string fanName)
    {
      if (fanName == "equals") return "Equals";
      return fanName;
    }

    /// <summary>
    /// Return the Fantom method name for this .NET method name.
    /// </summary>
    public static string toFanMethodName(string dotnetName)
    {
      if (dotnetName == "Equals") return "equals";
      return dotnetName;
    }

    /// <summary>
    /// Given a Fantom type, get its stack type: 'A', 'I', 'J', etc
    /// </summary>
    public static int toDotnetStackType(Fan.Sys.Type t)
    {
      if (!t.isNullable())
      {
        if (t == Fan.Sys.Sys.VoidType)  return 'V';
        if (t == Fan.Sys.Sys.BoolType)  return 'I';
        if (t == Fan.Sys.Sys.IntType)   return 'J';
        if (t == Fan.Sys.Sys.FloatType) return 'D';
      }
      return 'A';
    }

    /// <summary>
    /// If the given object is a .NET primitive, make it as
    /// a Fantom type, otherwise return obj.
    /// </summary>
    public static object box(object obj)
    {
      if (obj is bool) return Fan.Sys.Boolean.valueOf((bool)obj);
      if (obj is double) return Fan.Sys.Double.valueOf((double)obj);
      if (obj is long) return Fan.Sys.Long.valueOf((long)obj);
      return obj;
    }

    /// <summary>
    /// Return a new string, where the first letter is uppercase.
    /// If the string is a fully qualified type name, make each
    /// character following a '.' uppercase as well.
    /// </summary>
    public static string upper(string str) { return upper(str, true); }
    public static string upper(string str, bool recurse)
    {
      if (str.Length <= 1) return str.ToUpper();

      // Always first letter
      Char[] chars = str.ToCharArray();
      chars[0] = Char.ToUpper(chars[0]);

      if (recurse)
      {
        // Check for namespace
        for (int i=0; i<chars.Length-1; i++)
          if (chars[i] == '.')
            chars[i+1] = Char.ToUpper(chars[i+1]);
      }

      return new string(chars);
    }

    /// <summary>
    /// If the qualifed type name is a Fantom type, then return
    /// the pod name the type should belong to, which should
    /// also be the assembly name.  If the type name does not
    /// appear to be a Fantom type, return null.
    /// </summary>
    public static string getPodName(string qname)
    {
      if (!qname.StartsWith("Fan.")) return null;

      // Must have one more '.'
      int index = qname.IndexOf('.', 5);
      if (index == -1) return null;

      // Make first char lower case
      StringBuilder s = new StringBuilder(qname.Substring(4, index-4));
      s[0] = Char.ToLower(s[0]);
      return s.ToString();
    }

    /// <summary>
    /// Split a qualifed type name into two strings, where
    /// s[0] is the namespace, and s[1] is the simple type
    /// name.
    /// If qname represents a nested class, then s[0] will
    /// be the qualified type name of the parent, and s[1]
    /// will simply be the nested class name.
    /// If qname represnets a generic class, then s[0] will
    /// be the qualified type name of the class, and s[1]
    /// will be the generic param.
    /// </summary>
    public static string[] splitQName(string qname)
    {
      string[] s = new string[] { null, qname };
      int index = qname.LastIndexOf('/');
      if (index != -1)
      {
        s[0] = qname.Substring(0, index);
        s[1] = qname.Substring(index+1);
      }
      else
      {
//        index = qname.LastIndexOf('<');
//        if (index != -1)
//        {
//          s[0] = qname.Substring(0, index);
//          s[1] = qname.Substring(index+1, qname.Length-index-2);
//        }
//        else
//        {
          index = qname.LastIndexOf('.');
          if (index != -1)
          {
            s[0] = qname.Substring(0, index);
            s[1] = qname.Substring(index+1);
          }
//        }
      }
      return s;
    }

    private static Hashtable dotnetToFanTypes = new Hashtable();
    private static Hashtable dotnetImmutables = new Hashtable();

    static FanUtil()
    {
      if (Fan.Sys.Sys.ObjType == null)
      {
        System.Console.WriteLine("FanUtil.staticInit: ObjType == null");
        Fan.Sys.Sys.dumpStack();
      }

      dotnetToFanTypes["System.Boolean"]     = Fan.Sys.Sys.BoolType;
      dotnetToFanTypes["System.Double"]      = Fan.Sys.Sys.FloatType;
      dotnetToFanTypes["System.Int64"]       = Fan.Sys.Sys.IntType;
      dotnetToFanTypes["System.String"]      = Fan.Sys.Sys.StrType;
      dotnetToFanTypes["System.Object"]      = Fan.Sys.Sys.ObjType;
      dotnetToFanTypes["Fan.Sys.Boolean"]    = Fan.Sys.Sys.BoolType;
      dotnetToFanTypes["Fan.Sys.BigDecimal"] = Fan.Sys.Sys.DecimalType;
      dotnetToFanTypes["Fan.Sys.Double"]     = Fan.Sys.Sys.FloatType;
      dotnetToFanTypes["Fan.Sys.Long"]       = Fan.Sys.Sys.IntType;
      dotnetToFanTypes["Fan.Sys.Number"]     = Fan.Sys.Sys.NumType;

      dotnetImmutables["System.Boolean"]     = true;
      dotnetImmutables["System.Double"]      = true;
      dotnetImmutables["System.Int64"]       = true;
      dotnetImmutables["System.String"]      = true;
      dotnetImmutables["Fan.Sys.Boolean"]    = true;
      dotnetImmutables["Fan.Sys.BigDecimal"] = true;
      dotnetImmutables["Fan.Sys.Double"]     = true;
      dotnetImmutables["Fan.Sys.Long"]       = true;
      dotnetImmutables["Fan.Sys.Number"]     = true;
    }

  }
}