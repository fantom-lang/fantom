//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System.Collections;
using Fan.Sys;

namespace Fanx.Util
{
  /// <summary>
  /// TypeParser is used to parser formal type signatures which are
  /// used in Sys.type() and in fcode for typeRefs.def.  Signatures
  /// are formated as (with arbitrary nesting):
  ///
  ///   x::N
  ///   x::V[]
  ///   x::V[x::K]
  ///   |x::A, ... -> x::R|
  /// </summary>
  public class TypeParser
  {

  //////////////////////////////////////////////////////////////////////////
  // Factory
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Parse the signature into a loaded type.
    /// </summary>
    public static Type load(string sig, bool check, Pod loadingPod)
    {
      // if last character is ?, then parse a nullable
      int len = sig.Length;
      int last = len > 1 ? sig[len-1] : 0;
      if (last == '?')
        return load(sig.Substring(0, len-1), check, loadingPod).toNullable();

      // if the last character isn't ] or |, then this a non-generic
      // type and we don't even need to allocate a parser
      if (last != ']' && last != '|')
      {
        string podName, typeName;
        try
        {
          int colon = sig.IndexOf(':');
          if (sig[colon+1] != ':') throw new System.Exception();
          podName  = sig.Substring(0, colon);
          typeName = sig.Substring(colon+2);
          if (podName.Length == 0 || typeName.Length == 0) throw new System.Exception();
        }
        catch (System.Exception)
        {
          throw ArgErr.make("Invalid type signature '" + sig + "', use <pod>::<type>").val;
        }

        // if the type is from the pod being loaded then return to the pod
        if (loadingPod != null && podName == loadingPod.name())
          return loadingPod.type(typeName, check);

        // do a straight lookup
        return find(podName, typeName, check);
      }

      // we got our work cut out for us - create parser
      try
      {
        return new TypeParser(sig, check, loadingPod).LoadTop();
      }
      catch (Err.Val e)
      {
        throw e;
      }
      catch (System.Exception)
      {
        throw Err(sig).val;
      }
    }

    public static Type find(string podName, string typeName, bool check)
    {
      Pod pod = Pod.find(podName, check);
      if (pod == null) return null;
      return pod.type(typeName, check);
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    private TypeParser(string sig, bool check, Pod loadingPod)
    {
      this.sig        = sig;
      this.len        = sig.Length;
      this.pos        = 0;
      this.cur        = sig[pos];
      this.peek       = sig[pos+1];
      this.check      = check;
      this.loadingPod = loadingPod;
    }

  //////////////////////////////////////////////////////////////////////////
  // Parse
  //////////////////////////////////////////////////////////////////////////

    private Type LoadTop()
    {
      Type type = Load();
      if (cur != 0) throw Err().val;
      return type;
    }

    private Type Load()
    {
      Type type;

      // |...| is method
      if (cur == '|')
        type = LoadMethod();

      // [...] is map
      else if (cur == '[')
        type = LoadMap();

      // otherwise must be basic[]
      else
        type = LoadBasic();

      // nullable
      if (cur == '?')
      {
        Consume('?');
        type = type.toNullable();
      }

      // anything left must be []
      while (cur == '[')
      {
        Consume('[');
        Consume(']');
        type = type.toListOf();
        if (cur == '?')
        {
          Consume('?');
          type = type.toNullable();
        }
      }

      // nullable
      if (cur == '?')
      {
        Consume('?');
        type = type.toNullable();
      }

      return type;
    }

    private Type LoadMap()
    {
      Consume('[');
      Type key = Load();
      Consume(':');
      Type val = Load();
      Consume(']');
      return new MapType(key, val);
    }

    private Type LoadMethod()
    {
      Consume('|');
      ArrayList pars = new ArrayList(8);
      if (cur != '-')
      {
        while (true)
        {
          pars.Add(Load());
          if (cur == '-') break;
          Consume(',');
        }
      }
      Consume('-');
      Consume('>');
      Type ret = Load();
      Consume('|');

      return new FuncType((Type[])pars.ToArray(System.Type.GetType("Fan.Sys.Type")), ret);
    }

    private Type LoadBasic()
    {
      string podName = ConsumeId();
      Consume(':');
      Consume(':');
      string typeName = ConsumeId();

      // check for generic parameter like sys::V
      if (typeName.Length == 1 && podName == "sys")
      {
        Type type = Sys.genericParamType(typeName);
        if (type != null) return type;
      }

      if (loadingPod != null && podName == loadingPod.name())
        return loadingPod.type(typeName, check);
      else
        return find(podName, typeName, check);
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    private string ConsumeId()
    {
      int start = pos;
      while (Tokenizer.IsIdChar(cur)) Consume();
      return sig.Substring(start, pos-start);
    }

    private void Consume(int expected)
    {
      if (cur != expected) throw Err().val;
      Consume();
    }

    private void Consume()
    {
      cur = peek;
      pos++;
      peek = pos+1 < len ? sig[pos+1] : 0;
    }

    private Err Err() { return Err(sig); }
    private static Err Err(string sig)
    {
      return ArgErr.make("Invalid type signature '" + sig + "'");
    }

  //////////////////////////////////////////////////////////////////////////
  // Tokenizer
  //////////////////////////////////////////////////////////////////////////

    class Tokenizer
    {
      /// <summary>
      /// Is the specified char a valid name identifier character.
      /// </summary>
      public static bool IsIdChar(int ch)
      {
        int type = ch < 128 ? charMap[ch] : ALPHA;
        return type == ALPHA || type == DIGIT;
      }

      private static readonly byte[] charMap = new byte[128];
      private static readonly byte SPACE = 1;
      private static readonly byte ALPHA = 2;
      private static readonly byte DIGIT = 3;
      static Tokenizer()
      {
        // space characters; note \r is error in symbol()
        charMap[' ']  = SPACE;
        charMap['\n'] = SPACE;
        charMap['\t'] = SPACE;

        // alpha characters
        for (int i='a'; i<='z'; i++) charMap[i] = ALPHA;
        for (int i='A'; i<='Z'; i++) charMap[i] = ALPHA;
        charMap['_'] = ALPHA;

        // digit characters
        for (int i='0'; i<='9'; i++) charMap[i] = DIGIT;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private string sig;          // signature being parsed
    private int len;             // length of sig
    private int pos;             // index of cur in sig
    private int cur;             // cur character; sig[pos]
    private int peek;            // next character; sig[pos+1]
    private bool check;          // pass thru check flag
    private Pod loadingPod;      // used to map types within a loading pod
  }
}