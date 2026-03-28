import { Controller } from "@hotwired/stimulus"
import { Html5Qrcode, Html5QrcodeSupportedFormats } from "html5-qrcode"

export default class extends Controller {
  static targets = ["portraitScanner", "landscapeScanner", "result", "portraitPlaceholder", "landscapePlaceholder", "startButton", "stopButton", "librarySelect", "scanResult", "libraryStatus", "orientationDisplay", "portraitLayout", "landscapeLayout", "portraitScannerArea", "landscapeScannerArea"]
  static values = {
    scanning: { type: Boolean, default: false },
    currentOrientation: { type: String, default: "portrait" }
  }

  connect() {
    console.log("Barcode scanner controller connected")
    
    // Load saved library preference
    this.loadLibraryPreference()
    
    // Set up orientation detection
    this.setupOrientationDetection()
  }
  
  
  loadLibraryPreference() {
    // Add event listener to library dropdown
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
    // Initial orientation detection
    this.detectOrientation()
    
    // Listen for orientation changes
    if (screen.orientation) {
      screen.orientation.addEventListener('change', this.onOrientationChange.bind(this))
    }
    
    // Fallback: listen for resize events
    window.addEventListener('resize', this.onOrientationChange.bind(this))
    
    // Also listen for device orientation events
    window.addEventListener('deviceorientationchange', this.onOrientationChange.bind(this))
  }
  
  detectOrientation() {
    const isLandscape = window.innerWidth > window.innerHeight
    const newOrientation = isLandscape ? "landscape" : "portrait"
    
    if (newOrientation !== this.currentOrientationValue) {
      const oldOrientation = this.currentOrientationValue
      this.currentOrientationValue = newOrientation
      
      console.log(`Orientation changed: ${oldOrientation} → ${newOrientation}`)
      
      // Update UI to show current orientation
      this.updateOrientationDisplay()
      
      // If we're currently scanning, restart with new settings
      if (this.scanningValue) {
        this.restartScannerForOrientation()
      }
    }
  }
  
  onOrientationChange() {
    // Debounce orientation changes to avoid rapid switching
    clearTimeout(this.orientationTimeout)
    this.orientationTimeout = setTimeout(() => {
      this.detectOrientation()
    }, 300)
  }
  
  updateOrientationDisplay() {
    if (this.hasOrientationDisplayTarget) {
      const icon = this.currentOrientationValue === "landscape" ? "📱" : "📲"
      const text = this.currentOrientationValue === "landscape" ? "Landscape" : "Portrait"
      this.orientationDisplayTarget.innerHTML = `${icon} ${text}`
    }
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
    console.log(`Restarting scanner for ${this.currentOrientationValue} mode`)

    if (this.scanner) {
      try {
        await this.scanner.stop()
        this.scanner.clear()
        this.scanner = null
      } catch (error) {
        console.error("Error stopping scanner:", error)
      }
    }

    if (this.hasPortraitScannerTarget) this.portraitScannerTarget.classList.add("hidden")
    if (this.hasLandscapeScannerTarget) this.landscapeScannerTarget.classList.add("hidden")

    setTimeout(() => { this.initializeScanner() }, 500)
  }

  startScanning() {
    if (this.scanningValue) return

    console.log(`Starting adaptive scanning in ${this.currentOrientationValue} mode...`)
    this.scanningValue = true
    
    // Hide navigation for mobile
    this.hideNavigation()
    
    // Update UI state
    this.startButtonTarget.classList.add("hidden")
    this.updateStopButtonVisibility(true)
    
    // Hide the correct placeholder based on orientation
    if (this.currentOrientationValue === "landscape" && this.hasLandscapePlaceholderTarget) {
      this.landscapePlaceholderTarget.classList.add("hidden")
    } else if (this.currentOrientationValue === "portrait" && this.hasPortraitPlaceholderTarget) {
      this.portraitPlaceholderTarget.classList.add("hidden")
    }
    
    if (this.hasScanResultTarget) {
      this.scanResultTarget.classList.remove("hidden")
    }
    
    // Update orientation display
    this.updateOrientationDisplay()
    
    // Initialize scanner with orientation-appropriate settings
    this.initializeScanner()
  }
  
  async initializeScanner() {
    // Get the correct scanner element based on current orientation
    const scannerTarget = this.getCurrentScannerTarget()
    if (!scannerTarget) {
      console.error("No scanner target available for current orientation:", this.currentOrientationValue)
      return
    }
    
    console.log("Initializing adaptive scanner on element:", scannerTarget.id, scannerTarget)
    
    // Show the scanner element
    scannerTarget.classList.remove("hidden")
    
    const config = this.getScannerConfig()
    console.log(`Using ${this.currentOrientationValue} configuration:`, config)

    this.scanner = new Html5Qrcode(scannerTarget.id)

    try {
      await this.scanner.start(
        { facingMode: "environment" },
        config,
        this.onScanSuccess.bind(this),
        this.onScanFailure.bind(this)
      )
      console.log("Scanner started successfully")
    } catch (error) {
      console.error("Error starting scanner:", error)
      this.showError("Camera access failed. Please check permissions.")
    }
  }
  
  getCurrentScannerTarget() {
    if (this.currentOrientationValue === "landscape" && this.hasLandscapeScannerTarget) {
      return this.landscapeScannerTarget
    } else if (this.currentOrientationValue === "portrait" && this.hasPortraitScannerTarget) {
      return this.portraitScannerTarget
    }
    return null
  }
  
  updateStopButtonVisibility(show) {
    // Get all stop buttons (there are multiple in different layouts)
    const stopButtons = this.element.querySelectorAll('[data-barcode-scanner-target="stopButton"]')
    
    stopButtons.forEach(button => {
      if (show) {
        button.classList.remove("hidden")
      } else {
        button.classList.add("hidden")
      }
    })
    
    console.log(`${show ? 'Showing' : 'Hiding'} ${stopButtons.length} stop button(s)`)
  }

  stopScanning() {
    if (!this.scanningValue) return

    console.log("Stopping scanner...")
    this.scanningValue = false
    
    // Show navigation again for mobile
    this.showNavigation()
    
    // Update UI state
    this.startButtonTarget.classList.remove("hidden")
    this.updateStopButtonVisibility(false)
    
    // Show the correct placeholder based on orientation
    if (this.currentOrientationValue === "landscape" && this.hasLandscapePlaceholderTarget) {
      this.landscapePlaceholderTarget.classList.remove("hidden")
    } else if (this.currentOrientationValue === "portrait" && this.hasPortraitPlaceholderTarget) {
      this.portraitPlaceholderTarget.classList.remove("hidden")
    }
    
    // Hide both scanner elements
    if (this.hasPortraitScannerTarget) {
      this.portraitScannerTarget.classList.add("hidden")
    }
    if (this.hasLandscapeScannerTarget) {
      this.landscapeScannerTarget.classList.add("hidden")
    }
    
    if (this.hasScanResultTarget) {
      this.scanResultTarget.classList.add("hidden")
    }
    
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
    console.log(`Barcode detected (${this.currentOrientationValue} mode):`, decodedText)
    
    // Validate GTIN-13 format (13 digits)
    if (decodedText && /^\d{13}$/.test(decodedText)) {
      // Haptic feedback on mobile if supported
      if (navigator.vibrate) {
        navigator.vibrate(200)
      }
      
      // Always use the unified scan endpoint
      this.submitScan(decodedText)
    } else {
      console.log("Invalid GTIN-13 format:", decodedText)
      this.showError(`Invalid barcode format: ${decodedText}`)
    }
  }

  onScanFailure(error) {
    // Handle scan failure - this is called continuously during scanning
    // We don't need to log every failure as it's normal during scanning
  }

  async submitScan(gtin) {
    // Get selected library id from the dropdown
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
        // Check if we got a turbo stream response
        const contentType = response.headers.get('Content-Type')
        if (contentType && contentType.includes('text/vnd.turbo-stream.html')) {
          const turboStreamData = await response.text()
          Turbo.renderStreamMessage(turboStreamData)
        }

        // Continue scanning after showing result briefly (for continuous scanning contexts)
        // Brief pause before resuming scan
        setTimeout(() => {}, 2000)
      } else {
        this.showError('Failed to process scan')
      }
    } catch (error) {
      console.error('Error submitting scan:', error)
      this.showError('Network error while processing scan')
    }
  }
  
  showError(message) {
    console.error("Scanner error:", message)
  }
  
  getProductIdFromDisplay() {
    // Extract product ID from the current display (could be from a data attribute)
    const productDisplay = document.getElementById('product-display')
    return productDisplay?.dataset?.productId
  }
  
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }
  
  getDefaultDisplayContent() {
    return `
      <div class="bg-white rounded-lg shadow-md p-6 text-center">
        <div class="text-6xl mb-4">📚</div>
        <h2 class="text-xl font-semibold text-gray-800 mb-2">Ready to Scan</h2>
        <p class="text-gray-600 mb-4">Point your camera at a barcode to get started</p>
        <div class="bg-blue-50 rounded-lg p-4 text-left">
          <h3 class="font-semibold text-blue-800 mb-2">How it works:</h3>
          <ul class="text-sm text-blue-700 space-y-1">
            <li>• Tap 'Start Scanning' above</li>
            <li>• Point camera at book barcode</li>  
            <li>• Product info appears here instantly</li>
            <li>• Add to your library</li>
          </ul>
        </div>
      </div>
    `
  }

  
  
  
  // Navigation hiding/showing for mobile
  hideNavigation() {
    const nav = document.querySelector('nav')
    const actionBar = document.getElementById('action-bar')
    if (nav) {
      this.originalNavDisplay = this.originalNavDisplay || nav.style.display
      nav.style.display = 'none'
      if (actionBar) actionBar.style.display = 'none'

      const main = document.querySelector('main')
      if (main) main.style.marginTop = '0'

      const scannerContainer = this.element
      if (scannerContainer) {
        scannerContainer.classList.remove('top-28')
        scannerContainer.classList.add('top-0')
      }
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

      const scannerContainer = this.element
      if (scannerContainer) {
        scannerContainer.classList.remove('top-0')
        scannerContainer.classList.add('top-28')
      }
    }
  }

  disconnect() {
    this.stopScanning()
    
    // Clean up event listeners
    if (screen.orientation) {
      screen.orientation.removeEventListener('change', this.onOrientationChange.bind(this))
    }
    window.removeEventListener('resize', this.onOrientationChange.bind(this))
    window.removeEventListener('deviceorientationchange', this.onOrientationChange.bind(this))
    
    clearTimeout(this.orientationTimeout)
  }
}