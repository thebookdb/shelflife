import { Controller } from "@hotwired/stimulus"
import { Html5QrcodeScanner, Html5QrcodeSupportedFormats } from "html5-qrcode"

export default class extends Controller {
  static targets = ["scanner", "result", "placeholder", "startButton", "stopButton", "librarySelect", "scanResult", "libraryStatus"]
  static values = { 
    scanning: { type: Boolean, default: false },
    scannerPage: { type: Boolean, default: false }
  }

  connect() {
    console.log("Horizontal barcode scanner controller connected", { scannerPage: this.scannerPageValue })
    
    // Initialize mobile-specific features for scanner page
    if (this.scannerPageValue) {
      this.initializeMobileFeatures()
    }
    
    // Load saved library preference
    this.loadLibraryPreference()
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

  startScanning() {
    if (this.scanningValue) return

    console.log("Starting horizontal scanning...")
    this.scanningValue = true
    
    // Hide navigation for mobile scanner page
    if (this.scannerPageValue) {
      this.hideNavigation()
    }
    
    // Update UI state
    this.startButtonTarget.classList.add("hidden")
    this.stopButtonTarget.classList.remove("hidden")
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.add("hidden")
    }
    
    // Update result display
    if (this.hasResultTarget) {
      this.resultTarget.textContent = "Scanning... Point camera at barcode"
    }
    if (this.hasScanResultTarget) {
      this.scanResultTarget.classList.remove("hidden")
    }
    
    // Initialize html5-qrcode scanner with horizontal-optimized settings
    console.log("Initializing horizontal scanner on element:", this.scannerTarget.id, this.scannerTarget)
    
    this.scanner = new Html5QrcodeScanner(
      this.scannerTarget.id,
      {
        fps: 10,
        // Wider qrbox for horizontal scanning - better for landscape orientation
        qrbox: { width: 400, height: 200 },
        formatsToSupport: [Html5QrcodeSupportedFormats.EAN_13],
        showTorchButtonIfSupported: true,
        showZoomSliderIfSupported: true,
        defaultZoomValueIfSupported: 2,
        useBarCodeDetectorIfSupported: true,
        verbose: true,
        // Horizontal aspect ratio
        aspectRatio: 2.0,
        disableFlip: false,
        // Additional settings for horizontal scanning
        rememberLastUsedCamera: true
      },
      false
    )

    try {
      console.log("Rendering horizontal scanner...")
      this.scanner.render(
        this.onScanSuccess.bind(this),
        this.onScanFailure.bind(this)
      )
      console.log("Horizontal scanner rendered successfully")
    } catch (error) {
      console.error("Error initializing horizontal scanner:", error)
      this.showError("Camera access failed. Please check permissions.")
    }
  }

  stopScanning() {
    if (!this.scanningValue) return

    console.log("Stopping horizontal scanner...")
    this.scanningValue = false
    
    // Show navigation again for mobile scanner page
    if (this.scannerPageValue) {
      this.showNavigation()
    }
    
    // Update UI state
    this.startButtonTarget.classList.remove("hidden")
    this.stopButtonTarget.classList.add("hidden")
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.remove("hidden")
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
        console.error("Failed to clear horizontal scanner:", error)
      })
      this.scanner = null
    }
  }

  onScanSuccess(decodedText, decodedResult) {
    console.log("Barcode detected (horizontal):", decodedText)
    
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
  
  showError(message) {
    if (this.hasResultTarget) {
      this.resultTarget.textContent = `❌ ${message}`
      this.resultTarget.classList.add("text-red-600")
      this.resultTarget.classList.remove("text-green-700")
    }
  }
  
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
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
  }
}