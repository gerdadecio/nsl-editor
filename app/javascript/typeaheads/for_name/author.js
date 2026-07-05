
function setUpAuthorByAbbrev() {
  if (typeof(authorsByAbbrev) != "undefined") {
  $('#author-by-abbrev').typeahead({highlight:true}, {
    name: 'authors',
    displayKey: 'value',
    source: authorsByAbbrev.ttAdapter()})
    .on('typeahead:selected', function($e,datum) {
      $('#name_author_id').val(datum.id);
      window.setDependents('author-by-abbrev')
    })
    .on('typeahead:autocompleted', function($e,datum) {
      $('#name_author_id').val(datum.id);
      window.setDependents('author-by-abbrev')
    })
    .on('typeahead:closed', function($e,datum) {
      // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
      // Users must select or autocomplete.
    });
  };
}

window.setUpAuthorByAbbrev = setUpAuthorByAbbrev;
