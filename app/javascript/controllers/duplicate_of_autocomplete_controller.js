import { Autocomplete } from "stimulus-autocomplete"

// Connects to data-controller="duplicate-of-autocomplete"
//
// PROTOTYPE: evaluating stimulus-autocomplete as a replacement for the
// vendored, unmaintained typeahead.js + Bloodhound setup. See the "Duplicate
// of" field on the name edit form for a side-by-side comparison with the
// existing typeahead.js version.
//
// This is a thin subclass of stimulus-autocomplete's own Autocomplete
// controller. The one thing it doesn't do out of the box is let a field
// pass extra context (here, the current record's own id) into the search
// request - which we need so a record is never offered as a duplicate of
// itself. stimulus-autocomplete's documented extension point for this is
// overriding buildURL, so that's all this subclass does: call the parent's
// buildURL to get the normal "?q=<term>" URL, then add our own param to it.
//
// The avoidId value below is set once, from the server, when the page
// renders (see data-duplicate-of-autocomplete-avoid-id-value in the view).
// Fields that need a *live* value from another field on the page (e.g.
// name_parent_suggestions reading the current rank_id from a select) would
// read that field directly inside buildURL instead of using a static value
// - a harder case, deliberately not tackled in this first prototype.
export default class extends Autocomplete {
  static values = { ...Autocomplete.values, avoidId: Number }

  buildURL(query) {
    const url = new URL(super.buildURL(query))
    url.searchParams.set("name_id", this.avoidIdValue)
    return url.toString()
  }
}
