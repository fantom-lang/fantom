//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//

fan.dom.DomFilePeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.dom.DomFilePeer.prototype.$ctor = function(self)
{
  this.file = null;
}

/*
 * Native only method to wrap an existing DOM File instance.
 * If this node has already been wrapped by an DomFile instance,
 * return the existing instance.
 */
fan.dom.DomFilePeer.wrap = function(file)
{
  if (file == null) throw fan.sys.ArgErr.make("file is null")

  if (file._fanFile != undefined)
    return file._fanFile;

  var x = fan.dom.DomFile.make();
  x.peer.file = file;
  file._fanFile = x;
  return x;
}

fan.dom.DomFilePeer.prototype.$name = function(self)
{
  return this.file.name;
}

fan.dom.DomFilePeer.prototype.size = function(self)
{
  return this.file.size;
}

fan.dom.DomFilePeer.prototype.type = function(self)
{
  return this.file.type;
}

fan.dom.DomFilePeer.prototype.readAsDataUri = function(self, func)
{
  var reader = new FileReader();
  reader.onload = function(e) {
    var uri = fan.sys.Uri.decode(e.target.result.toString());
    func.call(uri);
  }
  reader.readAsDataURL(this.file);
}

fan.dom.DomFilePeer.prototype.readAsText = function(self, func)
{
  var reader = new FileReader();
  reader.onload = function(e) {
    func.call(e.target.result);
  }
  reader.readAsText(this.file);
}
