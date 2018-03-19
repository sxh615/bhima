angular.module('bhima.components')
  .component('bhYesNoRadios', {
    bindings : {
      value : '<',
      label : '@',
      helpText : '@?',
      onChangeCallback : '&',
    },
    templateUrl : 'modules/templates/bhYesNoRadios.tmpl.html',
    controller : YesNoRadioController,
  });

/**
 * @function YesNoRadioController
 *
 * @description
 * This component makes yes/no options a bit easier to navigate.
 */
function YesNoRadioController() {
  const $ctrl = this;

  $ctrl.$onInit = () => {
    $ctrl.value = Number.parseInt($ctrl.value, 10);
    $ctrl.onChangeCallback = $ctrl.onChangeCallback || angular.noop;
  };

  $ctrl.onChange = (value) => {
    $ctrl.onChangeCallback({ value });
  };
}
