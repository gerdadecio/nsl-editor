import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Connects to data-controller="link-profile-item"
//
// Shows the details of the published profile item picked in the profile v2
// "Link a published profile item" field, which is what the old typeahead.js
// wiring did in its typeahead:selected handler
// (app/javascript/typeaheads/for_instance/name_for_product_item_config.js,
// now gone).
//
// It wraps the field rather than sitting on it, so the field itself stays
// on the shared autocomplete partial; autocomplete.change and input bubble
// up to here. The picked option carries its profile item id as
// data-profile-item-id, see InstancesController#typeahead_for_product_item_config.
//
// detailsUrl is ProfileItemsController#details' path, built by the server
// with PROFILE_ITEM_ID standing in for the id, so it keeps the app's
// relative url root and the instance id being linked to.
//
// The details pane always matches the input: a new pick cancels the
// request for the previous one, so a slow earlier response can't land
// after a later one, and typing clears the pane, so the previous pick's
// "Link" button can't be used while the input shows other text.
export default class extends Controller {
  static values = { detailsUrl: String }
  static targets = ["details"]

  disconnect() {
    this.abortPending()
  }

  // Wired via data-action="autocomplete.change->link-profile-item#showDetails"
  async showDetails(event) {
    this.abortPending()
    const profileItemId = event.detail.selected?.dataset.profileItemId
    if (!profileItemId) return

    const controller = new AbortController()
    this.pending = controller
    const url = this.detailsUrlValue.replace("PROFILE_ITEM_ID", encodeURIComponent(profileItemId))

    try {
      const response = await fetch(url, {
        headers: { Accept: "text/vnd.turbo-stream.html" },
        credentials: "same-origin",
        signal: controller.signal
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const html = await response.text()
      if (controller.signal.aborted) return
      Turbo.renderStreamMessage(html)
    } catch (error) {
      if (controller.signal.aborted) return
      console.error("Could not load the profile item details:", error)
      this.showError()
    } finally {
      if (this.pending === controller) this.pending = null
    }
  }

  // Wired via data-action="input->link-profile-item#clearDetails"
  clearDetails() {
    this.abortPending()
    if (this.hasDetailsTarget) this.detailsTarget.replaceChildren()
  }

  abortPending() {
    this.pending?.abort()
    this.pending = null
  }

  showError() {
    if (!this.hasDetailsTarget) return

    const message = document.createElement("p")
    message.className = "text-danger"
    message.textContent = "Could not load the details of the picked profile item. Please try again."
    this.detailsTarget.replaceChildren(message)
  }
}
