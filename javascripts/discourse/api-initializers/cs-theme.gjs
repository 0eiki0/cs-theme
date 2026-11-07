import { apiInitializer } from "discourse/lib/api";
import ServerBanner from "../components/server-banner";
import OnlineUsers from "../components/online-users";
import TeamOnline from "../components/team-online";
import startTeamHeartbeat from "../lib/team-heartbeat";
import setupGuestPopup from "../lib/guest-popup";
import createUnreadSectionLink from "../lib/unread-section-link";
import unreadCounter from "../lib/unread-counter";
import CalendarBanner from "../components/calendar-banner";
import UpcomingEvents from "../components/upcoming-events";
import CalendarModal from "../components/calendar-modal";
import createCalendarSectionLink from "../lib/calendar-section-link";
import calendarFeed, { normalizeCalendarUrl } from "../lib/calendar-feed";
import { watchScheme, withScheme } from "../lib/calendar-scheme";

// calendar_groups: leer = alle Angemeldeten. Einträge können Gruppennamen
// oder IDs sein (je nach Discourse-Version speichert die Auswahl das eine
// oder das andere).
function inCalendarGroups(user) {
  const wanted = String(settings.calendar_groups || "")
    .split("|")
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean);
  if (wanted.length === 0) {
    return true;
  }
  return (user.groups || []).some(
    (group) =>
      wanted.includes(String(group.id)) ||
      wanted.includes(String(group.name || "").toLowerCase())
  );
}

function setupCalendar(api) {
  const calendarUrl = normalizeCalendarUrl(settings.calendar_url);
  if (!calendarUrl) {
    return;
  }
  const origin = new URL(calendarUrl).origin;

  // In Beiträgen eingebettete Kalender erkennen (Breite per CSS) …
  api.decorateCookedElement(
    (element) => {
      element.querySelectorAll("iframe").forEach((iframe) => {
        const src = iframe.getAttribute("src") || "";
        if (src.startsWith(`${origin}/`)) {
          iframe.classList.add("cs-cal-frame");
          // Hell/Dunkel wie das Forum
          if (!/[?&]scheme=/.test(src)) {
            iframe.setAttribute("src", withScheme(src));
          }
        }
      });
    },
    { id: "cs-calendar-frames" }
  );

  // Wechsel zwischen hell und dunkel an offene Kalender weitergeben
  watchScheme(origin);

  // Höhe eingebetteter Kalender an den Inhalt anpassen (meldet der Kalender selbst).
  window.addEventListener("message", (event) => {
    const data = event.data;
    if (
      event.origin !== origin ||
      !data ||
      data.type !== "cscal:height" ||
      typeof data.height !== "number"
    ) {
      return;
    }
    const height = Math.min(Math.max(data.height, 150), 5000);
    document.querySelectorAll("iframe.cs-cal-frame").forEach((iframe) => {
      if (iframe.contentWindow === event.source) {
        iframe.style.height = `${height}px`;
      }
    });
  });

  // Banner und Box "Nächste Termine" nur für angemeldete Nutzer
  const user = api.getCurrentUser();
  const wantsFeed =
    settings.show_calendar_banner ||
    settings.show_upcoming_events ||
    settings.show_calendar_sidebar_link;
  if (!user || !wantsFeed || !inCalendarGroups(user)) {
    return;
  }

  calendarFeed.start(calendarUrl, user.username);

  // Kalender als großes Fenster im Forum öffnen
  const modal = api.container.lookup("service:modal");
  calendarFeed.openHandler = () => {
    if (modal.activeModal?.component !== CalendarModal) {
      modal.show(CalendarModal);
    }
  };

  // Direktlink: https://…/forum/#kalender öffnet den Kalender
  const openFromHash = () => {
    if (window.location.hash === "#kalender") {
      history.replaceState(
        history.state,
        "",
        window.location.pathname + window.location.search
      );
      calendarFeed.open();
    }
  };
  window.addEventListener("hashchange", openFromHash);
  openFromHash();

  if (settings.show_calendar_sidebar_link) {
    api.addCommunitySectionLink(createCalendarSectionLink);

    // Klick auf den Seitenleisten-Punkt abfangen, bevor Discourse navigiert
    document.addEventListener(
      "click",
      (event) => {
        const link = event.target.closest?.(
          '[data-list-item-name="cs-calendar"] a'
        );
        if (!link || event.button !== 0 || event.ctrlKey || event.metaKey) {
          return;
        }
        event.preventDefault();
        event.stopPropagation();
        calendarFeed.open();
      },
      true
    );
  }

  if (settings.show_calendar_banner) {
    // Ganz oben, damit der Hinweis auf jeder Seite auffällt
    api.renderInOutlet("above-main-container", CalendarBanner);
  }
  if (settings.show_upcoming_events) {
    // Wie "Team Online": vor der Themenliste, per CSS als rechte Spalte
    api.renderInOutlet("before-list-area", UpcomingEvents);
  }
}

export default apiInitializer((api) => {
  if (settings.show_guest_popup) {
    setupGuestPopup(api);
  }

  if (settings.sidebar_unread_link) {
    api.addCommunitySectionLink(createUnreadSectionLink);

    // Zähler im Modus "alle" sofort starten und live halten
    if (api.getCurrentUser() && settings.sidebar_unread_mode !== "verfolgt") {
      unreadCounter.start({
        messageBus: api.container.lookup("service:message-bus"),
        topicTrackingState: api.container.lookup("service:topic-tracking-state"),
        router: api.container.lookup("service:router"),
      });
    }
  }

  // In der Liste "Ungesehen" ist jedes Thema ungelesen. Discourse liefert für
  // nicht verfolgte Themen aber keine Anzahl ungelesener Beiträge mit – per
  // Body-Klasse werden dort deshalb alle Themen hervorgehoben.
  const router = api.container.lookup("service:router");
  router.on("routeDidChange", () => {
    const route = router.currentRouteName || "";
    document.body.classList.toggle(
      "cs-route-unseen",
      route.startsWith("discovery.unseen")
    );
  });

  setupCalendar(api);

  if (settings.show_online_users) {
    // In der Seitenleiste unter den Kategorien
    api.renderInOutlet("after-sidebar-sections", OnlineUsers);
  }

  if (settings.show_banner) {
    api.renderInOutlet("above-main-container", ServerBanner);
  }

  if (settings.show_team_online) {
    // Steht im Discourse-Layout direkt vor der Themenliste und wird per CSS
    // als Spalte rechts daneben angeordnet.
    api.renderInOutlet("before-list-area", TeamOnline);

    if (settings.team_online_keep_alive) {
      startTeamHeartbeat(api.getCurrentUser());
    }
  }
});
