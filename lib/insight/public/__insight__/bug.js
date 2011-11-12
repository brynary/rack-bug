var _$ = window.$;
jQuery.noConflict();
jQuery(function($) {
    function RackBug() {
      this.current = null
      this.request_id = null
      this.panel_id = null
    }

    RackBug.prototype = {
      switchCurrentPanel: function() {
        if(this.request_id && this.panel_id) {
          this.current = $('#rack_bug #request_' + this.request_id + ' #' + this.panel_id)
        }
      },
      getPanelContent: function() {
        $.get("__rack_bug__/panels_content?request_id=" + this.request_id, function(data) {
            $('#rack_bug').append(data)
            $.rackBug.switchCurrentPanel()
            $.rackBug.openCurrent()
          })
      },
      toggleCurrent: function() {
        if(this.current) {
          if (this.current.is(':visible')) {
            $(document).trigger('close.rackBug');
          } else {
            this.openCurrent()
          }
        }
      },
      changeRequest: function(req_number) {
        $(document).trigger('close.rackbug')
        this.request_id = req_number
        this.switchCurrentPanel()
        if(this.current.length <= 0) {
          this.getPanelContent()
        } else {
          this.openCurrent()
        }
        $.get("__rack_bug__/panels_header?request_id=" + this.request_id, function(data) {
            $('ul.panels').html(data)
          })
      },
      openCurrent: function() {
        $('#rack_bug .panel_content').hide();
        this.current.show();
        this.open();
      },
      open: function() {
        $(document).bind('keydown.rackBug', function(e) {
            if (e.keyCode == 27) {
              $.rackBug.close();
            }
          });
        $('table.sortable').tablesorter();
      },
      toggle_content: function(elem) {
        if (elem.is(':visible')) {
          elem.hide();
        } else {
          elem.show();
        }
      },
      close: function() {
        $(document).trigger('close.rackBug');
        return false;
      }
    }

    $.rackBug = new RackBug

    $(document).bind('close.rackBug', function() {
        $(document).unbind('keydown.rackBug');
        $('.panel_content').hide();
      });
    $('#rack_bug ul.panels li a').live('click', function() {
        $.rackBug.panel_id = this.className
        $.rackBug.switchCurrentPanel()
        $.rackBug.toggleCurrent()
        return false;
      });
    $('#rack_bug_debug_window a.back').live('click',function() {
        $(this).parent().hide();
        return false;
      });
    $('#rack_bug a.remote_call').live('click',function() {
        $('#rack_bug_debug_window').load(this.href, null, function() {
            $('#rack_bug_debug_window').show();
          })
        return false;
      });
    $('#rack_bug a.reveal_backtrace').live('click',function() {
        $(this).parents("tr").next().toggle();
        return false;
      });
    $('#rack_bug a.rack_bug_close').live('click',function() {
        $(document).trigger('close.rackBug');
        return false;
      });
    $('#request_id_menu').live('change', function(){
        $.rackBug.changeRequest($(this).val())
      });
    $('#rb_debug_button').live('click',function(){
        $('#rack_bug').toggleClass('rb_top').toggleClass('rb_bottom');
        return false;
      });
    $.tablesorter.addParser({
        id: 'ms',
        is: function(s) {
          return /ms$/.test(s);
        },
        format: function(s) {
          return $.tablesorter.formatFloat(s.replace(new RegExp(/[^0-9.]/g),""));
        },
        type: "numeric"
      });
  });
$ = _$;
