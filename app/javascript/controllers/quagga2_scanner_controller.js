import { Controller } from "@hotwired/stimulus";
import { loadQuagga } from "quagga";

// Connects to data-controller="quagga2-scanner"
export default class extends Controller {
  static targets = ["startButton", "buttonText", "flashButton", "flashText", "scannerContainer", "scanner", "status", "manualInput", "barcodeReticle"];

  connect() {
    console.log("Quagga2 scanner controller connecting...");
    
    // Initialize state
    this.isScanning = false;
    this.flashOn = false;
    this.lastResult = null;
    this.lastResultTime = 0;
    this.stableCount = 0;
    this.stableThreshold = 2; // Require 2 consistent reads
    this.stabilityWindow = 300; // ms
    
    // Wait for Quagga2 to load from CDN
    this.waitForQuagga();
  }
  
  disconnect() {
    console.log("Quagga2 scanner controller disconnecting...");
    this.stopCamera();
  }
  
  async waitForQuagga() {
    if (typeof Quagga !== 'undefined') {
      console.log("Quagga2 already loaded");
      this.ready = true;
      return;
    }
    
    try {
      console.log("Loading Quagga2 via importmap...");
      const Quagga = await loadQuagga();
      console.log("Quagga2 loaded successfully via importmap");
      window.Quagga = Quagga; // Ensure it's available globally
      this.ready = true;
    } catch (error) {
      console.error("Failed to load Quagga2:", error);
      this.showStatus("Scanner library failed to load. Please check your connection and refresh.", "text-red-600");
    }
  }

  toggleCamera() {
    if (!this.ready) {
      this.showStatus("Scanner loading, please wait...", "text-yellow-600");
      return;
    }

    if (this.isScanning) {
      this.stopCamera();
    } else {
      this.startCamera();
    }
  }

  async startCamera() {
    try {
      this.showStatus("Starting camera and scanner...", "text-blue-600");
      
      // Update UI
      this.buttonTextTarget.textContent = "Stop";
      this.startButtonTarget.classList.remove("bg-booko", "hover:bg-booko-darker");
      this.startButtonTarget.classList.add("bg-red-600", "hover:bg-red-700");
      
      // Show scanner
      this.scannerContainerTarget.style.display = "block";
      if (this.hasStatusTarget) {
        this.statusTarget.style.display = "block";
      }
      
      this.isScanning = true;
      
      // Initialize Quagga2
      Quagga.init({
        inputStream: {
          name: "Live",
          type: "LiveStream",
          target: this.scannerTarget,
          constraints: {
            width: { min: 640 },
            height: { min: 480 },
            aspectRatio: { min: 1, max: 2 },
            facingMode: "environment" // Use back camera
          },
          area: { top: "12.5%", right: "7.8%", left: "7.8%", bottom: "12.5%" }, // Match reticle area
          singleChannel: false
        },
        locator: {
          patchSize: "large",
          halfSample: false
        },
        numOfWorkers: navigator.hardwareConcurrency > 2 ? 2 : 1,
        frequency: 10,
        decoder: {
          readers: [
            "ean_reader",      // GTIN-13 (13 digits) - Books, DVDs, LEGO, Pop Vinyls
            "upc_reader",      // UPC-A (12 digits) - North American products
          ],
          debug: {
            drawBoundingBox: true,
            showFrequency: true,
            drawScanline: true,
            showPattern: true
          }
        },
        locate: true
      }, (err) => {
        if (err) {
          console.error('Quagga2 initialization error:', err);
          this.showStatus(`Scanner failed to start: ${err.message}. Try using manual input below.`, "text-red-600");
          this.stopCamera();
          return;
        }
        
        console.log('Quagga2 initialized successfully');
        Quagga.start();
        this.showStatus('Scanner active! Point camera at a barcode...', "text-green-600");
        
        // Check for torch support after camera is initialized
        this.checkTorchSupport();
        
        // Set up detection handler
        this.setupDetectionHandler();
      });
      
    } catch (err) {
      console.error('Camera error:', err);
      this.showStatus(`Camera access failed: ${err.message}. Try manual input below.`, "text-red-600");
      this.stopCamera();
    }
  }

  stopCamera() {
    if (typeof Quagga !== 'undefined' && this.isScanning) {
      try {
        Quagga.offDetected();
        Quagga.stop();
      } catch(e) {
        console.warn("Quagga2 stop error:", e);
      }
    }
    
    // Reset UI
    this.buttonTextTarget.textContent = "Scan";
    this.startButtonTarget.classList.remove("bg-red-600", "hover:bg-red-700");
    this.startButtonTarget.classList.add("bg-booko", "hover:bg-booko-darker");
    
    // Hide scanner
    this.scannerContainerTarget.style.display = "none";
    if (this.hasStatusTarget) {
      this.statusTarget.style.display = "none";
    }
    this.flashButtonTarget.style.display = "none";
    
    // Reset flash
    this.flashOn = false;
    this.flashTextTarget.textContent = "💡 Torch Off";
    
    this.isScanning = false;
    
    // Reset detection state
    this.lastResult = null;
    this.stableCount = 0;
  }

  setupDetectionHandler() {
    Quagga.onDetected((result) => {
      console.log("Quagga2 detection:", result);
      const code = result.codeResult.code;
      const currentTime = Date.now();

      // Stability checking
      if (code === this.lastResult && (currentTime - this.lastResultTime) < this.stabilityWindow) {
        this.stableCount++;
      } else {
        this.stableCount = 1;
      }

      this.lastResult = code;
      this.lastResultTime = currentTime;

      if (this.stableCount >= this.stableThreshold) {
        if (this.isValidBookBarcode(code)) {
          console.log(`Confirmed barcode: ${code}`);
          this.showStatus(`Found: ${code} - Searching...`, "text-green-600");
          
          // Trigger green blink animation
          this.blinkReticleSuccess();
          
          // Stop scanning and navigate after brief delay to show animation
          setTimeout(() => {
            this.stopCamera();
            this.searchBarcode(code);
          }, 300);
          
          // Reset for next scan
          this.lastResult = null;
          this.stableCount = 0;
        }
      } else {
        this.showStatus(`Detected: ${code} (${this.stableCount}/${this.stableThreshold} confirmations)`, "text-blue-600");
      }
    });
  }

  async checkTorchSupport() {
    try {
      // Try to get the video element from the scanner
      const videoElement = this.scannerTarget.querySelector('video');
      if (videoElement && videoElement.srcObject) {
        const stream = videoElement.srcObject;
        const videoTrack = stream.getVideoTracks()[0];
        const capabilities = videoTrack.getCapabilities();
        
        console.log('Camera capabilities:', capabilities);
        
        if (capabilities && capabilities.torch) {
          console.log('Torch supported!');
          this.flashButtonTarget.style.display = 'inline-flex';
        } else {
          console.log('Torch not supported');
          this.flashButtonTarget.style.display = 'none';
        }
      } else {
        console.log('No video stream found for torch check');
        this.flashButtonTarget.style.display = 'none';
      }
    } catch (err) {
      console.warn('Could not check torch support:', err);
      this.flashButtonTarget.style.display = 'none';
    }
  }

  async toggleFlash() {
    try {
      this.flashOn = !this.flashOn;
      
      // Update button text
      this.flashTextTarget.textContent = this.flashOn ? '💡 Flash On' : '💡 Flash Off';
      
      // Apply torch constraint to the video track
      const videoElement = this.scannerTarget.querySelector('video');
      if (videoElement && videoElement.srcObject) {
        const stream = videoElement.srcObject;
        const videoTrack = stream.getVideoTracks()[0];
        const capabilities = videoTrack.getCapabilities();
        
        if (capabilities && capabilities.torch) {
          await videoTrack.applyConstraints({
            advanced: [{ torch: this.flashOn }]
          });
          console.log(`Flash ${this.flashOn ? 'enabled' : 'disabled'}`);
        } else {
          console.warn('Torch not supported on this device');
          this.showStatus('Flash not supported on this device', "text-yellow-600");
        }
      } else {
        console.warn('No video stream available for flash toggle');
        this.showStatus('Flash not available', "text-yellow-600");
      }
    } catch (err) {
      console.error('Flash toggle error:', err);
      this.showStatus('Failed to toggle flash', "text-red-600");
    }
  }

  searchManual() {
    const barcode = this.manualInputTarget.value.trim();
    if (barcode) {
      if (this.isValidBookBarcode(barcode)) {
        this.searchBarcode(barcode);
        this.manualInputTarget.value = "";
      } else {
        this.showStatus("Please enter a valid barcode (8, 10, 12, or 13 digits)", "text-red-600");
      }
    } else {
      this.showStatus("Please enter a barcode", "text-yellow-600");
    }
  }

  handleEnterKey(event) {
    if (event.key === 'Enter') {
      this.searchManual();
    }
  }

  isValidBookBarcode(code) {
    // Remove any non-digit characters
    const cleanCode = code.replace(/\D/g, '');
    
    // Check for valid book barcode formats
    const isISBN13 = cleanCode.length === 13 && (cleanCode.startsWith('978') || cleanCode.startsWith('979'));
    const isISBN10 = cleanCode.length === 10;
    const isUPC = cleanCode.length === 12;
    const isEAN8 = cleanCode.length === 8;
    
    return isISBN13 || isISBN10 || isUPC || isEAN8;
  }

  searchBarcode(barcode) {
    console.log(`Searching for barcode: ${barcode}`);
    this.showStatus(`Searching for ${barcode}...`, "text-blue-600");
    
    // Navigate to the product page using Turbo
    if (typeof Turbo !== 'undefined') {
      Turbo.visit(`/${barcode}`, { action: "replace" });
    } else {
      // Fallback to regular navigation
      window.location.href = `/${barcode}`;
    }
  }

  blinkReticleSuccess() {
    if (this.hasBarcodeReticleTarget) {
      // Add success animation class
      this.barcodeReticleTarget.classList.add('reticle-success');
      
      // Remove the class after animation completes
      setTimeout(() => {
        this.barcodeReticleTarget.classList.remove('reticle-success');
      }, 600); // Match animation duration
    }
  }

  showStatus(message, colorClass = "text-gray-600") {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message;
      this.statusTarget.className = `text-center text-sm mb-4 ${colorClass}`;
      this.statusTarget.style.display = "block";
    } else {
      console.log(`Scanner status: ${message}`);
    }
  }
}