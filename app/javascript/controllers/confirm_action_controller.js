import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="confirm-action"
//
// The two-step "Delete..." / "Confirm delete" / "Cancel" widgets (and the
// same pattern for other actions, such as Refresh... and Copy...). Each link
// carries this controller and one action:
//
//   reveal  - the "Delete..." (or "Refresh..." etc.) link: shows the confirm
//             container named by data-show-this-id, hides the element named
//             by data-hide-this-id, and disables itself
//   cancel  - the "Cancel" link: hides data-hide-this-id, re-enables
//             data-enable-this-id, shows data-show-this-id, and empties the
//             elements with the class in data-empty-this-class
//   confirm - the "Confirm delete" link: shows a spinner and disables itself
//             and its sibling cancel link. It doesn't prevent the default, so
//             rails-ujs still sends the remote request.
//
// The data-*-this-id attributes are the ones the old jQuery handlers
// (unconfirmed_action_link_click.js, cancel_link_click.js and
// confirm_delete_link_click.js) read, so the views keep them as they are.
export default class extends Controller {
  reveal(event) {
    event.preventDefault()
    const { showThisId, hideThisId } = this.element.dataset

    this.#byId(showThisId)?.classList.remove("hidden")
    this.#byId(hideThisId)?.classList.add("hidden")
    this.element.classList.add("disabled")
    this.#empty(".message-container")
  }

  cancel(event) {
    event.preventDefault()
    const { hideThisId, enableThisId, showThisId, emptyThisClass } = this.element.dataset

    this.#byId(hideThisId)?.classList.add("hidden")
    this.#byId(enableThisId)?.classList.remove("disabled")
    this.#byId(showThisId)?.classList.remove("hidden")
    if (emptyThisClass) this.#empty(`.${CSS.escape(emptyThisClass)}`)
    this.#empty(".message-container")
    this.#empty(".error-container")
  }

  confirm() {
    const spinner = document.createElement("i")
    spinner.className = "fa fa-spinner fa-spin"
    this.element.setAttribute("disabled", "disabled")
    this.element.prepend(spinner, " ")

    const parent = this.element.parentElement
    if (!parent) return
    for (const sibling of parent.children) {
      if (sibling !== this.element && sibling.matches(".cancel-link")) {
        sibling.setAttribute("disabled", "disabled")
      }
    }
  }

  #byId(id) {
    return id ? document.getElementById(id) : null
  }

  #empty(selector) {
    document.querySelectorAll(selector).forEach((element) => { element.innerHTML = "" })
  }
}
