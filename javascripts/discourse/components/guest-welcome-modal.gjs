import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import ForgotPassword from "discourse/components/modal/forgot-password";
import { i18n } from "discourse-i18n";

export default class GuestWelcomeModal extends Component {
  @service router;
  @service modal;

  get title() {
    return settings.guest_popup_title;
  }

  get text() {
    return settings.guest_popup_text;
  }

  get migrationText() {
    return settings.guest_popup_migration_text;
  }

  get labels() {
    return {
      signup: i18n(themePrefix("guest_popup.signup")),
      login: i18n(themePrefix("guest_popup.login")),
      reset: i18n(themePrefix("guest_popup.reset_password")),
      later: i18n(themePrefix("guest_popup.later")),
    };
  }

  @action
  signup() {
    this.args.closeModal();
    this.router.transitionTo("signup");
  }

  @action
  login() {
    this.args.closeModal();
    this.router.transitionTo("login");
  }

  @action
  resetPassword() {
    this.args.closeModal();
    this.modal.show(ForgotPassword);
  }

  <template>
    <DModal
      @title={{this.title}}
      @closeModal={{@closeModal}}
      class="cs-guest-modal"
    >
      <:body>
        {{#if this.text}}
          <p class="cs-guest-modal__text">{{this.text}}</p>
        {{/if}}

        <DButton
          @action={{this.signup}}
          @icon="user-plus"
          @translatedLabel={{this.labels.signup}}
          class="btn-primary btn-large cs-guest-modal__signup"
        />

        {{#if this.migrationText}}
          <div class="cs-guest-modal__migration">
            <p>{{this.migrationText}}</p>
            <DButton
              @action={{this.resetPassword}}
              @icon="key"
              @translatedLabel={{this.labels.reset}}
              class="btn-default"
            />
          </div>
        {{/if}}
      </:body>

      <:footer>
        <DButton
          @action={{this.login}}
          @icon="right-to-bracket"
          @translatedLabel={{this.labels.login}}
          class="btn-default"
        />
        <DButton
          @action={{@closeModal}}
          @translatedLabel={{this.labels.later}}
          class="btn-flat cs-guest-modal__later"
        />
      </:footer>
    </DModal>
  </template>
}
