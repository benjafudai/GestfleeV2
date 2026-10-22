import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

// "Instalar app" button. Chrome/Edge/Android fire beforeinstallprompt (caught
// early in the layout head into window.gfInstallPrompt); iPhone/iPad Safari has
// no install API, so there the button opens instructions instead.
export default class extends Controller {
  static targets = ["button", "iosHelp"]

  connect() {
    this.refresh = this.refresh.bind(this)
    window.addEventListener("gf:installable", this.refresh)
    window.addEventListener("appinstalled", this.refresh)
    this.refresh()
  }

  disconnect() {
    window.removeEventListener("gf:installable", this.refresh)
    window.removeEventListener("appinstalled", this.refresh)
  }

  refresh() {
    const show = !this.installed && (window.gfInstallPrompt || this.ios)
    this.buttonTargets.forEach((button) => { button.hidden = !show })
  }

  async install() {
    const prompt = window.gfInstallPrompt
    if (prompt) {
      window.gfInstallPrompt = null
      prompt.prompt()
      await prompt.userChoice
      this.refresh()
    } else if (this.ios && this.hasIosHelpTarget) {
      // Move the modal to <body> so a positioned parent (landing header)
      // can't stack it under the backdrop.
      const help = this.iosHelpTarget
      document.body.appendChild(help)
      help.addEventListener("hidden.bs.modal", () => this.element.appendChild(help), { once: true })
      Modal.getOrCreateInstance(help).show()
    }
  }

  get installed() {
    return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
  }

  get ios() {
    const ua = window.navigator.userAgent
    return /iPhone|iPad|iPod/.test(ua) || (ua.includes("Macintosh") && navigator.maxTouchPoints > 1)
  }
}
