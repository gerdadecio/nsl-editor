import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="copy-name-form"
//
// Guards the "copy a hybrid name" form: the parent typeaheads start on the
// original name's parents, the new name is shown as "first parent x second
// parent" as they are changed, and the chosen parents are validated on submit.
export default class extends Controller {
  static targets = ["preview"]

  static values = {
    originalParentId: String,
    originalSecondParentId: String,
    cultivarHybrid: Boolean,
    connector: String
  }

  // Namespaced so disconnect() can unbind only our handlers.
  static PARENT_EVENTS =
    "typeahead:selected.copyNamePreview typeahead:autocompleted.copyNamePreview " +
    "typeahead:change.copyNamePreview input.copyNamePreview change.copyNamePreview"

  // The first parent is a stimulus-autocomplete field (see
  // app/views/names/form/_parent_1.html.erb), which announces a pick with
  // its own bubbling event instead of the typeahead.js ones above. jQuery
  // reads the "." in the name as a namespace separator, so this one is
  // bound natively - on this element, the form, which the event reaches on
  // its way up from the field.
  static AUTOCOMPLETE_EVENT = "autocomplete.change"

  connect() {
    this.onParentChange = () => setTimeout(() => this.updatePreview(), 0)
    this.watchParents()
    this.updatePreview()
  }

  disconnect() {
    window.$("#name-parent-typeahead, #name-second-parent-typeahead")
      .off(".copyNamePreview")
    this.element.removeEventListener(this.constructor.AUTOCOMPLETE_EVENT,
                                     this.onParentChange)
  }

  // The typeaheads set their hidden id fields in their own handlers for these
  // events, so update on the next tick rather than racing them.
  watchParents() {
    window.$("#name-parent-typeahead, #name-second-parent-typeahead")
      .on(this.constructor.PARENT_EVENTS, this.onParentChange)
    this.element.addEventListener(this.constructor.AUTOCOMPLETE_EVENT,
                                  this.onParentChange)
  }

  // "first parent x second parent", from whichever parents have been chosen.
  updatePreview() {
    if (!this.hasPreviewTarget) return

    const connector = this.connectorValue || "x"
    const parents = [
      this.parentName("name-parent-typeahead", "name_parent_id"),
      this.parentName("name-second-parent-typeahead", "name_second_parent_id")
    ].filter(Boolean)

    this.previewTarget.value = parents.join(` ${connector} `)
  }

  // Only a parent picked from the suggestions counts - free text has no id.
  // The suggestion text is "full name | rank | status", so keep the name.
  parentName(typeaheadId, hiddenId) {
    const id = window.$("#" + hiddenId).val()
    if (!id) return ""

    return window.$("#" + typeaheadId).val().replace(/\|.*/, "").trim()
  }

  // Wired via data-action="submit->copy-name-form#validate"
  validate(event) {
    const firstParent = document.getElementById("name_parent_id").value
    const secondParent = document.getElementById("name_second_parent_id").value
    let message = null

    if (!firstParent) {
      message = "Please choose a first parent for the copy."
    } else if (!secondParent) {
      message = "Please choose a second parent for the copy."
    } else if (firstParent === this.originalParentIdValue &&
               secondParent === this.originalSecondParentIdValue) {
      // The form opens on the original's parents, so an untouched pair is a
      // copy of the same name.
      message = "Please change at least one parent - the copy would be the same name."
    } else if (!this.cultivarHybridValue && firstParent === secondParent) {
      message = "The second parent cannot be the same as the first parent."
    } else if (this.hasPreviewTarget && !this.previewTarget.value.trim()) {
      message = "Please choose both parents from the suggestion lists so the new name can be built."
    }

    if (message) {
      event.preventDefault()
      event.stopImmediatePropagation()
      window.$("#copy-name-info-message-container").html("").addClass("hidden")
      window.$("#copy-name-error-message-container").html(message).removeClass("hidden")
    }
  }
}
