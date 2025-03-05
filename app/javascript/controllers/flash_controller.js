import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.element.innerHTML = "";
    }, 3000); // Clear content after 3 seconds
  }
}
