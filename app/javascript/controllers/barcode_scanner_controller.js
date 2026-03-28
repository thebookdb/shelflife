import { Controller } from "@hotwired/stimulus"
import { Html5Qrcode, Html5QrcodeSupportedFormats } from "html5-qrcode"

export default class extends Controller {
  static targets = ["scanner", "placeholder", "startButton", "stopButton", "librarySelect", "scanOverlay", "libraryStatus", "cameraTab", "cameraDrawer", "cameraList", "cameraLabel", "recentItem"]
  static values = {
    scanning: { type: Boolean, default: false },
    currentOrientation: { type: String, default: "portrait" }
  }

  connect() {
    this.cameras = []
    this.activeCameraId = null
    this.drawerOpen = false
    this.boundOnOrientationChange = this.onOrientationChange.bind(this)
    this.boundOnLibraryChange = this.onLibraryChange.bind(this)
    this.highlightTimer = null
    this.loadLibraryPreference()
    this.setupOrientationDetection()
  }

  recentItemTargetConnected(element) {
    // Strip all highlight from previous items
    this.recentItemTargets.forEach(el => {
      if (el !== element) {
        el.classList.remove('ring-2', 'ring-green-400', 'bg-green-100')
      }
    })

    // Fade the neon ring after 2 seconds, keep the pale green background
    clearTimeout(this.highlightTimer)
    this.highlightTimer = setTimeout(() => {
      element.classList.remove('ring-2', 'ring-green-400')
    }, 2000)
  }

  loadLibraryPreference() {
    if (this.hasLibrarySelectTarget) {
      this.librarySelectTarget.addEventListener('change', this.boundOnLibraryChange)
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
      screen.orientation.addEventListener('change', this.boundOnOrientationChange)
    }
    window.addEventListener('resize', this.boundOnOrientationChange)
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

  async stopScannerInstance() {
    if (!this.scanner) return
    try {
      await this.scanner.stop()
      this.scanner.clear()
    } catch (error) {
      console.error("Error stopping scanner:", error)
    }
    this.scanner = null
  }

  async restartScannerForOrientation() {
    await this.stopScannerInstance()
    this.scannerTarget.classList.add("hidden")
    setTimeout(() => { this.initializeScanner() }, 500)
  }

  async startScanning() {
    if (this.scanningValue) return

    this.scanningValue = true
    this.hideNavigation()

    this.startButtonTarget.classList.add("hidden")
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden")
    if (this.hasScanOverlayTarget) this.scanOverlayTarget.classList.remove("hidden")

    await this.initializeScanner()

    // Enumerate cameras after scanner is running — permission is already granted
    // so enumerateDevices() returns labels without triggering a new getUserMedia
    if (this.cameras.length === 0) {
      this.enumerateCameras()
    }
  }

  async initializeScanner() {
    this.scannerTarget.classList.remove("hidden")

    const config = this.getScannerConfig()
    this.scanner = new Html5Qrcode(this.scannerTarget.id)

    // Use saved camera if available, otherwise default to environment-facing
    const cameraConfig = this.activeCameraId
      ? this.activeCameraId
      : { facingMode: "environment" }

    try {
      await this.scanner.start(
        cameraConfig,
        config,
        this.onScanSuccess.bind(this),
        this.onScanFailure.bind(this)
      )
    } catch (error) {
      console.error("Error starting scanner:", error)
    }
  }

  async enumerateCameras() {
    try {
      // Use browser API directly — avoids Html5Qrcode.getCameras() which
      // calls getUserMedia internally and can hijack the active stream on iOS
      const devices = await navigator.mediaDevices.enumerateDevices()
      this.cameras = devices
        .filter(d => d.kind === 'videoinput')
        .map(d => ({ id: d.deviceId, label: d.label }))

      this.updateCameraLabel()
      if (this.cameras.length > 1) {
        this.renderCameraList()
      } else {
        if (this.hasCameraTabTarget) this.cameraTabTarget.style.display = 'none'
      }
    } catch (error) {
      console.error("Error enumerating cameras:", error)
    }
  }

  updateCameraLabel() {
    if (!this.hasCameraLabelTarget) return

    let label = 'Camera'

    if (this.activeCameraId) {
      const active = this.cameras.find(c => c.id === this.activeCameraId)
      if (active) label = active.label || label
    } else {
      // No explicit camera ID — detect from the active video track
      const video = this.scannerTarget.querySelector('video')
      if (video?.srcObject) {
        const track = video.srcObject.getVideoTracks()[0]
        if (track) {
          const settings = track.getSettings()
          const match = this.cameras.find(c => c.id === settings.deviceId)
          if (match) label = match.label || label
        }
      }
    }

    this.cameraLabelTarget.querySelector('span').textContent = this.shortenCameraLabel(label)
  }

  renderCameraList() {
    if (!this.hasCameraListTarget) return

    this.cameraListTarget.innerHTML = ''
    this.cameras.forEach((camera, index) => {
      const btn = document.createElement('button')
      btn.type = 'button'
      btn.dataset.cameraId = camera.id
      btn.className = `w-full text-left px-2.5 py-2 rounded-lg text-sm transition-colors ${
        camera.id === this.activeCameraId
          ? 'bg-green-100 text-green-800 font-medium'
          : 'text-gray-700 hover:bg-gray-100'
      }`
      btn.textContent = this.shortenCameraLabel(camera.label || `Camera ${index + 1}`)
      this.cameraListTarget.appendChild(btn)
    })

    // Single delegated listener on the container
    if (!this.cameraListTarget.dataset.delegated) {
      this.cameraListTarget.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-camera-id]')
        if (btn) this.switchCamera(btn.dataset.cameraId)
      })
      this.cameraListTarget.dataset.delegated = 'true'
    }
  }

  shortenCameraLabel(label) {
    // Strip common verbose prefixes from camera labels
    return label
      .replace(/\s*\(.*?\)\s*$/, '')
      .replace(/^camera2\s+\d+,\s*/i, '')
      .trim() || label
  }

  async switchCamera(cameraId) {
    if (cameraId === this.activeCameraId) {
      this.toggleCameraDrawer()
      return
    }

    this.activeCameraId = cameraId
    this.updateCameraLabel()
    this.renderCameraList()
    this.toggleCameraDrawer()

    await this.stopScannerInstance()
    this.scannerTarget.classList.add("hidden")
    setTimeout(() => { this.initializeScanner() }, 300)
  }

  toggleCameraDrawer() {
    if (!this.hasCameraDrawerTarget) return

    this.drawerOpen = !this.drawerOpen
    if (this.drawerOpen) {
      this.cameraDrawerTarget.classList.remove('-translate-x-full')
      this.cameraDrawerTarget.classList.add('translate-x-0')
      if (this.hasCameraTabTarget) this.cameraTabTarget.style.opacity = '0'
    } else {
      this.cameraDrawerTarget.classList.remove('translate-x-0')
      this.cameraDrawerTarget.classList.add('-translate-x-full')
      if (this.hasCameraTabTarget) this.cameraTabTarget.style.opacity = ''
    }
  }

  stopScanning() {
    if (!this.scanningValue) return

    this.scanningValue = false
    this.showNavigation()

    // Close camera drawer if open
    if (this.drawerOpen) this.toggleCameraDrawer()

    this.startButtonTarget.classList.remove("hidden")
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.remove("hidden")
    if (this.hasScanOverlayTarget) this.scanOverlayTarget.classList.add("hidden")

    this.scannerTarget.classList.add("hidden")
    this.stopScannerInstance()
  }

  onScanSuccess(decodedText, decodedResult) {
    if (decodedText && /^\d{13}$/.test(decodedText)) {
      // Cooldown — ignore repeat scans for 2 seconds
      const now = Date.now()
      if (this.lastScanText === decodedText && now - this.lastScanTime < 2000) return
      this.lastScanText = decodedText
      this.lastScanTime = now

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
    this.cameras = []
    this.activeCameraId = null

    if (this.hasLibrarySelectTarget) {
      this.librarySelectTarget.removeEventListener('change', this.boundOnLibraryChange)
    }
    if (screen.orientation) {
      screen.orientation.removeEventListener('change', this.boundOnOrientationChange)
    }
    window.removeEventListener('resize', this.boundOnOrientationChange)
    clearTimeout(this.orientationTimeout)
  }
}
