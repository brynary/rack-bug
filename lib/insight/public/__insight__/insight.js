var _$ = window.$;
jQuery.noConflict();
jQuery(function($) {
    function Insight() {
      this.current = null
      this.request_id = null
      this.panel_id = null
    }

    Insight.prototype = {
      switchCurrentPanel: function() {
        if(this.request_id && this.panel_id) {
          this.current = $('#insight #request_' + this.request_id + ' #' + this.panel_id)
        }
      },
      getPanelContent: function() {
        $.get("__insight__/panels_content?request_id=" + this.request_id, function(data) {
            $('#insight').append(data)
            $.insight.switchCurrentPanel()
            $.insight.openCurrent()
          })
      },
      toggleCurrent: function() {
        if(this.current) {
          if (this.current.is(':visible')) {
            $(document).trigger('close.insight');
          } else {
            this.openCurrent()
          }
        }
      },
      changeRequest: function(req_number) {
        $(document).trigger('close.insight')
        this.request_id = req_number
        this.switchCurrentPanel()
        if(this.current.length <= 0) {
          this.getPanelContent()
        } else {
          this.openCurrent()
        }
        $.get("__insight__/panels_header?request_id=" + this.request_id, function(data) {
            $('ul.panels').html(data)
          })
      },
      openCurrent: function() {
        $('#insight .panel_content').hide();
        this.current.show();
        this.open();
      },
      open: function() {
        $(document).bind('keydown.insight', function(e) {
            if (e.keyCode == 27) {
              $.insight.close();
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
        $(document).trigger('close.insight');
        return false;
      }
    }

    $.insight = new Insight

    $(document).bind('close.insight', function() {
        $(document).unbind('keydown.insight');
        $('.panel_content').hide();
      });
    $('#insight ul.panels li a').live('click', function() {
        $.insight.panel_id = this.className
        $.insight.switchCurrentPanel()
        $.insight.toggleCurrent()
        return false;
      });
    $('#insight_debug_window a.back').live('click',function() {
        $(this).parent().hide();
        return false;
      });
    $('#insight a.remote_call').live('click',function() {
        $('#insight_debug_window').load(this.href, null, function() {
            $('#insight_debug_window').show();
          })
        return false;
      });
    $('#insight a.reveal_backtrace').live('click',function() {
        $(this).parents("tr").next().toggle();
        return false;
      });
    $('#insight a.reveal_response').live('click',function() {
        $(this).parents("tr").next().next().toggle();
        return false;
      });
    $('#insight a.insight_close').live('click',function() {
        $(document).trigger('close.insight');
        return false;
      });
    $('#request_id_menu').live('change', function(){
        $.insight.changeRequest($(this).val())
      });
    $('#insight_debug_button').live('click',function(){
        $('#insight').toggleClass('insight_top').toggleClass('insight_bottom');
        return false;
      });
    $('#insight_disable_button').live('click',function(){
        document.insightDisable();
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
