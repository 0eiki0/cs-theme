import GuestWelcomeModal from "../components/guest-welcome-modal";

const STORAGE_KEY = "cs-theme-guest-popup-dismissed";
// Auf diesen Seiten stört das Popup nur
const EXCLUDED_ROUTES = /^(login|signup|password-reset|activate-account|invites|email-login|associate-account|account-created)/;

function dismissedRecently() {
  const days = Math.max(0, parseInt(settings.guest_popup_repeat_days, 10) || 0);
  if (days === 0) {
    return false;
  }
  try {
    const at = parseInt(localStorage.getItem(STORAGE_KEY), 10);
    return at > 0 && Date.now() - at < days * 24 * 60 * 60 * 1000;
  } catch {
    return false;
  }
}

function rememberDismissed() {
  try {
    localStorage.setItem(STORAGE_KEY, String(Date.now()));
  } catch {
    // z. B. privater Modus – dann eben beim nächsten Besuch wieder
  }
}

export default function setupGuestPopup(api) {
  if (api.getCurrentUser() || dismissedRecently()) {
    return;
  }

  const delay = Math.max(0, parseInt(settings.guest_popup_delay_seconds, 10) || 0);

  setTimeout(() => {
    const router = api.container.lookup("service:router");
    const modal = api.container.lookup("service:modal");
    const route = router.currentRouteName || "";

    // Nicht über ein anderes offenes Popup und nicht auf Login-Seiten
    if (EXCLUDED_ROUTES.test(route) || modal.activeModal || api.getCurrentUser()) {
      return;
    }

    rememberDismissed();
    modal.show(GuestWelcomeModal);
  }, delay * 1000);
}
