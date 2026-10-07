// The synonymy tabs' name field (instances/_form_create_synonymy and
// tabs/_tab_synonymy_for_profile_v2) uses stimulus-autocomplete - see
// app/views/shared/_autocomplete_field.html.erb - so setUpSynonymyInstance
// and its instanceForSynonymy Bloodhound source have gone from here.

// Dedicated setup for the change-name form's synonym typeahead.
// Uses change-name-specific ids so it does not collide with the
// synonymy tab (_tab_synonymy_for_profile_v2), which uses the generic
// `instance-instance-for-name-showing-reference-typeahead`/`instance_cites_id` ids.
function setUpChangeNameSynonymyInstance() {
    $('#change-name-synonymy-typeahead').typeahead({highlight: true}, {
        name: 'change-name-synonymy-typeahead',
        displayKey: 'value',
        source: instanceForChangeNameSynonymy.ttAdapter()})
        .on('typeahead:selected', function($e,datum) {
            $('#change-name-synonymy-cites-id').val(datum.id);
        })
        .on('typeahead:autocompleted', function($e,datum) {
            $('#change-name-synonymy-cites-id').val(datum.id);
        })
        .on('typeahead:closed', function($e,datum) {
            // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
            // Users must select or autocomplete.
        });
}

window.setUpChangeNameSynonymyInstance = setUpChangeNameSynonymyInstance;

// Bloodhound for the change-name form, keyed off the change-name-specific
// current-name hidden field.
window.instanceForChangeNameSynonymy = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/instances/for_synonymy?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/instances/for_synonymy?name_id=' +
                $('#change-name-current-name-id').val() +
                '&term=' + encodeURIComponent(query) + '&' +
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

window.instanceForChangeNameSynonymy.initialize();

window.instanceForChangeNameSynonymy = instanceForChangeNameSynonymy;
