import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  updateSetting(event) {
    const checkbox = event.target
    const form = this.element
    const statusElement = this.statusTarget

    // Show loading state
    this.showStatus("Updating setting...", "text-gray-600")

    // Create form data from the form (this handles Rails form structure automatically)
    const formData = new FormData(form)

    // Submit the form via fetch
    fetch(form.action, {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "application/json"
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.showStatus("Setting saved successfully!", "text-green-600")
        setTimeout(() => this.hideStatus(), 3000)
      } else {
        this.showStatus(data.message || "Failed to update setting", "text-red-600")
        // Revert checkbox state on error
        checkbox.checked = !checkbox.checked
      }
    })
    .catch(error => {
      console.error("Error updating setting:", error)
      this.showStatus("An error occurred while updating the setting", "text-red-600")
      // Revert checkbox state on error
      checkbox.checked = !checkbox.checked
    })
  }

  showStatus(message, colorClass) {
    const statusElement = this.statusTarget
    statusElement.textContent = message
    statusElement.className = `text-sm mt-2 ${colorClass}`
    statusElement.classList.remove("hidden")
  }

  hideStatus() {
    this.statusTarget.classList.add("hidden")
  }
}