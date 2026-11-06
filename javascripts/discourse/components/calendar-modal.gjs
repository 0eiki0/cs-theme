import Component from "@glimmer/component";
import DModal from "discourse/components/d-modal";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import calendarFeed from "../lib/calendar-feed";

// Der Kalender als großes Fenster direkt im Forum.
// Lädt die passende Kalender-Seite (Team: bearbeiten, Buddy: nur lesen).

export default class CalendarModal extends Component {
  get src() {
    return calendarFeed.pageUrl;
  }

  get title() {
    return settings.calendar_sidebar_text || i18n(themePrefix("calendar.title"));
  }

  get newTabLabel() {
    return i18n(themePrefix("calendar.open_new_tab"));
  }

  <template>
    <DModal
      @title={{this.title}}
      @closeModal={{@closeModal}}
      class="cs-cal-modal"
    >
      <:body>
        <iframe
          class="cs-cal-modal__frame"
          src={{this.src}}
          title={{this.title}}
        ></iframe>
      </:body>
      <:footer>
        <a
          class="cs-cal-modal__newtab"
          href={{this.src}}
          target="_blank"
          rel="noopener"
        >{{icon "up-right-from-square"}} {{this.newTabLabel}}</a>
      </:footer>
    </DModal>
  </template>
}
