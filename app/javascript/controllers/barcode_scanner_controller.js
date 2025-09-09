import { Controller } from "@hotwired/stimulus"
import { Html5QrcodeScanner, Html5QrcodeSupportedFormats } from "html5-qrcode"

export default class extends Controller {
  static targets = ["portraitScanner", "landscapeScanner", "result", "portraitPlaceholder", "landscapePlaceholder", "startButton", "stopButton", "librarySelect", "scanResult", "libraryStatus", "orientationDisplay", "portraitLayout", "landscapeLayout", "portraitScannerArea", "landscapeScannerArea"]
  static values = { 
    scanning: { type: Boolean, default: false },
    scannerPage: { type: Boolean, default: false },
    currentOrientation: { type: String, default: "portrait" }
  }

  connect() {
    console.log("Barcode scanner controller connected", { scannerPage: this.scannerPageValue })
    
    // Initialize mobile-specific features for scanner page
    if (this.scannerPageValue) {
      this.initializeMobileFeatures()
    }
    
    // Load saved library preference
    this.loadLibraryPreference()
    
    // Set up orientation detection
    this.setupOrientationDetection()
  }
  
  initializeMobileFeatures() {
    // Store original nav visibility for restoration
    this.originalNavDisplay = null
  }
  
  loadLibraryPreference() {
    // Add event listener to library dropdown
    if (this.hasLibrarySelectTarget) {
      this.librarySelectTarget.addEventListener('change', this.onLibraryChange.bind(this))
    }
  }
  
  async onLibraryChange(event) {
    const libraryName = event.target.value
    
    try {
      await fetch('/scanner/set_library', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ library_name: libraryName })
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
    
    if (isLandscape) {
      // Horizontal/Landscape configuration
      return {
        fps: 10,
        qrbox: { width: 400, height: 200 },
        formatsToSupport: [Html5QrcodeSupportedFormats.EAN_13],
        showTorchButtonIfSupported: true,
        showZoomSliderIfSupported: true,
        defaultZoomValueIfSupported: 2,
        useBarCodeDetectorIfSupported: true,
        verbose: true,
        aspectRatio: 2.0,
        disableFlip: false,
        rememberLastUsedCamera: true
      }
    } else {
      // Vertical/Portrait configuration
      return {
        fps: 10,
        qrbox: { width: 250, height: 150 },
        formatsToSupport: [Html5QrcodeSupportedFormats.EAN_13],
        showTorchButtonIfSupported: true,
        showZoomSliderIfSupported: true,
        defaultZoomValueIfSupported: 2,
        useBarCodeDetectorIfSupported: true,
        verbose: true,
        aspectRatio: 1.777778,
        disableFlip: false
      }
    }
  }
  
  async restartScannerForOrientation() {
    console.log(`Restarting scanner for ${this.currentOrientationValue} mode`)
    
    // Stop current scanner
    if (this.scanner) {
      try {
        await this.scanner.clear()
        this.scanner = null
      } catch (error) {
        console.error("Error clearing scanner:", error)
      }
    }
    
    // Hide both scanner elements
    if (this.hasPortraitScannerTarget) {
      this.portraitScannerTarget.classList.add("hidden")
    }
    if (this.hasLandscapeScannerTarget) {
      this.landscapeScannerTarget.classList.add("hidden")
    }
    
    // Brief pause to ensure cleanup
    setTimeout(() => {
      this.initializeScanner()
    }, 500)
  }

  startScanning() {
    if (this.scanningValue) return

    console.log(`Starting adaptive scanning in ${this.currentOrientationValue} mode...`)
    this.scanningValue = true
    
    // Hide navigation for mobile scanner page
    if (this.scannerPageValue) {
      this.hideNavigation()
    }
    
    // Update UI state
    this.startButtonTarget.classList.add("hidden")
    this.updateStopButtonVisibility(true)
    
    // Hide the correct placeholder based on orientation
    if (this.currentOrientationValue === "landscape" && this.hasLandscapePlaceholderTarget) {
      this.landscapePlaceholderTarget.classList.add("hidden")
    } else if (this.currentOrientationValue === "portrait" && this.hasPortraitPlaceholderTarget) {
      this.portraitPlaceholderTarget.classList.add("hidden")
    }
    
    // Update result display
    if (this.hasResultTarget) {
      this.resultTarget.textContent = "Scanning... Point camera at barcode"
    }
    if (this.hasScanResultTarget) {
      this.scanResultTarget.classList.remove("hidden")
    }
    
    // Update orientation display
    this.updateOrientationDisplay()
    
    // Initialize scanner with orientation-appropriate settings
    this.initializeScanner()
  }
  
  initializeScanner() {
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
    
    this.scanner = new Html5QrcodeScanner(
      scannerTarget.id,
      config,
      false
    )

    try {
      console.log("Rendering adaptive scanner...")
      this.scanner.render(
        this.onScanSuccess.bind(this),
        this.onScanFailure.bind(this)
      )
      console.log("Adaptive scanner rendered successfully")
    } catch (error) {
      console.error("Error initializing adaptive scanner:", error)
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
    
    // Show navigation again for mobile scanner page
    if (this.scannerPageValue) {
      this.showNavigation()
    }
    
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
    
    // Clear result displays
    if (this.hasResultTarget) {
      this.resultTarget.textContent = ""
    }
    if (this.hasScanResultTarget) {
      this.scanResultTarget.classList.add("hidden")
    }
    
    if (this.scanner) {
      this.scanner.clear().catch(error => {
        console.error("Failed to clear scanner:", error)
      })
      this.scanner = null
    }
  }

  onScanSuccess(decodedText, decodedResult) {
    console.log(`Barcode detected (${this.currentOrientationValue} mode):`, decodedText)
    
    // Validate GTIN-13 format (13 digits)
    if (decodedText && /^\d{13}$/.test(decodedText)) {
      // Update result display
      const resultText = `✅ Scanned: ${decodedText}`
      if (this.hasResultTarget) {
        this.resultTarget.textContent = resultText
        this.resultTarget.classList.add("text-green-700")
        this.resultTarget.classList.remove("text-red-600")
      }
      
      // Haptic feedback on mobile if supported
      if (navigator.vibrate) {
        navigator.vibrate(200)
      }
      
      // Handle differently based on page type
      if (this.scannerPageValue) {
        this.handleScannerPageScan(decodedText)
      } else {
        // Original turbo stream approach
        this.fetchProductData(decodedText)
      }
    } else {
      console.log("Invalid GTIN-13 format:", decodedText)
      this.showError(`Invalid barcode format: ${decodedText}`)
    }
  }

  onScanFailure(error) {
    // Handle scan failure - this is called continuously during scanning
    // We don't need to log every failure as it's normal during scanning
  }

  async fetchProductData(gtin) {
    try {
      // First, get the product data
      const response = await fetch(`/${gtin}`, {
        method: 'GET',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'Content-Type': 'application/json'
        }
      })
      
      if (response.ok) {
        const turboStreamData = await response.text()
        // Let Turbo handle the stream response
        Turbo.renderStreamMessage(turboStreamData)
        
        // Track the scan after successful product fetch
        await this.trackScan(gtin)
      } else {
        this.showError('Failed to load product data')
      }
    } catch (error) {
      console.error('Error fetching product:', error)
      this.showError('Network error while loading product')
    }
  }

  async trackScan(gtin) {
    try {
      await fetch('/scans', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ gtin: gtin })
      })
    } catch (error) {
      console.error('Error tracking scan:', error)
      // Don't show error to user as this is background tracking
    }
  }
  
  // Action handlers for library management
  addToLibrary(event) {
    const libraryName = event.target.dataset.libraryName
    const productId = this.getProductIdFromDisplay()
    
    if (productId) {
      this.submitLibraryAction(productId, 'add_to_library', { library_name: libraryName })
    }
  }
  
  addToWishlist(event) {
    const productId = this.getProductIdFromDisplay()
    
    if (productId) {
      this.submitLibraryAction(productId, 'add_to_library', { library_name: 'Wishlist' })
    }
  }
  
  async submitLibraryAction(productId, action, params = {}) {
    try {
      const formData = new FormData()
      Object.entries(params).forEach(([key, value]) => {
        formData.append(key, value)
      })
      
      const response = await fetch(`/products/${productId}/${action}`, {
        method: 'POST',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: formData
      })
      
      if (response.ok) {
        const turboStreamData = await response.text()
        Turbo.renderStreamMessage(turboStreamData)
      } else {
        this.showError('Failed to update library')
      }
    } catch (error) {
      console.error('Error updating library:', error)
      this.showError('Network error')
    }
  }
  
  continueScan() {
    // Reset result display and continue scanning
    this.resultTarget.textContent = "Scanning... Point camera at barcode"
    this.resultTarget.classList.remove("text-red-600", "text-green-700")
    
    // Clear the product display back to default
    const productDisplay = document.getElementById('product-display')
    if (productDisplay) {
      productDisplay.innerHTML = this.getDefaultDisplayContent()
    }
  }
  
  showError(message) {
    this.resultTarget.textContent = `❌ ${message}`
    this.resultTarget.classList.add("text-red-600")
    this.resultTarget.classList.remove("text-green-700")
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
            <li>• Add to your library or wishlist</li>
          </ul>
        </div>
      </div>
    `
  }

  // Scanner page specific methods
  handleScannerPageScan(gtin) {
    // Just track the scan - same as existing scanner
    this.trackScan(gtin)
    
    // Continue scanning after a brief pause
    setTimeout(() => {
      if (this.scanningValue) {
        const resultText = "Scanning... Point camera at barcode"
        if (this.hasResultTarget) {
          this.resultTarget.textContent = resultText
          this.resultTarget.classList.remove("text-green-700", "text-red-600")
        }
      }
    }, 2000)
  }
  
  
  
  // Navigation hiding/showing for mobile
  hideNavigation() {
    const nav = document.querySelector('nav')
    if (nav) {
      this.originalNavDisplay = nav.style.display
      nav.style.display = 'none'
      
      // Also remove the main margin-top since nav is hidden
      const main = document.querySelector('main')
      if (main) {
        main.style.marginTop = '0'
      }
      
      // Remove top-16 class from scanner container and make it fill full screen
      const scannerContainer = this.element
      if (scannerContainer) {
        scannerContainer.classList.remove('top-16')
        scannerContainer.classList.add('top-0')
      }
    }
  }
  
  showNavigation() {
    const nav = document.querySelector('nav')
    if (nav) {
      nav.style.display = this.originalNavDisplay || ''
      
      // Restore main margin-top
      const main = document.querySelector('main')
      if (main) {
        main.style.marginTop = ''
      }
      
      // Restore top-16 class to scanner container
      const scannerContainer = this.element
      if (scannerContainer) {
        scannerContainer.classList.remove('top-0')
        scannerContainer.classList.add('top-16')
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