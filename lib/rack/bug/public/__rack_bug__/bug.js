jQuery(function() {
  jQuery("#rack_bug ul.panels li a").click(function () {
    current = $('#rack_bug #' + this.className);
    
    if (current.is(':visible')) {
      $('.panelContent').hide();
      current.hide();
    } else {
      $('.panelContent').hide();
      current.show();
    }
    
    return false;
  });
});