import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { openPage } from "../lib/embedded-pages";

// Button rechts oben in der Kopfzeile (neben Suche und Avatar).

export default class HeaderPageButton extends Component {
  get page() {
    return this.args.page;
  }

  @action
  open() {
    openPage(this.page);
  }

  <template>
    <li class="cs-header-page header-dropdown-toggle">
      <DButton
        @action={{this.open}}
        @icon={{this.page.icon}}
        @translatedTitle={{this.page.label}}
        @translatedAriaLabel={{this.page.label}}
        class="icon btn-flat"
      />
    </li>
  </template>
}
