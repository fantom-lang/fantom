#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jul 2022  Kiera O'Flynn   Creation
//

using util

**
** Converts YAML text into a hierarchy of [YamlObjs]`yaml::YamlObj`,
** which can in turn be converted into native Fantom objects.
**
** See the [pod documentation]`yaml::pod-doc` for more information.
**
class YamlReader
{
  ** Creates a new YamlReader that reads YAML content from the
  ** given InStream, optionally tracking file location data.
  new make(InStream in, FileLoc loc := FileLoc.unknown)
  {
    p = YamlParser(in, loc)
  }

  ** Creates a new YamlReader that reads YAML content from the
  ** given file.
  new makeFile(File file) : this.make(file.in, FileLoc(file)) {}

  ** Parses the input stream as YAML content, returning
  ** each document as its own YamlObj within a larger
  ** YamlList.
  YamlList parse()
  {
    // Return a YamlList with the parsed list of documents
    // tagged as a !!stream
    YamlList(p.parse, "tag:yaml.org,2002:stream")
  }

  private YamlParser p
}