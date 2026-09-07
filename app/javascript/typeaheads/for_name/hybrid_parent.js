// The Bloodhound source for hybrid parent suggestions.
//
// Its own field - the name form's first Parent - now uses
// stimulus-autocomplete (app/views/names/form/_parent_1.html.erb), so the
// set-up function that went with this source is gone. The source stays for
// the Second parent field (second_parent.js), which is still on
// typeahead.js and shares it.

// Provides a way to inject the current name id into the URL - read
// from the Second parent input, the only field left using this source.
window.nameParentSuggestionsForHybrid = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {url: window.relative_url_root + '/suggestions/name/hybrid_parent?term=%QUERY',
        replace: function(url,query) {
            return window.relative_url_root + '/suggestions/name/hybrid_parent?' +
                'name_id=' + $('#name-second-parent-typeahead').attr('data-name-id') + '&' +
                'rank_id=' + $('#name_name_rank_id').val() + '&' +
                'term=' + encodeURIComponent(query.replace(/\|.*/,''))  + '&' + 
                'cache_buster=' + Math.floor((Math.random() * 1000) + 1).toString()
        }
    },
    limit: 100
});

// kicks off the loading/processing of `local` and `prefetch`
window.nameParentSuggestionsForHybrid.initialize();

