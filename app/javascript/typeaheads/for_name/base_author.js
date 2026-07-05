
function setUpBaseAuthorByAbbrev() {
  if (typeof(authorsByAbbrev) != "undefined") {
    $('#base-author-by-abbrev').typeahead({highlight: true}, {
      name: 'base-authors',
      displayKey: 'value',
      source: authorsByAbbrev.ttAdapter()})
      .on('typeahead:selected', function($e,datum) {
        $('#name_base_author_id').val(datum.id);
      })
      .on('typeahead:autocompleted', function($e,datum) {
        $('#name_base_author_id').val(datum.id);
      })
      .on('typeahead:closed', function($e,datum) {
        // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
        // Users must select or autocomplete.
      });
  };
}

window.setUpBaseAuthorByAbbrev = setUpBaseAuthorByAbbrev;
