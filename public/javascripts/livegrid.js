function LiveGrid(element, options) {
  element.grid = this;
  element.className = element.className + " livegrid";
  this.options = options;
  this.sort = null;
  this.element = element;
  this.tablewrapper = document.createElement("div");
  this.tablewrapper.style.position = "relative";
  this.element.appendChild(this.tablewrapper);
  this.scrollable = document.createElement("div");
  this.offsetParameter = options.offsetParameter || "offset";
  this.limitParameter = options.limitParameter || "limit";
  this.url = options.url;
  this.extra_params = options.extra_params || '';
  var grid = this;
  this.scrollable.addEventListener("scroll", function(event) { grid.scrollhandler.call(grid, event)}, false);
  this._rowHeight = options.rowHeight || 21;
  this._rowExtraHeight = 4;
  this.setScrollableStyle();

  this.scrollproxy = document.createElement("div");
  this.scrollproxy.style.height = "0px"; 
  this.scrollproxy.style.border = "none";
  this.scrollproxy.className = element.id + "_scrollproxy";
  this.scrollable.appendChild(this.scrollproxy);
  this.tablewrapper.appendChild(this.scrollable);
  this.counterDiv = document.createElement("div");
  this.counterDiv.className = "livegridcounter";
  this.cells = [];
  this.buildTable();
  this.table.style.direction = 'ltr';
  this.loadingDiv = document.createElement("div");
  this.loadingDiv.innerHTML = '<span style="background-color: #888; -moz-opacity: 1; border: solid black thin; margin: auto; height:3em; position:absolute; top:0px; bottom: 0px;">loading data...<br/><img src="/images/mozilla_blu.gif"/></span>';
  this.loadingDiv.style.visibility = "hidden";
  this.loadingDiv.style.position = "absolute";
  this.loadingDiv.style.left = "0px";
  this.loadingDiv.style.top= "0px";
  this.loadingDiv.style.backgroundColor = "#aaa";
  this.loadingDiv.style.color = "black";
  //this.loadingDiv.style.opacity = 0.8;
  this.loadingDiv.style.width = "100%";
  this.loadingDiv.style.height= "100%";
  this.loadingDiv.style.verticalAlign= "middle";
  this.loadingDiv.style.textAlign = "center";
  this.element.appendChild(this.loadingDiv);
  this.timerID = null;
  this.request = null;
  this.request_running = false;
  this.buffer_size = options.buffer_size || 50;
  this.buffer_fetch_near = options.buffer_fetch_near || 10;
  this.buffer_count = options.buffer_count || 3;
  this.buffers = [];
  this.columnResizePad = options.columnResizePad || 5;
  this.setDefaultWidths();
  this.element.appendChild(this.counterDiv);
  this.update_buffer();
};

LiveGrid.prototype.setScrollableStyle = function() {
  var grid = this;
  var h = parseInt(grid.options.height) || 200;
  h = Math.ceil(h/grid.rowFullHeight()) * grid.rowFullHeight();
  with (this.scrollable.style) {
    position = "absolute";
    right= "0px";
    bottom = "0px";
    //marginTop = grid._rowHeight + "px";
    height= h + 'px';
    border="none";
    overflowY = "scroll";
    overflowX = "hidden";
    width="20px";
    zIndex="4";
  }
};
LiveGrid.prototype.setTableStyle = function() {
  this.table.className = "scrolltable";
  with (this.table.style) {
    borderSpacing = "0px";
    borderCollapse = "collapse";
    maxWidth = "100%";
  }
};

LiveGrid.prototype.storePosition = function() {
    try {
      window.sessionStorage[this.url + "_scrolltop"] = this.scrollable.scrollTop;
    } catch (e) {
      try {
        console.log(e);
      } catch (ignored) {}
    };
};

LiveGrid.prototype.buildTable = function() {
  var grid = this;
  this.table = document.createElement("table");
  var scrollh = function(event) {
    // triggers scroll event handler on this.scrollable
    grid.scrollable.scrollTop = grid.scrollable.scrollTop + (event.detail -1 ) * grid.rowFullHeight();
    event.preventDefault();
    grid.storePosition();
  };
  var scrollh2 = function(event) {
    // triggers scroll event handler on this.scrollable
    grid.scrollable.scrollTop = grid.scrollable.scrollTop + (event.wheelDelta / -40) * grid.rowFullHeight();
    event.preventDefault();
    grid.storePosition();
  };
  this.table.addEventListener("DOMMouseScroll", scrollh, true);
  this.element.addEventListener("DOMMouseScroll", scrollh, true);
  this.table.addEventListener("mousewheel", scrollh2, true);
  this.element.addEventListener("mousewheel", scrollh2, true);
  this.element.addEventListener("keyup", function(event) {
    if (event.keyCode==38) { // up
      grid.scrollable.scrollTop = grid.scrollable.scrollTop - grid.rowFullHeight();
      event.preventDefault();
      event.stopPropagation();
    }
    if (event.keyCode==40) { // down
      grid.scrollable.scrollTop = grid.scrollable.scrollTop + grid.rowFullHeight();
      event.preventDefault();
      event.stopPropagation();
    } 
    if (event.keyCode==33) { // pageup
      grid.scrollable.scrollTop = grid.scrollable.scrollTop - grid.numberOfRowsVisible() * grid.rowFullHeight();
      event.preventDefault();
      event.stopPropagation();
    }
    if (event.keyCode==34) { // pagedown
      grid.scrollable.scrollTop = grid.scrollable.scrollTop + grid.numberOfRowsVisible() * grid.rowFullHeight();
      event.preventDefault();
      event.stopPropagation();
    }
    grid.storePosition();
  }, true);
  this.setTableStyle();
  this.tablewrapper.appendChild(this.table);
  // build table header
  var headerspec = this.options.header;
  //var tr1 = document.createElement("tr");
  var tr1 = this.table.insertRow(-1);
  tr1.className = "head resizable";
  //var tr2 = document.createElement("tr");
  var tr2 = this.table.insertRow(-1);
  // dass diese Zeile die head Klasse bekommt ist völlig widersinnig. Aber wenn sie es nicht bekommt, spinnt der Firefox beim markieren der inputfelder
  tr2.className = "head";
  //this.table.appendChild(tr1);
  // for resizing columns
  tr1.addEventListener("mousedown", function(event) {
    grid.mouseDownHandler.call(grid, event);
  }, false);
  tr1.addEventListener("mousemove", function(event) {
    grid.mouseMoveHandler.call(grid, event);
  }, false);
  document.addEventListener("mouseup", function(event) {
    if (grid.columnResize != null) {
      event.preventDefault();
      event.stopPropagation();
    }
    grid.columnResize = null;
  }, false); 
  
  //this.table.appendChild(tr2);
  var reloadHandler = function(event) {
    if (event.keyCode==13) {
      grid.search();
    }
  };
  tr1.style.height = this.rowHeight() -1 + 'px';
  tr2.style.height = this.rowHeight() -1 + 'px';
  var ncols = headerspec.numberOfColumns();
  for (var j=0; j < ncols; j++) {
    //var td=document.createElement("th");
    var td=tr1.insertCell(-1);
    td.addEventListener('mouseup', function(event) {
      if (event.currentTarget.tagName=='TD' && grid.columnResize == null) {
      var cell = event.currentTarget;
      var idx = cell.cellIndex;
      if (headerspec.fields[idx][2] == null || headerspec.fields[idx][2]=='')
        return;
      grid.sort= headerspec.fields[idx][2];
      var sort_dir = 'ASC';
      if (grid.sort_asc && idx == grid.sort_column) {
        sort_dir = 'DESC';
        grid.sort_asc = false;
      } else {
        grid.sort_asc = true;
      }
      grid.sort = grid.sort + " " + sort_dir;
      if (grid.sort_column != null) {
        var old_cell = cell.parentNode.cells[grid.sort_column];
        old_cell.className = old_cell.className.replace(/(DESC|ASC)/, '');
      }
      cell.className = cell.className + ' ' + sort_dir;
      grid.sort_column = idx;
      grid.reload();
      }
    }, true);
    td.innerHTML = "<div>" + headerspec.getFieldName(j) + "</div>";
    td.style.height = this._rowHeight-1 + 'px';
    td.style.overflow = 'hidden';
    var sort_string = headerspec.fields[j][2];
    //tr1.appendChild(td);
    //td=document.createElement("th");
    td = tr2.insertCell(-1);
    td.innerHTML = "<div>" + headerspec.getFieldSearch(j) + "</div>";
    //console.log(td.clienthHeight);
    
    var inputs = td.firstChild.getElementsByTagName("input");
    for (var k=0; k < inputs.length; k++) {
      inputs[k].addEventListener('keyup', reloadHandler, true);
    }
    var selects = td.firstChild.getElementsByTagName("select");
    for (var k=0; k < selects.length; k++) {
      selects[k].addEventListener('keyup', reloadHandler, true);
    }
    
    td.style.height = this._rowHeight-1 + 'px';
    td.style.overflow = 'hidden';
    var scripts = td.firstChild.getElementsByTagName("script");
    for (var k=0; k < scripts.length; k++) {
      try {
      eval(scripts[k].textContent);
      } catch(e) { alert(e); }
    }
    if (j==0) {
      var clear = document.createElement("img");
      clear.src="/images/locationbar_erase.png";
      clear.title="Suchfelder leeren";
      clear.className="button";
      td.firstChild.appendChild(clear);
      clear.addEventListener("click", function(event) {
        var inputs = tr2.getElementsByTagName("input");
        for (var k=0; k < inputs.length; k++) {
          inputs[k].value = '';
        }
      }, true);
    }
    //tr2.appendChild(td);
  }
  // build table cells
  for (var i=0; i < this.numberOfRowsVisible(); i++) {
    //var tr = document.createElement("tr");
    var tr = this.table.insertRow(-1);
    this.cells[i] = [];
    if (this.options.rowClickHandler) {
      var rch = this.options.rowClickHandler;
      tr.addEventListener('click', function(event) {
          var line = event.currentTarget.rowIndex - 2;
          var row = grid.getFirstVisibleRow() + line;
          rch(event, grid, line, row);
	  event.preventDefault();
      }, false);
    }
    tr.style.height = this._rowHeight -1 + 'px';
    for (var j=0; j < ncols; j++) {
      //var td=document.createElement("td");
      var td = tr.insertCell(-1);
      this.cells[i][j] = td;
      td.innerHTML = "<div></div>";
      td.style.height = this._rowHeight -1 + 'px';
      td.firstChild.style.height = this._rowHeight -1 + 'px';
      //td.style.border = "solid 1px #ccc";
      //tr.appendChild(td);
    }
    //this.table.appendChild(tr);
  }
  // height mut be computed after all rows have been added, because the browser relayouts
  var h = tr1.clientHeight + tr2.clientHeight;
  this.lastQueryString = headerspec.getQueryString(this.table.rows[1]);
  this.scrollable.style.marginTop = h + "px";
  var nrows = this.table.rows.length;
  for (var i=parseInt(nrows/2); i < nrows; i++) {
    this.table.rows[i].className = 'bottom';
  }
  this.restoreSessionStorage();
};

LiveGrid.prototype.reload = function() {
  this.buffers = [];
  this.update_buffer();
};

LiveGrid.prototype.getBufferIndexForOffset = function(offset) {
  var first_unused_buffer = null;
  for(var i=0; i < this.buffer_count; i++){
    if (this.buffers[i] == null && first_unused_buffer == null)
      first_unused_buffer = i;
    if (this.buffers[i] != null && this.buffers[i]['offset'] == offset)
      return i;
  }
  return first_unused_buffer;
};

LiveGrid.prototype.getReplacementBufferIndexForOffset = function(offset) {
  var max_dist = -1;
  var max_dist_idx = null;
  if (this.buffers.length < this.buffer_count) {
    // check if offset exists in data
    for (var i=0; i < this.buffers.length;i++){
      if (this.buffers[i]['offset'] == offset)
        return i;
    }
    // does not exists -> append
    return this.buffers.length;
  }
  for(var i=0; i < this.buffer_count; i++){
    if (this.buffers[i]){
      var dist = Math.abs(this.buffers[i]['offset'] - offset);
      if (dist == 0)
        return i;
      if (dist > max_dist) {
        max_dist = dist;
        max_dist_idx = i;
      }
    }
  }
  return max_dist_idx;
};

LiveGrid.prototype.getOffsetForRow = function(rowNumber) {
  return parseInt((rowNumber / this.buffer_size)) * this.buffer_size;
};

LiveGrid.prototype.scrollhandler = function(event) {
  var line = Math.round(this.scrollable.scrollTop / this.rowFullHeight());
  if (line * this.rowFullHeight() != this.scrollable.scrollTop) {
    this.scrollable.scrollTop = line * this.rowFullHeight();
    this.storePosition();
  } else {
    this.update_buffer();
  }
};

LiveGrid.prototype.mouseDownHandler = function(event) {
  var grid = this;
  var th = event.target;
  while (th.tagName != 'TD' && th.parentNode != null)
    th = th.parentNode;
  if (th != null && th.tagName=='TD') {
    var left = event.clientX;
    var el = th;
    while (el.offsetParent != null) {
      left = left - el.offsetLeft;
      el = el.offsetParent;
    }
    var w = parseInt(document.defaultView.getComputedStyle(th, null).width);
    if (w > grid.columnResizePad * 2 &&
        grid.columnResizePad < left &&
        left <= w - grid.columnResizePad)
      return;
    el = th;
    if (left < grid.columnResizePad) {
      if (el.cellIndex != 0) {
        el = el.parentNode.cells[el.cellIndex-1];
      }
    }
    grid.columnResize = {
      target: el,
      originalWidth: w
    };
  }
};
LiveGrid.prototype.mouseMoveHandler = function(event) {
  var grid = this;
  var th = event.target;
  while (th.tagName != 'TD' && th.parentNode != null)
    th = th.parentNode;
  if (th && th.tagName == 'TD') {
    var left = event.clientX;
    var el = th;
    while (el.offsetParent != null) {
      left = left - el.offsetLeft;
      el = el.offsetParent;
    }
    var w = parseInt(document.defaultView.getComputedStyle(th, null).width);
    // set cursor!
    if (w > grid.columnResizePad * 2 &&
        grid.columnResizePad < left &&
        left <= w - grid.columnResizePad) {
      grid.table.style.cursor = "default";
    } else {
      grid.table.style.cursor = "move";
    }
  } else {
    grid.table.style.cursor = "default";
  }
  
  // resize if in drag mode
  if (grid.columnResize != null) {
    var left = event.clientX;
    var el = grid.columnResize.target;
    while (el.offsetParent != null) {
      left = left - el.offsetLeft;
      el = el.offsetParent;
    }
    grid.resizeColumn(grid.columnResize.target.cellIndex, left);
    // keep column width
    // Firefox 2 && Firefox 3 do not support WhatWG localStorage implementation but non-standard globalStorage
    if (window.localStorage==null && window.globalStorage && window.globalStorage[location.hostname]) {
      window.localStorage = window.globalStorage[location.hostname];
    }
    var storageKey = this.url + "#colwidth" + grid.columnResize.target.cellIndex;
    window.localStorage[storageKey] = left;
    event.preventDefault;
  }
};

LiveGrid.prototype.hasToLoadData = function() {
  var firstRow = this.getFirstVisibleRow();
  var idx = this.getBufferIndexForOffset(this.getOffsetForRow(firstRow));
  // buffer does not exist
  if (this.buffers[idx] == null)
    return this.getOffsetForRow(firstRow);
  // buffer exists. do not check for lower near range if offset == 0
  if (firstRow <= this.buffer_fetch_near) 
    return null;
  // now check if we are NOT close to another buffer
  var off = this.buffers[idx]['offset'];
  if(firstRow <= this.buffer_fetch_near) return null;
  var buf_size = this.buffers[idx]['data'].length;
  var nrows = this.numberOfRowsVisible();
  if (off + this.buffer_fetch_near < firstRow && 
      off + buf_size - this.buffer_fetch_near > firstRow + nrows) {
    return null;
  }
  // now check if we are in the lower border range, then check if the lower buffer exists
  if (off + this.buffer_fetch_near >= firstRow) {
    var idx_below = this.getBufferIndexForOffset(off - buf_size);
    if (this.buffers[idx_below] !=null)
      return null;
    else
      return off - buf_size;
  }
  // now check if we are in the upper border range, then check if the upper buffer exists
  if (off + buf_size - this.buffer_fetch_near - nrows <= firstRow) {
    var idx_above = this.getBufferIndexForOffset(off + buf_size);
    if (this.buffers[idx_above] !=null)
      return null;
    else
      return off + buf_size;
  }
  // all checks failed. Data is missing.
  return off;

};

LiveGrid.prototype.update_buffer = function() {
  var grid = this;
  if (this.request_running==true) {
    return;
  }
  // flush buffers if query string changed
  var qs = grid.options.header.getQueryString(grid.table.rows[1]);
  if (grid.sort != null) {
    qs = qs + "&sort=" + grid.sort;
  }
  if (qs != grid.lastQueryString) {
    grid.buffers = [];
    grid.lastQueryString = qs;
  }
  var load_offset = this.hasToLoadData();
  if (load_offset != null) {
    this.request_running = true;
    var request = new XMLHttpRequest();
    request.onreadystatechange = function() {
      if (request.readyState == 4) {
        try {
          var data = eval('(' + request.responseText + ')');
          //var data = jsonParse(request.responseText);
	  data.data = [];
          var g = grid;
          var ncols = grid.options.header.numberOfColumns();
          var regex = /\#\{(.+?)\}/g;
          var compiled_templates = [];
          for (var j=0; j < ncols; j++) {
            var template_src = grid.options.header.fields[j][4];
            compiled_templates[j] = Handlebars.compile(template_src);
          }

          for(var i=0; i < data.objects.length; i++) {
            data.data[i] = [];
            for (var j=0; j < ncols; j++) {
              data.data[i][j] = '&nbsp;<div class="cellcontent">' + compiled_templates[j](data.objects[i]) + '</div>';
            }
          }
          var replace = grid.getReplacementBufferIndexForOffset(data['offset']);
          grid.buffers[replace] = data;
          // resize scrollproxy size if neccesary
          var new_height = (parseInt(data['count'])) * grid.rowFullHeight();
          if (grid.scrollproxy.clientHeight != new_height) {
            grid.scrollproxy.style.height = new_height + "px";
          }
          var data_missing = grid.applyData();
        } catch(e) {
          alert(e);
        }finally {
          grid.request_running = false;
        }
        grid.loadingDiv.firstChild.style.visibility="hidden";
        if (data_missing)
          grid.update_buffer();
      }
    };
    var firstRow = this.getFirstVisibleRow();
    var start_buf = parseInt((firstRow / this.buffer_size)) * this.buffer_size;
    if (start_buf != 0 && (firstRow - start_buf < this.buffer_fetch_near)) {
      start_buf = start_buf - this.buffer_size;
    } else if  ((start_buf + this.buffer_size - firstRow < this.buffer_fetch_near)) {
      start_buf = start_buf + this.buffer_size;
    }
    request.open("GET", this.url + "?" + 
		    encodeURI(this.offsetParameter + "=" + load_offset + "&" + this.limitParameter + "=" + this.buffer_size + "&")  + qs + "&" + this.extra_params, true);
    request.send(null);
    grid.loadingDiv.firstChild.style.visibility="visible";
  }
  this.applyData();
};

LiveGrid.prototype.applyData = function() {
  var start_t = (new Date).getTime();
  var firstRow = this.getFirstVisibleRow();
  var data_missing = false;
  var ncols = this.options.header.numberOfColumns();
  var nrows = this.numberOfRowsVisible();
  if (this.buffers[0]) {
    this.counterDiv.innerHTML = "Zeilen " + (firstRow+1) + "-" + (Math.min(firstRow+nrows, this.buffers[0].count)) + "/" + this.buffers[0].count;
  }
  for (var i=0; i < nrows; i++) {
    //var tr = this.table.rows[i+2];
    /*
    var data_row = null;
    var offset = this.getOffsetForRow(firstRow + i);
    var buffer_idx = this.getBufferIndexForOffset(offset);
    if (this.buffers[buffer_idx] != null) {
      data_row = this.buffers[buffer_idx]['data'][firstRow + i - offset];
    } */
    var data_row = this.getRowData(firstRow + i);
    //var h = this.rowHeight();
    for (var j=0; j < ncols; j++) {
      //if (tr && tr.cells[j]) {
	//var tr_height = tr.clientHeight;
 	var cell = this.cells[i][j]; //tr.cells[j];
        if (data_row) {
          cell.firstChild.innerHTML = data_row[j];
          //tr.cells[j].replaceChild(data_row[j], tr.cells.firstChild);
	
/*	
	  var inner = cell.firstChild.childNodes[1];
	  if (h < parseInt(document.defaultView.getComputedStyle(inner, null).height)) {
	    //tr.cells[j].className = "clipped";
	    cell.style.background = "url(/images/ecke_rechts_unten.png) right bottom no-repeat";
	  } else {
	    //tr.cells[j].className = "";
	    cell.style.background = "";
	  }
*/
//	
	}
        else {
          cell.firstChild.innerHTML = '';
	  data_missing = true;
	}
      //}
    }
  }
  /*
  if (data_missing==true) {
    var load_offset = this.hasToLoadData();
    if (load_offset != null) 
      this.update_buffer();
  }*/
  if (this.buffers.length == 0) {
    this.table.rows[2].cells[0].firstChild.innerHTML = "Keine Daten";
    return false;
  }
  if (this.buffers[0] && parseInt(this.buffers[0]['count']) == 0) {
    this.table.rows[2].cells[0].firstChild.innerHTML = "Keine Datensätze gefunden";
    return false;
  }
  var end_t = (new Date).getTime();
  //console.log(end_t - start_t);
  return data_missing;
};

LiveGrid.prototype.getRowObject = function(rownumber) {
  var data_row = null;
  var offset = this.getOffsetForRow(rownumber);
  var buffer_idx = this.getBufferIndexForOffset(offset);
  if (this.buffers[buffer_idx] != null) {
    data_row = this.buffers[buffer_idx]['objects'][rownumber - offset];
  } 
  return data_row;
};
LiveGrid.prototype.getRowData = function(rownumber) {
  var data_row = null;
  var offset = this.getOffsetForRow(rownumber);
  var buffer_idx = this.getBufferIndexForOffset(offset);
  if (this.buffers[buffer_idx] != null) {
    data_row = this.buffers[buffer_idx]['data'][rownumber - offset];
  } 
  return data_row;
};
LiveGrid.prototype.numberOfRowsVisible = function() {
  //if (this._numberOfRowsVisible)
  //  return this._numberOfRowsVisible;
  var defined_height = 200;
  if (this.options && this.options.height) {
    defined_height = parseInt(this.options.height);
  }
  this._numberOfRowsVisible = Math.ceil(Math.max(parseInt(this.scrollable.clientHeight), defined_height) / (this.rowHeight()+4));
  return this._numberOfRowsVisible;
};
LiveGrid.prototype.rowHeight = function() {
  /*if (this.table.rows &&
      this.table.rows[2] &&
      this.table.rows[2].clientHeight > this._rowHeight)
      return this.table.rows[2].clientHeight;*/
  return this._rowHeight;
};
LiveGrid.prototype.rowFullHeight = function() {
  return this._rowHeight + this._rowExtraHeight;
};

LiveGrid.prototype.setFirstVisibleRow = function(rownr) {
  if (rownr >= this.buffers[0].count ) {
    rownr = this.buffers[0].count - 1;
  }
  this.scrollable.scrollTop = rownr * this.rowFullHeight();
};
LiveGrid.prototype.getFirstVisibleRow = function() {
  return parseInt(this.scrollable.scrollTop / this.rowFullHeight()) ;
};

LiveGrid.prototype.resizeColumn = function(column, width) {
  if (width < 10)
    width = 10;
  var rows = this.table.rows
  for (var i=0; i < rows.length; i++) {
    var cells = rows[i].cells;
    if (column < cells.length)
      cells[column].style.width = width + "px";
      if (cells[column].firstChild != null)
        cells[column].firstChild.style.width = width + "px";
  }
};

LiveGrid.prototype.search = function() {
  this.buffers = [];
  this.scrollable.scrollTop = 0;
  try {
    window.sessionStorage[this.url] =
      this.options.header.getQueryString(this.table.rows[1]);
  } catch(e) {
    try {
      console.log(e);
    } catch(ignored) {};
  };

  this.update_buffer();
}
LiveGrid.prototype.restoreSessionStorage = function() {
  try {
    if (window.sessionStorage[this.url]!=null) {
      var raw_values = null;
      if (typeof(window.sessionStorage[this.url]) == "string") {
        raw_values = window.sessionStorage[this.url].split("&");
      } else {
        raw_values = window.sessionStorage[this.url].value.split("&");
      }
      var values = {};
      for (var i=0; i< raw_values.length; i++) {
        var key = decodeURIComponent(raw_values[i].split("=")[0]);
        var value = decodeURIComponent(raw_values[i].split("=")[1]);
        values[key] = value;
      }
      var inputs = this.table.rows[1].getElementsByTagName('input');
      for (var i=0; i < inputs.length; i++) {
        if (inputs[i].defaultValue == "") {
          if (values[inputs[i].name])
            inputs[i].value = values[inputs[i].name];
        }
      }
    }
  } catch(e) {
    try{
      console.log(e);
    } catch(ignored) {}
  };
  var grid = this;
  //window.setTimeout(function() {
  try {
    if (window.sessionStorage[grid.url + "_scrolltop"] != null) {
      var s_top = null;
      if (typeof(window.sessionStorage[grid.url + "_scrolltop"])=="string") {
        s_top=window.sessionStorage[grid.url + "_scrolltop"];
      } else {
        s_top=window.sessionStorage[grid.url + "_scrolltop"].value;
      }
      if (grid.scrollproxy.clientHeight < s_top) {
        grid.scrollproxy.style.height = (s_top + 10) + 'px';
      }
      grid.scrollable.scrollTop = s_top;
    }
  } catch(e) {
    try {
      console.log(e);
    } catch(ignored) {}
  };
  //}, 1000);
};
LiveGrid.prototype.setDefaultWidths = function() {
  // Firefox 2 && Firefox 3 do not support WhatWG localStorage implementation but non-standard globalStorage
  if (window.localStorage==null && window.globalStorage && window.globalStorage[location.hostname]) {
    window.localStorage = window.globalStorage[location.hostname];
  }
  var headerspec = this.options.header;
  var ncols = headerspec.numberOfColumns();
  for (var j=0; j < ncols; j++) {
    var storageKey = this.url + "#colwidth" + j;
    if (window.localStorage && window.localStorage[storageKey]) {
	if  (typeof(window.localStorage[storageKey])=="string") {
           this.resizeColumn(j, parseInt(window.localStorage[storageKey]));
        } else {
           this.resizeColumn(j, parseInt(window.localStorage[storageKey].value));
        }
    } else if (headerspec.fields[j][3]) {
      this.resizeColumn(j, headerspec.fields[j][3]);
    }
  }
};
function findLiveGridAround(element) {
  var el = element;
  while (el && el.className.match(/livegrid/) == null) {
    el = el.parentNode;
  }
  return el;
}

HeaderSpec = function(url) {
  this.url = url;
  this.fields = [];
  var spec = this;
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    if (xhr.readyState==4) {
      var s = spec;
      s.fields = eval("(" + xhr.responseText + ")");
    }
  };
  xhr.open("GET", this.url, false);
  xhr.send(null);
  this.fields = eval("(" + xhr.responseText + ")");
};
HeaderSpec.prototype = {
  numberOfColumns: function() {
    return this.fields.length;
  },
  getFieldName: function(index) {
    return this.fields[index][0];
  },
  getFieldSearch: function(index) {
    return this.fields[index][1];
  },
  getFieldIndex: function(name) {
    for (var i=0; i < this.fields.length; i++) {
      if (this.fields[i][2] == name) {
        return i;
      }
    }
    return null;
	},
  getQueryString: function(searchBelow) {
    if (searchBelow==null)
      return "";
    var inputs = searchBelow.getElementsByTagName('input');
    var params = [];
    for (var i=0; i < inputs.length; i++) {
      params.push(encodeURIComponent(inputs[i].name) + "=" + encodeURIComponent(inputs[i].value))
    }
    var selects = searchBelow.getElementsByTagName('select');
    for (var i=0; i < selects.length; i++) {
      var elem = selects[i];
      for (var j=0; j < elem.options.length; j++) {
        if (elem.options[j].selected==true) {
          params.push(encodeURIComponent(elem.name) + "=" + encodeURIComponent(elem.options[j].value));
        }
      }
    }
    return params.join("&");
  }
};

HeaderBase = function() {
}
HeaderBase.prototype = {
  numberOfColumns: function() {
    return this.fields.length;
  },
  getFieldName: function(index) {
    return this.fields[index][0];
  },
  getFieldSearch: function(index) {
    return this.fields[index][1];
  },
  getFieldIndex: function(name) {
    for (var i=0; i < this.fields.length; i++) {
      if (this.fields[i][2] == name) {
        return i;
      }
    }
    return null;
	},
  getQueryString: function(searchBelow) {
    if (searchBelow==null)
      return "";
    var inputs = searchBelow.getElementsByTagName('input');
    var params = [];
    for (var i=0; i < inputs.length; i++) {
      params.push(encodeURIComponent(inputs[i].name) + "=" + encodeURIComponent(inputs[i].value))
    }
    var selects = searchBelow.getElementsByTagName('select');
    for (var i=0; i < selects.length; i++) {
      var elem = selects[i];
      for (var j=0; j < elem.options.length; j++) {
        if (elem.options[j].selected==true) {
          params.push(encodeURIComponent(elem.name) + "=" + encodeURIComponent(elem.options[j].value));
        }
      }
    }
    return params.join("&");
  }
};
