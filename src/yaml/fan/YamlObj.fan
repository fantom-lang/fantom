#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    5 Jul 2022  Kiera O'Flynn   Creation
//

using util

**************************************************************************
** YamlObj
**************************************************************************

**
** The base class for objects that represent nodes in a YAML hierarchy.
** The key information for each node is its tag and content.
**
** See the [pod documentation]`yaml::pod-doc` for more information.
**
@Serializable
abstract const class YamlObj
{

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** The node's tag. Either a specific tag (e.g. 'tag:yaml.org,2002:str')
  ** or the non-specific tag '?'.
  const Str tag     := "?"

  ** The node's content. [YamlScalars]`yaml::YamlScalar` always have
  ** content of type 'Str', [YamlLists]`yaml::YamlList` with content
  ** type 'YamlObj[]', and [YamlMaps]`yaml::YamlMap` with 'YamlObj:YamlObj'.
  const Obj content := 0 //the "?" and 0 are placeholders

  ** The text location from which this node was parsed.
  const FileLoc loc := FileLoc.unknown

//////////////////////////////////////////////////////////////////////////
// Public methods
//////////////////////////////////////////////////////////////////////////

  ** Convenience for [schema.decode]`yaml::YamlSchema.decode`.
  Obj? decode(YamlSchema schema := YamlSchema.core) { schema.decode(this) }

  ** Transforms the YAML object back into a string, using block style where
  ** applicable. The result ends with '\n' and may span multiple lines.
  Void write(OutStream out := Env.cur.out) { writeInd(out, 0) }

  // Helper method for write
  // first - indentation on first line, next - indentation on following lines
  abstract internal Void writeInd(OutStream out, Int first, Int next := first)

//////////////////////////////////////////////////////////////////////////
// Obj overrides
//////////////////////////////////////////////////////////////////////////

  ** Two YamlObjs are equal if they have the same type, same tag, and
  ** same content.
  override Bool equals(Obj? that)
  {
    this.typeof == that?.typeof &&
    this.tag == (that as YamlObj).tag &&
    this.content == (that as YamlObj).content
  }

  ** Hash is based on tag and content
  override Int hash() { 31 * tag.hash + content.hash }

  ** Returns 'write' written into a string.
  override Str toStr()
  {
    buf := StrBuf()
    write(buf.out)
    return buf.toStr
  }
}

**************************************************************************
** YamlScalar
**************************************************************************

**
** A YamlObj whose content always has the type 'Str'.
** For example, each item on the list below is a scalar:
**
** pre>
**  - This is a plain scalar
**  - "This is a string"
**  - !!int 5
** <pre
**
const class YamlScalar : YamlObj
{
  // content : Str

  ** Creates a YamlScalar with the string 's' as content
  ** and 'tag' as its tag.
  new make(Str s, Str tag := "?", FileLoc loc := FileLoc.unknown)
  {
    this.content = s
    this.loc = loc

    if (tag == "!")     this.tag = "tag:yaml.org,2002:str"
    else if (tag != "") this.tag = tag
    else                this.tag = "?"
  }

  override internal Void writeInd(OutStream out, Int first, Int next := first)
  {
    out.writeChars(" " * first)

    if (tag == "?")
    // Plain scalar
    {
      //cover when a plain scalar contains '\n'
      out.writeChars(Regex("\\n(?=.)").matcher(content).replaceAll("\n\n" + (" " * next)) + "\n")
    }
    else
    // Non-plain - use quotation marks & escape chars
    {
      if (tag != "tag:yaml.org,2002:str")
        out.writeChars("!<$tag> ")

      out.writeChar('"')

      (content as Str).each |c|
      {
        // Escape chars
        switch(c)
        {
          case 0x00:   out.writeChars("\\0")
          case 0x07:   out.writeChars("\\a")
          case 0x08:   out.writeChars("\\b")
          case 0x09:   out.writeChars("\\t")
          case 0x0A:   out.writeChars("\\n")
          case 0x0B:   out.writeChars("\\v")
          case 0x0C:   out.writeChars("\\f")
          case 0x0D:   out.writeChars("\\r")
          case 0x1B:   out.writeChars("\\e")
          case 0x22:   out.writeChars("\\\"")
          case 0x5C:   out.writeChars("\\\\")
          case 0x85:   out.writeChars("\\N")
          case 0xA0:   out.writeChars("\\_")
          case 0x2028: out.writeChars("\\L")
          case 0x2029: out.writeChars("\\P")
          default:
            if (YamlTokenizer.isPrintable(c)) out.writeChar(c)
            else if (c < 0x100)   out.writeChars("\\x${c.toHex(2)}")
            else if (c < 0x10000) out.writeChars("\\u${c.toHex(4)}")
            else                  out.writeChars("\\U${c.toHex(8)}")
        }
      }
      out.writeChars("\"\n")
    }
  }
}

**************************************************************************
** YamlList
**************************************************************************

**
** A YamlObj whose content always has the type 'YamlObj[]'.
** For example, each item on the list below is itself a list:
**
** pre>
**  - - a
**    - b
**    - c
**  - [a, b, c]
** <pre
**
const class YamlList : YamlObj
{
  // content : YamlObj[]

  ** Creates a YamlList with the list 's' as content
  ** and 'tag' as its tag.
  new make(YamlObj[] s, Str tag := "!", FileLoc loc := FileLoc.unknown)
  {
    this.content = s
    this.loc = loc

    if (tag == "!" || tag == "") this.tag = "tag:yaml.org,2002:seq"
    else                         this.tag = tag
  }

  ** Content as a list
  YamlObj[] list() { content }

  ** Iterate the list items
  Void each(|YamlObj| f)
  {
    ((YamlObj[])content).each(f)
  }

  override internal Void writeInd(OutStream out, Int first, Int next := first)
  {
    // special case - this is the overarching document collection, indentation ignored
    if (tag == "tag:yaml.org,2002:stream")
      writeStream(out)

    // normal list
    else
    {
      contList := content as YamlObj[]
      isEmpty := contList.size == 0
      isTagged := tag != "?" && tag != "tag:yaml.org,2002:seq"

      if (isTagged)
        out.writeChars((" " * first) + "!<$tag>" + (isEmpty ? " " : "\n"))
      else if (isEmpty)
        out.writeChars(" " * first)

      if (isEmpty) out.writeChars("[]\n")
      else contList.each |v, i|
      {
        out.writeChars(" " * ((i == 0 && !isTagged) ? first : next))
        out.writeChars("- ")
        v.writeInd(out, 0, next + 2)
      }
    }
  }

  ** Writes the content as a stream of YAML documents instead of a list
  private Void writeStream(OutStream out)
  {
    contList := content as YamlObj[]

    if (contList.size != 0)
      out.writeChars("%YAML 1.2\n")
    contList.each |v|
    {
      out.writeChars("---\n")
      v.write(out)
    }
  }
}

**************************************************************************
** YamlMap
**************************************************************************

**
** A YamlObj whose content always has the type 'YamlObj:YamlObj'.
** For example, each item on the list below is a map:
**
** pre>
**  - foo: bar
**    a: b
**  - {foo: bar, a: b}
** <pre
**
const class YamlMap : YamlObj
{
  // content : [YamlObj:YamlObj]

  ** Creates a YamlMap with the map 's' as content
  ** and 'tag' as its tag.
  new make([YamlObj:YamlObj] s, Str tag := "!", FileLoc loc := FileLoc.unknown)
  {
    this.content = s
    this.loc = loc

    if (tag == "!" || tag == "") this.tag = "tag:yaml.org,2002:map"
    else                         this.tag = tag
  }

  ** Content as a map
  [YamlObj:YamlObj] map() { content }

  override internal Void writeInd(OutStream out, Int first, Int next := first)
  {
    contMap := content as YamlObj:YamlObj
    isEmpty := contMap.keys.size == 0
    isTagged := tag != "?" && tag != "tag:yaml.org,2002:map"

    if (isTagged)
      out.writeChars((" " * first) + "!<$tag>" + (isEmpty ? " " : "\n"))
    else if (isEmpty)
      out.writeChars(" " * first)

    if (isEmpty) out.writeChars("{}\n")
    else contMap.keys.each |k,i|
    {
      v := contMap[k]
      out.writeChars(" " * ((i == 0 && !isTagged) ? first : next))

      buf := StrBuf()
      k.writeInd(buf.out, 0, next)
      kStr := buf.toStr[0..-2] //strip ending '\n'

      // Key fits on single line
      if ((k.typeof == YamlScalar# || k.content == YamlObj[,] || k.content == [YamlObj:YamlObj][:]) &&
          !kStr.containsChar('\n') &&
          kStr.size <= 1024)
      {
        out.writeChars(kStr + ":")

        // Scalar
        if (v.typeof == YamlScalar# || v.content == YamlObj[,] || v.content == [YamlObj:YamlObj][:])
          v.writeInd(out, 1, next + 1)
        // Non-scalar
        else
        {
          out.writeChar('\n')
          v.writeInd(out, next + 1)
        }
      }

      // Key must be explicit
      else
      {
        out.writeChar('?')
        k.writeInd(out, 1, next + 2)
        out.writeChars((" " * next) + ":")
        v.writeInd(out, 1, next + 2)
      }
    }
  }
}