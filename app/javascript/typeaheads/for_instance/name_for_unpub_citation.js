
function setUpInstanceNameForUnpubCitation() {

    $('#instance-name-typeahead').typeahead({highlight: true}, {
        name: 'name-typeahead',
        displayKey: 'value',
        source: nameByFullNameForUnpubCit.ttAdapter()})
        .on('typeahead:opened', function($e,datum) {
            // Start afresh.
        })
        .on('typeahead:selected', function($e,datum) {
            $('#instance_name_id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
            $('#instance_name_id').val(datum.id);
        })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select or autocomplete.
        });
}

window.setUpInstanceNameForUnpubCitation = setUpInstanceNameForUnpubCitation;

window.nameByFullNameForUnpubCit = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/names/typeaheads/for_unpub_cit/index?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/names/typeaheads/for_unpub_cit/index?name_id=' +
                $('#instance-name-id').val() +
                '&term=' + encodeURIComponent(query) + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
window.nameByFullNameForUnpubCit.initialize();
window.nameByFullNameForUnpubCit = nameByFullNameForUnpubCit;


