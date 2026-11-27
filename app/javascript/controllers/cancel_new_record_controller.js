import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="cancel-new-record"
//
// The Cancel link on a new-record form (name, author, reference, user,
// loader batch, loader name): clears the details pane and removes the
// placeholder search-result row named by data-element-id.
export default class extends Controller {
  cancel(event) {
    event.preventDefault()
    event.stopPropagation()

    const details = document.getElementById("search-result-details")
    if (details) details.innerHTML = ""

    const { elementId } = this.element.dataset
    if (elementId) document.getElementById(elementId)?.remove()
  }
}
