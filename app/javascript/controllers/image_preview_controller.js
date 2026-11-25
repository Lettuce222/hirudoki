import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "original"]

  update(event) {
    this.releaseObjectURL()
    const file = event.target.files[0]
    const supported = file && event.target.accept.split(",").includes(file.type)
    this.previewTarget.hidden = !supported
    if (this.hasOriginalTarget) this.originalTarget.hidden = !!supported
    if (supported) {
      this.objectURL = URL.createObjectURL(file)
      this.previewTarget.src = this.objectURL
    } else {
      this.previewTarget.removeAttribute("src")
    }
  }

  disconnect() {
    this.releaseObjectURL()
  }

  releaseObjectURL() {
    if (this.objectURL) URL.revokeObjectURL(this.objectURL)
    this.objectURL = null
  }
}
