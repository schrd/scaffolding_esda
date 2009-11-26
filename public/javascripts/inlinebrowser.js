(function($) {
  $.fn.inlinebrowser = function(options) {
    //var o = options;
    return this.each(function() {
      //var options = o;
      try {
        if (this.is_inline_browser==true) {
          return;
        }
        this.is_inline_browser=true;
        var elem = $(this);
        var url = elem.attr('url');
        var headerurl = elem.attr('header_url');
        var extra_params = elem.attr('extra_params');
        if (!elem.hasClass("notnull")) {
          elem.prepend('<a class="button erease" title="Eingabe löschen"><img src="/images/locationbar_erase.png"/></a>');
        }
        var ignore_selected_text = elem.attr('ignore_selected_text');
        if (ignore_selected_text != null) {
          elem.append('<a class="button openib"><img src="/images/find.png"/></a>' +
            '<div class="ibdialog"><div class="livegrid"></div></div>');
        } else {
          elem.append('<span class="ib_selected_text"></span><a class="button openib"><img src="/images/find.png"/></a>' +
            '<div class="ibdialog"><div class="livegrid"></div></div>');
        }
        var hidden_field = elem.find("input, textarea");
        if (options && options.input_field) {
                hidden_field = elem.find(options.input_field);
        }
        var ib_selected_text = elem.find(".ib_selected_text");
        ib_selected_text.text(elem.attr('selected_text'));
        var lg_div = elem.find(".livegrid")[0];
        var dlg = elem.find(".ibdialog");
        dlg.dialog({ autoOpen: false, width:"80%", title:elem.attr('title') });
        var lg = null;
        var value_index = null;
        if (options && options.value_index) 
          value_index = options.value_index;
        elem.find("a[class*=erease]").click(function() {
          hidden_field.val("");
          ib_selected_text.text("");
        });
        if (options != null)
          value_index = options.value_index;
        elem.find("a[class*=openib]").attr("title", elem.attr("title")).click(function() {
          dlg.dialog('open');
          if (lg==null) {
            lg = new LiveGrid(lg_div, {
              header: new HeaderSpec(headerurl),
              url: url,
              height: "300px",
              extra_params: extra_params,
              rowClickHandler: function(event, grid, line, row) {
                var row_data = grid.getRowObject(row);
                var hf = hidden_field;
                var newval = null;
                if (value_index == null) {
                  newval = row_data.id;
                } else {
                  newval = row_data[value_index];
                }
                try {
                  if ($(newval).length > 0)
                    hidden_field.val($(newval).text());
                  else
                    hidden_field.val(newval);
                } catch(e) {
                  hidden_field.val(newval);
                }
                ib_selected_text.text(row_data['scaffold_name']);
                dlg.dialog('close');
              }
            });
          }
        });
	elem.attr("title", null);
      } catch(e) {
        /*if (console) {
          //console.log(e)
        }*/
      }
      
    });
  };
  $.fn.livegrid = function(options) {
    return this.each(function() {
      try {
      	if (this.grid == null) {
        var elem = $(this);
        var url = elem.attr('url');
        var headerurl = elem.attr('header_url');
	var extra_params = elem.attr('extra_params');
        //elem.append('<div class="livegrid"></div>');
        var lg_div = this; // elem.find(".livegrid")[0];
	$.getJSON(headerurl, null, function(data) {
		var header = new HeaderBase();
		header.fields = data;
		var lg = new LiveGrid(lg_div, {
			header: header,
			url: url,
			height: "300px",
			extra_params: extra_params
		});
	});
	}
      } catch(e) {
        /*if (console) {
          //console.log(e)
        }*/
      }
      
    });
  };

  $.fn.inlineshow = function(options) {
    return this.each(function(){
      if (this.is_inline_show==true)
        return;
      this.is_inline_show=true;
      var elem = $(this);
      var sel = elem.parent().find("select, input:hidden");
      var url = elem.attr('url');
      elem.append('<a class="button"><img src="/images/filefind.png"/></a><div class="dialoginhalt">Lade Daten</div>');
      var link = elem.find("a");
      var dlginhalt = elem.find(".dialoginhalt")
      dlginhalt.dialog({autoOpen: false, width:"80%", title: elem.attr('title')});
      var loaded = false;
      link.click(function() {
	if (dlginhalt.dialog('isOpen')) {
          dlginhalt.dialog('close');
	} else {
          dlginhalt.dialog('open');
	}
        if (loaded==false) {
          var url2 = url;
          if (sel.val() != null)
            url2 = url + "/" + sel.val();
          dlginhalt.load(url2, null, function(responseText, textStatus, xhr) {
            if (xhr.status==200) {
              jQuery(this).find(".inlineshow").inlineshow({});
            }
          });
          //loaded = true;
//          var i = dlginhalt.find(".inlineshow");
//          console.log(i);
//          console.log(dlginhalt);
//          dlginhalt.find(".inlineshow").inlineshow({});
        }
      });
    });
  };
  $.fn.inlinenew = function(options) {
    return this.each(function(){
      if (this.is_inline_new==true)
        return;
      this.is_inline_new=true;
      var elem = $(this);
      var sel = elem.parent().find("select, input:hidden");
      var url = elem.attr('url');
      elem.append('<a class="button"><img src="/images/filenew.png"/></a><div class="newinline">Lade Formular</div>');
      var link = elem.find("a");
      var inhalt = elem.find("div.newinline");
      inhalt.hide();
      link.click(function() {
        var oldselected = sel.val();
        sel.val("");
        inhalt.load(url, null, function(responseText, textStatus, xhr) {
          if (xhr.status==200) {
            /*jQuery(this).find(".inlineshow").inlineshow({});
            jQuery(this).find(".inlinenew").inlinenew({});
            jQuery(this).find(".inlinebrowser").inlinebrowser({});*/
            jQuery(this).prepend('<a class="button"><img src="/images/cancel.png"/></a>');
            jQuery(this).find("a:first").click(function() {
              sel.val(oldselected);
              inhalt.html("");
            });
            jQuery(this).registerModifications();
          }
        });
        inhalt.show();
      });
    });
  };
  $.fn.inlineform = function(target, options) {
    var t = target;
    var o = options;
    return this.each(function(){
      if (this.is_inline_form==true)
        return;
      this.is_inline_form=true;
      var elem = $(this);
      var form = elem.find("form");
      form.submit(function() {
        try{
          var action = $(this).attr("action");
          $.ajax({
            url: action,
            data: $(this).serialize(),
            type: "POST",
            complete: function(xhr) {
              if (xhr.status==200) {
                elem.dialog('close');
		elem.html("");
		elem[0].is_inline_form = false;
                o.grid.each(function() { this.grid.reload();});
              } else {
                t.html(xhr.responseText);
                t.registerModifications();
                t.inlineform(t, o);
              }
            }
          });
        } catch (e) {
          try {
          console.log(e);
	  } catch(e1) {}
        }
        return false; // do not do the form submit. use ajax instead
      });
    });
  };
  $.fn.indexedTable = function() {
    return this.each(function() {
    /*  var dlg = $(this).find("div.newdialog");
      var idx_t = $(this);
      var url = idx_t.attr('reload_url');
      this.grid = {
        reload:function() {
          idx_t.load(url);
	  idx_t.indexedTable();
          alert("reload");
        }
      };
      dlg.dialog({autoOpen:false, width:"80%"});
      $(this).find("a").click(function() {
        $(this).each(function() {
          dlg.dialog('open');
          dlg.load(this.href, null, function(responseText, textStatus, xhr) {
            $(this).inlineform(dlg, {
              grid:idx_t
            });
            $(this).registerModifications();
          });
          return false;
        });
        return false;
      });
    */});
  };
  var check_notnull = function() {
    if (this.tagName != 'INPUT' && this.tagName != 'SELECT') {
      var elem = $(this).find("input:first")[0];
    } else {
      var elem = this;
    }
    if (elem.value == null || elem.value=='') {
      $(this).addClass('format-error');
    } else {
      $(this).removeClass('format-error');
    }
  };
  $.fn.registerModifications = function() {
    return this.each(function() {
      $(this).find(".kundeninlinebrowser").inlinebrowser({value_index: 'kundennummer'});
      $(this).find(".artikelinlinebrowser").inlinebrowser({value_index: 'schluessel'});
      $(this).find(".lagerinlinebrowser").inlinebrowser({value_index: 'lagernummer'});
      $(this).find(".matrixinlinebrowser").inlinebrowser({value_index: 'matrix'});
      $(this).find("*[class*=inlinebrowser]").inlinebrowser();
      $(this).find(".inlineshow").inlineshow();
      $(this).find(".inlinenew").inlinenew();
      $(this).find(".livegrid").livegrid();
      $(this).find(".indexedtable").indexedTable();
      $(this).find("input[class*='date']").datepicker({ 
        dateFormat: 'dd.mm.yy', 
        minDate:'-10y', 
        maxDate:'+50y',
        showOn: 'button', 
        changeMonth: true,
        changeYear: true,
      	duration: 0,
	firstDay: 1,
        dayNamesMin: ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'],
	monthNamesShort: ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez']
      });
      $(this).find("*[class*='notnull']").bind("blur change", check_notnull);
      $(this).find("*[class*='notnull']").each(check_notnull);
    });
  };

})(jQuery);
