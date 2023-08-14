//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class DomFilePeer extends sys.Obj {

  constructor(self)
  {
    super();
    this.file = null;
  }

  /*
  * Native only method to wrap an existing DOM File instance.
  * If this node has already been wrapped by an DomFile instance,
  * return the existing instance.
  */
  static wrap(file)
  {
    if (!file) throw sys.ArgErr.make("file is null")

    if (file._fanFile)
      return file._fanFile;

    const x = DomFile.make();
    x.peer.file = file;
    file._fanFile = x;
    return x;
  }

  name(self)
  {
    return this.file.name;
  }

  size(self)
  {
    return this.file.size;
  }

  type(self)
  {
    return this.file.type;
  }

  readAsDataUri(self, func)
  {
    const reader = new FileReader();
    reader.onload = function(e) {
      const uri = sys.Uri.decode(e.target.result.toString());
      func(uri);
    }
    reader.readAsDataURL(this.file);
  }

  readAsText(self, func)
  {
    const reader = new FileReader();
    reader.onload = function(e) {
      func(e.target.result);
    }
    reader.readAsText(this.file);
  }
}