import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "latitude", "longitude", "statusMsg" ]

  locate() {
    if (!navigator.geolocation) {
      this.statusMsgTarget.textContent = "Geolocalización no soportada en tu navegador.";
      return;
    }

    this.statusMsgTarget.textContent = "Ubicando...";

    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.latitudeTarget.value = position.coords.latitude;
        this.longitudeTarget.value = position.coords.longitude;
        this.statusMsgTarget.textContent = "¡Ubicación capturada con éxito!";
        this.statusMsgTarget.classList.add("text-success");
      },
      (error) => {
        this.statusMsgTarget.textContent = "Error al capturar ubicación: " + error.message;
        this.statusMsgTarget.classList.add("text-danger");
      }
    );
  }
}
