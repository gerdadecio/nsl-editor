import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="copy-name-form"
//
// Guards the "copy a hybrid name" form: clears the parent typeaheads on load so
// the copy cannot silently inherit the original's parents, and validates the
// chosen parents on submit.
export default class extends Controller {
  static values = {
    originalParentId: String,
    originalSecondParentId: String,
    cultivarHybrid: Boolean
  }

  connect() {
    this.clearParent("name-parent-typeahead", "name_parent_id")
    this.clearParent("name-second-parent-typeahead", "name_second_parent_id")
  }

  // Start empty so the copy cannot silently inherit the original's parents.
  clearParent(typeaheadId, hiddenId) {
    const $typeahead = window.$("#" + typeaheadId)
    if ($typeahead.hasClass("tt-input")) {
      $typeahead.typeahead("val", "")
    }
    $typeahead.val("")
    window.$("#" + hiddenId).val("")
  }

  // Wired via data-action="submit->copy-name-form#validate"
  validate(event) {
    const firstParent = document.getElementById("name_parent_id").value
    const secondParent = document.getElementById("name_second_parent_id").value
    let message = null

    if (!firstParent) {
      message = "Please choose a first parent for the copy."
    } else if (firstParent === this.originalParentIdValue) {
      message = "The first parent must differ from the original name's first parent."
    } else if (!secondParent) {
      message = "Please choose a second parent for the copy."
    } else if (secondParent === this.originalSecondParentIdValue) {
      message = "The second parent must differ from the original name's second parent."
    } else if (!this.cultivarHybridValue && firstParent === secondParent) {
      message = "The second parent cannot be the same as the first parent."
    }

    if (message) {
      event.preventDefault()
      event.stopImmediatePropagation()
      window.$("#copy-name-info-message-container").html("").addClass("hidden")
      window.$("#copy-name-error-message-container").html(message).removeClass("hidden")
    }
  }
}
