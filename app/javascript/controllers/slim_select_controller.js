import { Controller } from "@hotwired/stimulus"
import SlimSelect from 'slim-select'

// Connects to data-controller="slim-select"
export default class extends Controller {
  static values = {
    allowDeselect: { type: Boolean, default: true },
    searchable: { type: Boolean, default: true },
    closeOnSelect: { type: Boolean, default: true },
    allowCreate: { type: Boolean, default: false },
    placeholder: String,
    searchPlaceholder: { type: String, default: 'Search...' },
    createUrl: String  // URL to POST new options (for associations)
  }

  connect() {
    this.select = new SlimSelect({
      select: this.element,
      settings: {
        allowDeselect: this.allowDeselectValue,
        searchable: this.searchableValue,
        closeOnSelect: this.closeOnSelectValue,
        placeholderText: this.placeholderValue || this.element.dataset.placeholder || 'Select...',
        searchPlaceholder: this.searchPlaceholderValue,
        searchText: 'No results found',
        searchHighlight: true
      },
      events: {
        addable: this.allowCreateValue ? (value) => this.handleCreate(value) : undefined,
        afterChange: (newVal) => this.afterChange(newVal)
      }
    })
  }

  disconnect() {
    if (this.select) {
      this.select.destroy()
    }
  }

  handleCreate(value) {
    if (!value) return false

    // If createUrl is provided, POST to create association
    if (this.hasCreateUrlValue) {
      return this.createAssociation(value)
    }

    // Otherwise, just add it as a new option (for simple text fields like location)
    return value
  }

  async createAssociation(value) {
    try {
      const response = await fetch(this.createUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ name: value })
      })

      if (response.ok) {
        const data = await response.json()
        // Return the new option with id and name
        return {
          text: data.name,
          value: data.id.toString()
        }
      }
    } catch (error) {
      console.error('Error creating option:', error)
    }

    return false
  }

  afterChange(newVal) {
    // Dispatch custom event for other controllers to listen to
    this.element.dispatchEvent(new CustomEvent('slim-select:change', {
      detail: { value: newVal },
      bubbles: true
    }))
  }
}
