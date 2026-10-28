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
// on the shared autocomplete partial; autocomplete.change bubbles up to
// here. The picked option carries its profile item id as
// data-profile-item-id, see InstancesController#typeahead_for_product_item_config.
//
// detailsUrl is ProfileItemsController#details' path, built by the server
// with PROFILE_ITEM_ID standing in for the id, so it keeps the app's
// relative url root and the instance id being linked to.
export default class extends Controller {
  static values = { detailsUrl: String }

  // Wired via data-action="autocomplete.change->link-profile-item#showDetails"
  async showDetails(event) {
    const profileItemId = event.detail.selected?.dataset.profileItemId
    if (!profileItemId) return

    const url = this.detailsUrlValue.replace("PROFILE_ITEM_ID", encodeURIComponent(profileItemId))
    const response = await fetch(url, {
      headers: { Accept: "text/vnd.turbo-stream.html" },
      credentials: "same-origin"
    })
    if (!response.ok) return

    Turbo.renderStreamMessage(await response.text())
  }
}
