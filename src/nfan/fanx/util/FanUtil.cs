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
    /// Convert .NET type to Fan type.
    /// </summary>
    public static Fan.Sys.Type toFanType(Type netType, bool check)
    {
      Fan.Sys.Type t = (Fan.Sys.Type)netToFanTypes[netType.FullName];
      if (t != null) return t;
      if (!check) return null;
      throw Fan.Sys.Err.make("Not a Fan type: " + netType).val;
    }

    /// <summary>
    /// Return if the specified .NET type represents an immutable type.
    /// </summary>
    public static bool isNetImmutable(Type netType)
    {
      return netImmutables[netType.FullName] != null;
    }

    /// <summary>
    /// Return if the Fan Type is represented as a .NET class
    /// such as sys::Int as Fan.Sys.Long.
    /// </summary>
    public static bool isNetRepresentation(Fan.Sys.Type t)
    {
      if (t.pod() != Fan.Sys.Sys.SysPod) return false;
      return t == Fan.Sys.Sys.ObjType   ||
             t == Fan.Sys.Sys.BoolType  ||
             t == Fan.Sys.Sys.IntType   ||
             t == Fan.Sys.Sys.FloatType ||
             t == Fan.Sys.Sys.NumType   ||
             t == Fan.Sys.Sys.DecimalType;
    }

    /// <summary>
    /// Return the .NET type name for this Fan pod and type.
    /// </summary>
    public static string toNetTypeName(Fan.Sys.Str podName, Fan.Sys.Str typeName)
    {
      return toNetTypeName(podName.val, typeName.val);
    }

    /// <summary>
    /// Return the .NET type name for this Fan pod and type.
    /// </summary>
    public static string toNetTypeName(string podName, string typeName)
    {
      if (podName == "sys")
      {
        switch (typeName[0])
        {
          case 'B':
            if (typeName == "Bool") return "Fan.Sys.Boolean";
            break;
          case 'D':
            if (typeName == "Decimal") return "Fan.Sys.BigDecimal";
            break;
          case 'F':
            if (typeName == "Float") return "Fan.Sys.Double";
            break;
          case 'I':
            if (typeName == "Int") return "Fan.Sys.Long";
            break;
          case 'N':
            if (typeName == "Num") return "Fan.Sys.Number";
            break;
          case 'O':
            if (typeName == "Obj") return "System.Object";
            break;
        }
      }
      return "Fan." + FanUtil.upper(podName, false) + "." + typeName;
    }

    /// <summary>
    /// Given a Fan qname, get the .NET implementation class name:
    /// </summary>
    public static string toNetImplTypeName(string podName, string typeName)
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
        }
      }
      return "Fan." + FanUtil.upper(podName, false) + "." + typeName;
    }

    /// <summary>
    /// Given a .NET type signature, return the implementation
    /// class signature for methods and fields:
    ///   System.Object   =>  Fan.Sys.FanObj
    ///   Fan.Sys.Double  =>  Fan.Sys.FanFloat
    /// Anything else returns itself.
    /// </summary>
    public static string toNetImplTypeName(string ntype)
    {
      if (ntype[0] == 'S')
      {
        if (ntype == "System.Object")  return "Fan.Sys.FanObj";
      }
      if (ntype[0] == 'F')
      {
        if (ntype == "Fan.Sys.Boolean") return "Fan.Sys.FanBool";
        if (ntype == "Fan.Sys.BigDecimal") return "Fan.Sys.FanDecimal";
        if (ntype == "Fan.Sys.Double") return "Fan.Sys.FanFloat";
        if (ntype == "Fan.Sys.Long") return "Fan.Sys.FanInt";
        if (ntype == "Fan.Sys.Number") return "Fan.Sys.FanNum";
      }
      return ntype;
    }

    /// <summary>
    /// Return the .NET method name for this Fan method name.
    /// </summary>
    public static string toNetMethodName(string fanName)
    {
      if (fanName == "equals") return "_equals";
      return fanName;
    }

    /// <summary>
    /// Return the Fan method name for this .NET method name.
    /// </summary>
    public static string toFanMethodName(string netName)
    {
      if (netName == "_equals") return "equals";
      return netName;
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
    /// If the qualifed type name is a Fan type, then return
    /// the pod name the type should belong to, which should
    /// also be the assembly name.  If the type name does not
    /// appear to be a Fan type, return null.
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
        index = qname.LastIndexOf('.');
        if (index != -1)
        {
          s[0] = qname.Substring(0, index);
          s[1] = qname.Substring(index+1);
        }
      }
      return s;
    }

    private static Hashtable netToFanTypes = new Hashtable();
    private static Hashtable netImmutables = new Hashtable();

    static FanUtil()
    {
      netToFanTypes["System.Object"]      = Fan.Sys.Sys.ObjType;
      netToFanTypes["Fan.Sys.Boolean"]    = Fan.Sys.Sys.BoolType;
      netToFanTypes["Fan.Sys.BigDecimal"] = Fan.Sys.Sys.DecimalType;
      netToFanTypes["Fan.Sys.Double"]     = Fan.Sys.Sys.FloatType;
      netToFanTypes["Fan.Sys.Long"]       = Fan.Sys.Sys.IntType;
      netToFanTypes["Fan.Sys.Number"]     = Fan.Sys.Sys.NumType;

      netImmutables["Fan.Sys.Boolean"]    = true;
      netImmutables["Fan.Sys.BigDecimal"] = true;
      netImmutables["Fan.Sys.Double"]     = true;
      netImmutables["Fan.Sys.Long"]       = true;
      netImmutables["Fan.Sys.Number"]     = true;
    }

  }
}