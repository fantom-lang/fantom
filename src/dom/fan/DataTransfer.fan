//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 2015  Andy Frank  Creation
//

**
** The DataTransfer object is used to hold the data that is being dragged
** during a drag and drop operation.
**
@Js
class DataTransfer
{
  ** The effect used for drop targets.
  native Str dropEffect

  ** The effects that are allowed for this drag.
  native Str effectAllowed

  ** List of the format types of data, in the same order the data was added.
  native Str[] types()

  ** Get data for given MIME type, or an empty string if data for that type
  ** does not exist or the data transfer contains no data.
  native Str getData(Str type)

  ** Set data for given MIME type.
  native This setData(Str type, Str val)
}