import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    console.log("dropdown controller connected")

    // Close dropdown when clicking outside
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.boundHandleClickOutside)
  }

  disconnect() {
    document.removeEventListener('click', this.boundHandleClickOutside)
  }

  toggle(event) {
    event.stopPropagation()
    
    if (this.contentTarget.classList.contains("hidden")) {
      this.open(event)
    } else {
      this.close()
    }
  }

  open(event) {
    // Position dropdown relative to button since it's now fixed
    const buttonRect = event.target.getBoundingClientRect()
    const dropdown = this.contentTarget
    
    dropdown.style.top = `${buttonRect.bottom + 4}px`
    dropdown.style.left = `${buttonRect.left}px`
    dropdown.style.width = `${Math.max(buttonRect.width, 250)}px`
    dropdown.style.minWidth = '250px'
    
    dropdown.classList.remove("hidden")
  }

  handleClickOutside(event) {
    // Check if click is outside both the controller element AND the dropdown content
    if (!this.element.contains(event.target) && !this.contentTarget.contains(event.target)) {
      this.close()
    }
  }

  close() {
    const dropdown = this.contentTarget
    dropdown.classList.add("hidden")
    
    // Clear positioning styles when closing
    dropdown.style.top = ''
    dropdown.style.left = ''
    dropdown.style.width = ''
    dropdown.style.minWidth = ''
  }
}