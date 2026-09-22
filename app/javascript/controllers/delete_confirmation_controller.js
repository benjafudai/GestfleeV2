import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "button", "form", "companyNameDisplay"]

    connect() {
        this.buttonTarget.disabled = true
    }

    setDeleteTarget(event) {
        const { companyId, companyName } = event.params

        // Update modal content
        this.companyNameDisplayTarget.textContent = companyName
        this.formTarget.action = `/companies/${companyId}`

        // Reset input
        this.inputTarget.value = ""
        this.buttonTarget.disabled = true

        // Auto-focus input when modal opens (after a small delay for Bootstrap animation)
        setTimeout(() => {
            this.inputTarget.focus()
        }, 500)
    }

    checkInput() {
        const value = this.inputTarget.value.trim().toLowerCase()
        console.log("Input detectado:", value) // Debuglog (eliminar despues)
        if (value === "eliminar") {
            console.log("Palabra clave correcta. Habilitando botón.")
            this.buttonTarget.disabled = false
        } else {
            this.buttonTarget.disabled = true
        }
    }

    handleEnter(event) {
        if (event.key === "Enter") {
            event.preventDefault() // Prevent default form submit which might do nothing if button is disabled
            const value = this.inputTarget.value.trim().toLowerCase()

            if (value === "eliminar") {
                this.formTarget.requestSubmit()
            }
        }
    }
}
