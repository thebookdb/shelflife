import { Controller } from "@hotwired/stimulus"
import { Html5Qrcode, Html5QrcodeSupportedFormats } from "html5-qrcode"

export default class extends Controller {
  static targets = ["scanner", "placeholder", "startButton", "stopButton", "librarySelect", "scanOverlay", "libraryStatus"]
  static values = {
    scanning: { type: Boolean, default: false },
    currentOrientation: { type: String, default: "portrait" }
  }

  connect() {
    this.loadLibraryPreference()
    this.setupOrientationDetection()
  }

  loadLibraryPreference() {
    if (this.hasLibrarySelectTarget) {
      this.librarySelectTarget.addEventListener('change', this.onLibraryChange.bind(this))
    }
  }

  async onLibraryChange(event) {
    const libraryId = event.target.value
    try {
      await fetch('/scanner/set_library', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ library_id: libraryId })
      })
    } catch (error) {
      console.error('Error setting library:', error)
    }
  }

  setupOrientationDetection() {
    this.detectOrientation()

    if (screen.orientation) {
      screen.orientation.addEventListener('change', this.onOrientationChange.bind(this))
    }
    window.addEventListener('resize', this.onOrientationChange.bind(this))
  }

  detectOrientation() {
    const isLandscape = window.innerWidth > window.innerHeight
    const newOrientation = isLandscape ? "landscape" : "portrait"

    if (newOrientation !== this.currentOrientationValue) {
      this.currentOrientationValue = newOrientation

      // If scanning, restart with orientation-appropriate config
      if (this.scanningValue) {
        this.restartScannerForOrientation()
      }
    }
  }

  onOrientationChange() {
    clearTimeout(this.orientationTimeout)
    this.orientationTimeout = setTimeout(() => {
      this.detectOrientation()
    }, 300)
  }

  getScannerConfig() {
    const isLandscape = this.currentOrientationValue === "landscape"
    return {
      fps: 10,
      qrbox: isLandscape ? { width: 400, height: 200 } : { width: 250, height: 150 },
      formatsToSupport: [Html5QrcodeSupportedFormats.EAN_13],
      aspectRatio: isLandscape ? 2.0 : 1.777778,
      disableFlip: false
    }
  }

  async restartScannerForOrientation() {
    if (this.scanner) {
      try {
        await this.scanner.stop()
        this.scanner.clear()
        this.scanner = null
      } catch (error) {
        console.error("Error stopping scanner:", error)
      }
    }

    this.scannerTarget.classList.add("hidden")
    setTimeout(() => { this.initializeScanner() }, 500)
  }

  startScanning() {
    if (this.scanningValue) return

    this.scanningValue = true
    this.hideNavigation()

    this.startButtonTarget.classList.add("hidden")
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden")
    if (this.hasScanOverlayTarget) this.scanOverlayTarget.classList.remove("hidden")

    this.initializeScanner()
  }

  async initializeScanner() {
    this.scannerTarget.classList.remove("hidden")

    const config = this.getScannerConfig()
    this.scanner = new Html5Qrcode(this.scannerTarget.id)

    try {
      await this.scanner.start(
        { facingMode: "environment" },
        config,
        this.onScanSuccess.bind(this),
        this.onScanFailure.bind(this)
      )
    } catch (error) {
      console.error("Error starting scanner:", error)
    }
  }

  stopScanning() {
    if (!this.scanningValue) return

    this.scanningValue = false
    this.showNavigation()

    this.startButtonTarget.classList.remove("hidden")
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.remove("hidden")
    if (this.hasScanOverlayTarget) this.scanOverlayTarget.classList.add("hidden")

    this.scannerTarget.classList.add("hidden")

    if (this.scanner) {
      this.scanner.stop().then(() => {
        this.scanner.clear()
        this.scanner = null
      }).catch(error => {
        console.error("Failed to stop scanner:", error)
        this.scanner = null
      })
    }
  }

  onScanSuccess(decodedText, decodedResult) {
    if (decodedText && /^\d{13}$/.test(decodedText)) {
      if (navigator.vibrate) {
        navigator.vibrate(200)
      }
      this.submitScan(decodedText)
    }
  }

  onScanFailure(error) {
    // Normal during scanning — no action needed
  }

  async submitScan(gtin) {
    const libraryId = this.hasLibrarySelectTarget ? this.librarySelectTarget.value : ''

    try {
      const response = await fetch('/library_items', {
        method: 'POST',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ gtin: gtin, library_id: libraryId || null })
      })

      if (response.ok) {
        const contentType = response.headers.get('Content-Type')
        if (contentType && contentType.includes('text/vnd.turbo-stream.html')) {
          const turboStreamData = await response.text()
          Turbo.renderStreamMessage(turboStreamData)
        }
      }
    } catch (error) {
      console.error('Error submitting scan:', error)
    }
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  hideNavigation() {
    const nav = document.querySelector('nav')
    const actionBar = document.getElementById('action-bar')
    if (nav) {
      this.originalNavDisplay = this.originalNavDisplay || nav.style.display
      nav.style.display = 'none'
      if (actionBar) actionBar.style.display = 'none'

      const main = document.querySelector('main')
      if (main) main.style.marginTop = '0'

      this.element.classList.remove('top-28')
      this.element.classList.add('top-0')
    }
  }

  showNavigation() {
    const nav = document.querySelector('nav')
    const actionBar = document.getElementById('action-bar')
    if (nav) {
      nav.style.display = this.originalNavDisplay || ''
      if (actionBar) actionBar.style.display = ''

      const main = document.querySelector('main')
      if (main) main.style.marginTop = ''

      this.element.classList.remove('top-0')
      this.element.classList.add('top-28')
    }
  }

  disconnect() {
    this.stopScanning()

    if (screen.orientation) {
      screen.orientation.removeEventListener('change', this.onOrientationChange.bind(this))
    }
    window.removeEventListener('resize', this.onOrientationChange.bind(this))
    clearTimeout(this.orientationTimeout)
  }
}
