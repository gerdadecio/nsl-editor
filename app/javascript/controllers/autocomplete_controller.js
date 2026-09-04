import { Autocomplete } from "stimulus-autocomplete"

// Connects to data-controller="autocomplete"
//
// The single Stimulus controller behind every field migrated off the
// vendored, unmaintained typeahead.js + Bloodhound setup. It is a thin
// subclass of stimulus-autocomplete's own Autocomplete controller, adding
// only the things this app's fields need that the library doesn't do out
// of the box. The first four are opt-in per field; the last applies to
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
//    A field whose suggestions depend on another field the user can still
//    change needs liveParams instead.
//
// 2. liveParams - the same idea, but read from the page at query time
//    rather than baked in when it rendered: a hash of param name => the
//    dom id to read it from. The Parent field's suggestions are restricted
//    by the rank currently chosen in the form's Rank select, which the
//    user can change between two queries on the same field, so the rank
//    has to be read when the query is built. A param whose element isn't
//    on the page is simply left off the URL.
//
// 3. termDelimiter - what a field's suggestions are displayed as isn't
//    always what should be searched on. The Parent field's suggestions
//    read "<full name> | <rank> | <status> | <n> instances", and picking
//    one puts all of that into the input, so a user who then edits the
//    name would otherwise search for the trailing detail too. A field sets
//    this to the string its display value is built with ("|") and only the
//    text before the first one is sent as the term.
//
// 4. dependentsField - some of the old typeahead wirings called
//    window.setDependents(fieldId) after a pick, to enable/disable the
//    fields that depend on this one. Rather than have callers write their
//    own data-action for it, a field opts in by setting this value to the
//    element id setDependents should be given.
//
// 5. replaceResults - resetting the dropdown's scroll position whenever a
//    new set of suggestions lands. See the override below.
//
// The identifier is "autocomplete" - the name the library itself assumes,
// which is why an option's id attribute reads data-autocomplete-value.
// Keeping the controller here rather than in a subdirectory keeps it that
// short: Stimulus builds the identifier from the file path, so
// controllers/utilities/autocomplete_controller.js would instead have to
// be spelled data-controller="utilities--autocomplete" in the markup,
// along with every one of its target and value attributes.
//
// Markup lives in app/views/shared/_autocomplete_field.html.erb and the
// suggestion fragments in app/views/shared/_autocomplete_suggestions.html.erb;
// styling in app/assets/stylesheets/utilities/autocomplete.css.
export default class extends Autocomplete {
  static values = {
    ...Autocomplete.values,
    extraParams: Object,
    liveParams: Object,
    termDelimiter: String,
    dependentsField: String
  }

  buildURL(query) {
    const url = new URL(super.buildURL(this.termFor(query)))
    Object.entries(this.extraParamsValue).forEach(([key, value]) => {
      // A param the server had no value for is sent empty rather than as
      // the string "null" - a name being created has no id of its own yet.
      url.searchParams.set(key, value === null ? "" : value)
    })
    Object.entries(this.liveParamsValue).forEach(([key, elementId]) => {
      const source = document.getElementById(elementId)
      if (source) url.searchParams.set(key, source.value)
    })
    return url.toString()
  }

  // The typed text, minus the display-only detail a previous pick left in
  // the input - see termDelimiter above. The library has already trimmed
  // the query, but not what's left after the cut.
  termFor(query) {
    if (!this.termDelimiterValue) return query

    return query.split(this.termDelimiterValue)[0].trim()
  }

  // Wired up in the shared field partial as
  // data-action="autocomplete.change->autocomplete#syncDependents". The
  // library only fires autocomplete.change on a real commit, so this does
  // not run for the aria-disabled "No matches" row.
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
