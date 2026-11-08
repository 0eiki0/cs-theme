import Component from "@glimmer/component";
import DModal from "discourse/components/d-modal";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

// Externe Seite als großes Fenster im Forum (wie der Kalender).

export default class PageModal extends Component {
  get page() {
    return this.args.model?.page;
  }

  get newTabLabel() {
    return i18n(themePrefix("calendar.open_new_tab"));
  }

  <template>
    <DModal
      @title={{this.page.label}}
      @closeModal={{@closeModal}}
      class="cs-cal-modal cs-page-modal"
    >
      <:body>
        <iframe
          class="cs-cal-modal__frame"
          src={{this.page.url}}
          title={{this.page.label}}
          allow="clipboard-write; fullscreen"
        ></iframe>
      </:body>
      <:footer>
        <a
          class="cs-cal-modal__newtab"
          href={{this.page.url}}
          target="_blank"
          rel="noopener"
        >{{icon "up-right-from-square"}} {{this.newTabLabel}}</a>
      </:footer>
    </DModal>
  </template>
}
