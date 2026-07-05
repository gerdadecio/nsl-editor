
function setUpExBaseAuthorByAbbrev() {
  if (typeof(authorsByAbbrev) != "undefined") {
  $('#ex-base-author-by-abbrev').typeahead({highlight:true}, {
    name: 'ex-base-authors',
    displayKey: 'value',
    source: authorsByAbbrev.ttAdapter()})
    .on('typeahead:selected', function($e,datum) {
      $('#name_ex_base_author_id').val(datum.id);
      window.setDependents('ex-base-author-by-abbrev')
    })
    .on('typeahead:autocompleted', function($e,datum) {
      $('#name_ex_base_author_id').val(datum.id);
      window.setDependents('ex-base-author-by-abbrev')
    })
    .on('typeahead:closed', function($e,datum) {
      // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
      // Users must select or autocomplete.
    });
  };
}

window.setUpExBaseAuthorByAbbrev = setUpExBaseAuthorByAbbrev;
