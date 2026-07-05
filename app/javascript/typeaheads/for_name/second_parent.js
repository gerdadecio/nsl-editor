// Used on name edit form.
function setUpNameSecondParentTypeahead() {
    if (typeof(nameParentSuggestionsForHybrid) != "undefined") {
        $("#name-second-parent-typeahead").typeahead({highlight: true}, {
            name: "preceding-name-id-second-parent",
            displayKey: 'value',
            source: nameParentSuggestionsForHybrid.ttAdapter()})
            .on('typeahead:selected', function($e,datum) {
                $('#name_second_parent_id').val(datum.id) })
            .on('typeahead:autocompleted', function($e,datum) {
                $('#name_second_parent_id').val(datum.id) })
            .on('typeahead:closed', function($e,datum) {
                // NOOP: cannot distinguish tabbing through vs emptying vs typing text.
                // Users must select or autocomplete.
            });
    }
}

window.setUpNameSecondParentTypeahead = setUpNameSecondParentTypeahead;

