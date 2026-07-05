
function setUpSanctioningAuthorByAbbrev() {
  if (typeof(authorsByAbbrev) != "undefined") {
    $('#sanctioning-author-by-abbrev').typeahead({highlight: true}, {
      name: 'sanctioning-authors',
      displayKey: 'value',
      source: authorsByAbbrev.ttAdapter()})
      .on('typeahead:selected', function($e,datum) {
        $('#name_sanctioning_author_id').val(datum.id);
      })
      .on('typeahead:autocompleted', function($e,datum) {
        $('#name_sanctioning_author_id').val(datum.id);
      })
      .on('typeahead:closed', function($e,datum) {
        // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
        // Users must select or autocomplete.
      });
  };
}

window.setUpSanctioningAuthorByAbbrev = setUpSanctioningAuthorByAbbrev;
