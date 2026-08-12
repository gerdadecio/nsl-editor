import { Autocomplete } from "stimulus-autocomplete"

// Connects to data-controller="nsl-autocomplete"
//
// The single Stimulus controller behind every field migrated off the
// vendored, unmaintained typeahead.js + Bloodhound setup. It is a thin
// subclass of stimulus-autocomplete's own Autocomplete controller, adding
// only the things this app's fields need that the library doesn't do out
// of the box. The first two are opt-in per field; the third applies to
// every field.
//
// 1. extraParams - a field often has to send more than the typed term
//    (e.g. the "Duplicate of" field sends the current record's own id so a
//    record is never offered as a duplicate of itself). buildURL is the
//    library's documented extension point for that, so we call the
//    parent's buildURL to get the normal "?term=<query>" URL and merge our
//    own params onto it.
//
//    These values are set once, from the server, when the page renders.
//    Fields that need a *live* value from another field on the page (e.g.
//    name_parent_suggestions reading the current rank_id from a select)
//    will need to read that field directly inside buildURL instead - a
//    harder case, not covered here.
//
// 2. dependentsField - some of the old typeahead wirings called
//    window.setDependents(fieldId) after a pick, to enable/disable the
//    fields that depend on this one. Rather than have callers write their
//    own data-action for it, a field opts in by setting this value to the
//    element id setDependents should be given.
//
// 3. replaceResults - resetting the dropdown's scroll position whenever a
//    new set of suggestions lands. See the override below.
//
// Markup lives in app/views/shared/_autocomplete_field.html.erb and the
// suggestion fragments in app/views/shared/_autocomplete_suggestions.html.erb;
// styling in app/assets/stylesheets/autocomplete/nsl_autocomplete.css.
export default class extends Autocomplete {
  static values = {
    ...Autocomplete.values,
    extraParams: Object,
    dependentsField: String
  }

  buildURL(query) {
    const url = new URL(super.buildURL(query))
    Object.entries(this.extraParamsValue).forEach(([key, value]) => {
      url.searchParams.set(key, value)
    })
    return url.toString()
  }

  // Wired up in the shared field partial as
  // data-action="autocomplete.change->nsl-autocomplete#syncDependents".
  // The library only fires autocomplete.change on a real commit, so this
  // does not run for the aria-disabled "No matches" row.
  syncDependents() {
    if (this.dependentsFieldValue && typeof window.setDependents === "function") {
      window.setDependents(this.dependentsFieldValue)
    }
  }

  // stimulus-autocomplete's own replaceResults() only swaps the results
  // list's innerHTML - it never touches the results container's own
  // scrollTop. Since it's the same scrollable element being reused across
  // fetches (not typeahead.js's approach of rebuilding the dropdown from
  // scratch), a scroll position set while browsing one set of suggestions
  // carries straight over onto the next, freshly-fetched set. If the user
  // had scrolled down, the new list opens already scrolled down too -
  // hiding its top suggestions above the visible area, with nothing on
  // screen to suggest they exist. Resetting scrollTop to 0 whenever new
  // results land keeps every fetch starting from the top, matching what
  // the old typeahead.js dropdown did (it had no persistent scroll
  // position to carry over in the first place).
  //
  // This applies to every migrated field, not just Duplicate of: the
  // shared stylesheet gives them all the same max-height/overflow-y
  // scrolling dropdown, so they all have a scroll position to carry over.
  replaceResults(html) {
    super.replaceResults(html)
    this.resultsTarget.scrollTop = 0
  }
}
