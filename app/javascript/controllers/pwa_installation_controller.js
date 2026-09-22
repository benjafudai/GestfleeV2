import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["installButton"]

  connect() {
    this.deferredPrompt = null;

    window.addEventListener('beforeinstallprompt', (e) => {
      // Prevent the mini-infobar from appearing on mobile
      e.preventDefault();
      // Stash the event so it can be triggered later.
      this.deferredPrompt = e;
      // Update UI notify the user they can install the PWA
      if (this.hasInstallButtonTarget) {
        this.installButtonTarget.classList.remove('hidden');
      }
    });

    window.addEventListener('appinstalled', (evt) => {
      // Log install to analytics
      console.log('INSTALL: Success');
    });
  }

  async install(e) {
    if (this.deferredPrompt) {
      // Show the install prompt
      this.deferredPrompt.prompt();
      // Wait for the user to respond to the prompt
      const { outcome } = await this.deferredPrompt.userChoice;
      console.log(`User response to the install prompt: ${outcome}`);
      // We've used the prompt, and can't use it again, throw it away
      this.deferredPrompt = null;
      if (this.hasInstallButtonTarget) {
        this.installButtonTarget.classList.add('hidden');
      }
    }
  }

  async subscribePush() {
    if ('serviceWorker' in navigator && 'PushManager' in window) {
      const registration = await navigator.serviceWorker.ready;
      
      // Ideally we should get the applicationServerKey from an API endpoint or meta tag.
      // This is a placeholder for the actual VAPID public key.
      const vapidPublicKey = document.querySelector('meta[name="vapid-public-key"]')?.content;
      
      if (!vapidPublicKey) {
         console.warn("No VAPID public key found. Cannot subscribe to push notifications.");
         return;
      }
      
      const convertedVapidKey = this.urlBase64ToUint8Array(vapidPublicKey);

      try {
        const subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: convertedVapidKey
        });

        // Send subscription to server
        await fetch('/push_subscriptions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify(subscription)
        });

        console.log('Push subscription successful');
      } catch (err) {
        console.error('Failed to subscribe the user: ', err);
      }
    }
  }

  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
      .replace(/\-/g, '+')
      .replace(/_/g, '/');

    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }
}
