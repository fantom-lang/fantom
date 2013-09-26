//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 2011  Andy Frank  Creation
//

fan.webfwt.FileUploaderPeer = fan.sys.Obj.$extend(fan.fwt.PanePeer);
fan.webfwt.FileUploaderPeer.prototype.$ctor = function(self)
{
  fan.fwt.PanePeer.prototype.$ctor.call(this, self);
  this.files = fan.sys.List.make(fan.webfwt.FileUpload.$type);
}

fan.webfwt.FileUploaderPeer.prototype.create = function(parentElem, self)
{
  var $this = this;
  var div = fan.fwt.PanePeer.prototype.create.call(this, parentElem, self);

  // notify used for d-n-d
  var msg = document.createElement("div");
  with (msg.style)
  {
    width      = "100%";
    height     = "100%";
    fontSize   = "16px";
    fontWeight = "bold";
    color      = "#080";
    textAlign  = "center";
    paddingTop = "48px";
  }
  var notify = document.createElement("div");
  with (notify.style)
  {
    position   = "relative";
    top        = "0px";
    left       = "0px";
    display    = "none";
    background = "rgba(0, 204, 0, 0.4)";
    border     = "1px solid #080";
    zIndex     = "100";
    borderRadius = "10px";
  }
  msg.appendChild(document.createTextNode("DROP FILES HERE"));
  notify.appendChild(msg);
  div.appendChild(notify);
  this.notify = notify;
  this.initDragAndDrop(self, div);

  // create input
  var input = document.createElement("input");
  input.type = "file";
  input.name = "upload";
  if (self.m_multi) input.multiple = "multiple";
  input.style.position = "absolute";
  input.style.top = "45px";
  input.style.left = "12px";
  input.onchange = function() { $this.addFiles(self, input.files) }
  this.input = input;

  div.appendChild(input);
  return div;
}

fan.webfwt.FileUploaderPeer.prototype.sync = function(self)
{
  var w = this.m_size.m_w;
  var h = this.m_size.m_h;
  this.notify.style.width  = (w-2) + "px";
  this.notify.style.height = (h-2) + "px";
  fan.fwt.WidgetPeer.prototype.sync.call(this, self);
}

fan.webfwt.FileUploaderPeer.prototype.initDragAndDrop = function(self, div)
{
  var $this = this;

  div.addEventListener("dragenter", function(e)
  {
    //if ($this.onDone != null) return;
    e.stopPropagation();
    e.preventDefault();
    $this.notify.style.display = "block";
  }, false);

  div.addEventListener("dragover", function(e)
  {
    if ($this.onDone != null) return;
    e.stopPropagation();
    e.preventDefault();
  }, false);

  //div.addEventListener("dragleave", function(e)
  //{
  //  if ($this.isChild(div, e.target)) return;
  //  console.log(e.target);
  //  $this.notify.style.display = "none";
  //}, false);

  div.addEventListener("drop", function(e)
  {
    if ($this.onDone != null) return;
    e.stopPropagation();
    e.preventDefault();

    // verify inside drop zone
    if ($this.isChild($this.notify, e.target))
      $this.addFiles(self, e.dataTransfer.files);

    // hide notify
    $this.notify.style.display = "none";
  }, false);
}

fan.webfwt.FileUploaderPeer.prototype.isChild = function(parent, child)
{
  var elem = child;
  while (elem != null)
  {
    if (elem == parent) return true;
    elem = elem.parentNode;
  }
  return false;
}

fan.webfwt.FileUploaderPeer.prototype.addFiles = function(self, files)
{
  if (!self.m_multi) this.files.clear();

  for (var i=0; i<files.length; i++)
  {
    var f = files[i];

    // verify not already added
    var exists = false;
    for (var j=0; j<this.files.size(); j++)
      if (this.files.get(j).m_$name == f.name)
        exists = true;

    // add file
    if (!exists)
    {
      var fu = fan.webfwt.FileUpload.make();
      fu.m_$name = f.name;
      fu.m_file = f;
      this.files.add(fu);
    }
  }

  // notify change
  self.onFilesChanged(this.files);
}

fan.webfwt.FileUploaderPeer.prototype.onChoose = function(self)
{
  this.input.click();
}

fan.webfwt.FileUploaderPeer.prototype.onRemove = function(self, index)
{
  this.files.removeAt(index);
  self.onFilesChanged(this.files);
}

fan.webfwt.FileUploaderPeer.prototype.onClear = function(self)
{
  this.files.clear();
  self.onFilesChanged(this.files);
}

fan.webfwt.FileUploaderPeer.prototype.onSubmit = function(self)
{
  var $this = this;
  var uri = self.m_uri.toStr();

  // spawn XHR request for each file
  for (var i=0; i<this.files.size(); i++)
  {
    (function(file)
    {
      file.m_active   = true;
      file.m_waiting  = true;
      file.m_complete = false;

      var req  = new XMLHttpRequest();
      req.upload.onprogress = function(e)
      {
        file.m_waiting  = false;
        file.m_progress = e.lengthComputable ? Math.floor((e.loaded/e.total)*100) : -1;
      }
      req.upload.onload = function(e)
      {
        //file.m_complete = true;
        file.m_progress = 100;
      }
      req.onreadystatechange = function(e)
      {
        if (req.readyState == 4)
        {
          file.m_complete = true;
          file.m_response = req.responseText;
        }
      }
      req.upload.onerror = function(e) { console.log("# error: " + file.m_$name); }
      req.upload.onabort = function(e) { console.log("# abort: " + file.m_$name); }

      req.open("POST", uri, true);
      var keys = self.m_headers.keys();
      for (var i=0; i<keys.size(); i++)
      {
        var key = keys.get(i);
        var val = self.m_headers.get(key);
        req.setRequestHeader(key, val);
      }

      if (self.m_useMultiPart)
      {
        // TODO FIXIT: use a single POST for all files
        var data = new FormData();
        data.append("file", file.m_file, file.m_$name);
        req.send(data);
      }
      else
      {
        req.setRequestHeader("FileUpload-filename", file.m_$name);
        req.send(file.m_file);
      }
    })(this.files.get(i));
  }

  // kick-off status update poller
  this.onUploadStatus(self);
}

fan.webfwt.FileUploaderPeer.prototype.onUploadStatus = function(self)
{
  // notify changes
  self.onFilesChanged(this.files);

  // check if all uploads complete
  var num  = 0;
  var size = this.files.size();
  for (var i=0; i<size; i++) if (this.files.get(i).m_complete) num++;
  if (num == size) self.onUploadComplete(this.files);
  else
  {
    var $this = this;
    setTimeout(function() { $this.onUploadStatus(self) }, 100);
  }
}