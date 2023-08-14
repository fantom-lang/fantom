//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 2023  Brian Frank  Creation
//

using graphics

**
** HttpSocket implements an async WebSocket client
**
@Js
native class HttpSocket
{
  ** Open a web socket to given URI with sub-protocol list
  static HttpSocket open(Uri uri, Str[]? protocols)

  ** Private constructor
  private new make()

  ** Uri passed to the open method
  Uri uri()

  ** Send the data as a message - data must be a Str or in-memory Buf
  This send(Obj data)

  ** Close the web socket.
  This close()

  ** Event fired when the web socket is opened
  Void onOpen(|Event| f)

  ** Event fired when the web socket receives a message.
  ** The message payload is available as a Str or Buf via `Event.data`
  Void onReceive(|Event| f)

  ** Event fired when the web socket is closed
  Void onClose(|Event| f)

  ** Event fired when the web socket is closed due to an error
  Void onError(|Event| f)
}

