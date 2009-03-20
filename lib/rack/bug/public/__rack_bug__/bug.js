var _$ = window.$;
jQuery.noConflict();
jQuery(function($) {
  $.rackBug = function(data, klass) {
    $.rackBug.init();
  }
  $.extend($.rackBug, {
    init: function() {
      var current = null;
      $('#rack_bug ul.panels li a').click(function() {
        current = $('#rack_bug #' + this.className);
        
        if (current.is(':visible')) {
          $(document).trigger('close.rackBug');
        } else {
          $('#rack_bug .panel_content').hide();
          current.show();
          $.rackBug.open();
        }
        return false;
      });
      $('#rack_bug a.remote_call').click(function() {
        $('#rack_bug_debug_window').load(this.href, null, function() {
          $('#rack_bug_debug_window a.back').click(function() {
            $(this).parent().hide();
            return false;
          });
        });
        $('#rack_bug_debug_window').show();
        return false;
      });
      $('#rack_bug a.reveal_backtrace').click(function() {
        $(this).parents("tr").next().toggle();
        return false;
      });
      $('#rack_bug a.rack_bug_close').click(function() {
        $(document).trigger('close.rackBug');
        return false;
      });
    },
    open: function() {
      $(document).bind('keydown.rackBug', function(e) {
        if (e.keyCode == 27) {
          $.rackBug.close();
        }
      });
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
  });
  $(document).bind('close.rackBug', function() {
    $(document).unbind('keydown.rackBug');
    $('.panel_content').hide();
  });
});

jQuery(function() {
  jQuery.rackBug();
});
$ = _$;
