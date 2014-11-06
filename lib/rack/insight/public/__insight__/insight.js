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
      console.log(this.panel_id);
      if(this.request_id && this.panel_id) {
        this.current = $('#rack-insight #request_' + this.request_id + ' #' + this.panel_id)
      }
    },
    getPanelContent: function() {
      $.get("/__insight__/panels_content?request_id=" + this.request_id, function(data) {
          $('#rack-insight').append(data)
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
      $.get("/__insight__/panels_header?request_id=" + this.request_id, function(data) {
          $('ul.panels').html(data)
        })
    },
    openCurrent: function() {
      $('#rack-insight .panel_content').hide();
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
  $('#rack-insight ul.panels li a').on('click', function() {
      $.insight.panel_id = this.className
      $.insight.switchCurrentPanel()
      $.insight.toggleCurrent()
      return false;
    });
  $('#rack-insight .panel_content .rack-insight_close').on('click', function() {
      $.insight.panel_id = this.id
      $.insight.switchCurrentPanel()
      $.insight.toggleCurrent()
      return false;
    });
  $('#rack-insight_debug_window a.back').on('click',function() {
      $(this).parent().hide();
      return false;
    });
  $('#rack-insight a.remote_call').on('click',function() {
      $('#rack-insight_debug_window').load(this.href, null, function() {
          $('#rack-insight_debug_window').show();
        })
      return false;
    });
  $('#rack-insight a.reveal_backtrace').on('click',function() {
      $(this).parents("tr").next().toggle();
      return false;
    });
  $('#rack-insight a.reveal_response').on('click',function() {
      $(this).parents("tr").next().next().toggle();
      return false;
    });
  $('#rack-insight a.insight_close').on('click',function() {
      $(document).trigger('close.insight');
      return false;
    });
  $('#request_id_menu').on('change', function(){
      $.insight.changeRequest($(this).val())
    });
  $('#rack-insight_debug_button').on('click',function(){
      new_position = ($('#rack-insight').attr('class')== 'rack-insight_top') ? 'bottom' : 'top';
      document.createCookie('rack-insight_position', new_position);
      $('#rack-insight').removeClass('rack-insight_top rack-insight_bottom').addClass('rack-insight_' + new_position);
      return false;
    });
  $('#rack-insight_disable_button').on('click',function(){
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
