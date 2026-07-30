(function() {
  var dropdownSubmenuClick, hideDetails;

  $(document).on("turbo:load", function() {
  // Do NOT close the menu when submenu is clicked.

    $('body').on('click', 'span.details-toggle', function(event) {
      return hideDetails(event, $(this));
    });

    $('body').on('click', '#switch-off-details-tab', function(event) {
      return hideDetails(event, $(this));
    });

    // NOTE: under BS5 we no longer hide #search-result-details when a navbar
    // dropdown opens. The panel now stays put and the dropdown overlays it
    // (matching BS3) — see the #top-navbar z-index lift in bootstrap5-compat.css.

  });


  dropdownSubmenuClick = function(event, $element) {
    event.preventDefault();
    return event.stopPropagation();
  };

  hideDetails = function(event, $this) {
    debug('Hiding details');
    $this.addClass('hidden');
    $('.showing-details').removeClass('showing-details');
    $('div#search-result-details').hide();
    $('#search-results.something-selected').removeClass('something-selected').addClass('nothing-selected');
    return event.preventDefault();
  };

}).call(this);
