import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="copy-name-form"
//
// Guards the "copy a hybrid name" form: the parent fields start on the
// original name's parents, the new name is shown as "first parent x second
// parent" as they are changed, and the chosen parents are validated on submit.
//
// Both parents are stimulus-autocomplete fields (see
// app/views/names/form/_parent_1.html.erb and _parent_2.html.erb). Their
// input, change and autocomplete.change events bubble up to the form, where
// the view's data-action routes them to queuePreview - so Stimulus binds and
// unbinds the listeners, and this controller needs no connect/disconnect
// wiring of its own.
export default class extends Controller {
  static targets = ["preview"]

  static values = {
    originalParentId: String,
    originalSecondParentId: String,
    cultivarHybrid: Boolean,
    connector: String
  }

  connect() {
    this.updatePreview()
  }

  // The autocomplete sets (or clears) the hidden id in its own handler for
  // these events, so update on the next tick rather than racing it.
  queuePreview() {
    setTimeout(() => this.updatePreview(), 0)
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
  parentName(inputId, hiddenId) {
    if (!this.fieldValue(hiddenId)) return ""

    return this.fieldValue(inputId).replace(/\|.*/, "").trim()
  }

  // Wired via data-action="submit->copy-name-form#validate"
  validate(event) {
    const firstParent = this.fieldValue("name_parent_id")
    const secondParent = this.fieldValue("name_second_parent_id")
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
      this.showError(message)
    }
  }

  showError(message) {
    const info = document.getElementById("copy-name-info-message-container")
    const error = document.getElementById("copy-name-error-message-container")

    if (info) {
      info.replaceChildren()
      info.classList.add("hidden")
    }
    if (error) {
      error.textContent = message
      error.classList.remove("hidden")
    }
  }

  fieldValue(id) {
    return document.getElementById(id)?.value ?? ""
  }
}
