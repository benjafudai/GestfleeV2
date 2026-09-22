import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  clearStorage(event) {
    // Clear localStorage
    localStorage.clear();
    
    // Delete IndexedDB for offline forms
    const req = indexedDB.deleteDatabase("PwaOfflineStore");
    req.onsuccess = () => {
      console.log("IndexedDB PwaOfflineStore deleted successfully");
    };
    req.onerror = () => {
      console.error("Couldn't delete database");
    };
  }
}
