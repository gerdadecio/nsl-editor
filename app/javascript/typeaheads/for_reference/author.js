function setUpReferenceAuthor() {
   $('#reference-author-typeahead').typeahead({highlight: true}, {
        name: 'Authors',
        displayKey: 'value',
        source: authorsByName.ttAdapter()})
        .on('typeahead:selected', function($e,datum) {
          $('#reference_author_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
          $('#reference_author_id').val(datum.id);
        })
}

window.setUpReferenceAuthor = setUpReferenceAuthor;


window.authorsByName = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
  queryTokenizer: Bloodhound.tokenizers.whitespace,
  remote: window.relative_url_root + '/authors/typeahead_on_name?term=%QUERY',
  limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
authorsByName.initialize();

window.authorsByName = authorsByName;
