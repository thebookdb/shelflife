import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static values = { libraryId: Number }

  connect() {
    this.boundClose = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.boundClose)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  setGroupBy(event) {
    event.preventDefault()
    const value = event.currentTarget.dataset.value
    this.saveSetting(`library_${this.libraryIdValue}_group_by`, value)
  }

  moveUp(event) {
    event.preventDefault()
    this.reorder("up")
  }

  moveDown(event) {
    event.preventDefault()
    this.reorder("down")
  }

  async saveSetting(key, value) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch("/profile/dashboard_settings", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token
      },
      body: JSON.stringify({ key, value })
    })
    window.location.reload()
  }

  async reorder(direction) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch("/profile/dashboard_settings", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token
      },
      body: JSON.stringify({
        key: "reorder_library",
        value: { library_id: this.libraryIdValue, direction }
      })
    })
    window.location.reload()
  }
}
