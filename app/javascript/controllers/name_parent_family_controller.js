import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="name-parent-family"
//
// Keeps the name form's Family field in step with its Parent field: picking
// a parent fills Family in from that parent's own family, which is what the
// old typeahead.js wiring did in its typeahead:selected/autocompleted
// handlers (app/javascript/typeaheads/for_name/parent.js, now gone).
//
// It wraps the Parent field rather than sitting on it, so the field itself
// stays on the shared autocomplete partial with no per-field controller of
// its own; autocomplete.change bubbles up to here.
//
// The family comes from the picked suggestion itself - the endpoint
// publishes it as data-family-id/data-family-value on each option, see
// Name::Typeaheads#name_parent_suggestions. Hybrid and cultivar names take
// their parents from endpoints that send no family with a suggestion, so
// this is a no-op for them, as the old wiring also was: only the plain
// parent typeahead ever set the family.
export default class extends Controller {
  // Wired via data-action="autocomplete.change->name-parent-family#sync"
  sync(event) {
    const picked = event.detail.selected
    if (!picked || picked.dataset.familyId === undefined) return

    const hidden = document.getElementById("name_family_id")
    if (hidden) hidden.value = picked.dataset.familyId

    this.showFamily(picked.dataset.familyValue || "")
  }

  // The Family field is still a typeahead.js widget, so set its value
  // through the widget rather than on the input: typeahead.js keeps its own
  // copy of the current query, and writing straight to the input would
  // leave that stale. Falls back to the input for when Family is migrated
  // too and the plugin is no longer there.
  showFamily(value) {
    const input = document.getElementById("name-family-typeahead")
    if (!input) return

    const jQuery = window.$
    if (jQuery && jQuery.fn && jQuery.fn.typeahead) {
      jQuery(input).typeahead("val", value)
    } else {
      input.value = value
    }
  }
}
