angular.module('bhima.controllers')
.controller('ApplicationController', ApplicationController);

ApplicationController.$inject = [
  'AppCache', 'SessionService', 'LanguageService', '$state', '$rootScope', 'NotifyService'
];

/**
 * Application Controller
 *
 * This top-level controller is currently  responsible for initializing language
 * loading and controlling the side-bar hide/show methods.
 */
function ApplicationController(AppCache, Session, Languages, $state, $rootScope, Notify) {
  var vm = this;

  // load in the application cache
  var cache = AppCache('preferences');

  // expose notifications list to the application level view
  vm.notifications = Notify.list;

  // set up the languages for the application, including default languages
  // the 'true' parameter forces refresh
  Languages.read(true);

  vm.isLoggedIn = isLoggedIn;

  // check if the user has a valid session.
  function isLoggedIn() {
    return !!Session.user;
  }

  // Default sidebar state
  /** @todo Load sidebar state before angular is bootstrapped to remove 'flicker' */
  vm.sidebarExpanded = vm.isLoggedIn() ? (cache.sidebar && cache.sidebar.expanded) : false;

  vm.project = Session.project;

  /**
   * Application Structure methods
   */
  vm.toggleSidebar = function toggleSidebar() {
    if (!isLoggedIn()) { return; }
    vm.sidebarExpanded = !vm.sidebarExpanded;
    cache.sidebar = { expanded : vm.sidebarExpanded };
  };

  $rootScope.$on('login', function () {
    vm.sidebarExpanded = cache.sidebar && cache.sidebar.expanded;
    vm.project = Session.project;
  });

  $rootScope.$on('logout', function () {
    vm.sidebarExpanded = false;
    delete vm.project;
  });

  // go to the settings page
  vm.settings = function settings() {
    if (!isLoggedIn()) { return; }
    $state.go('settings', { previous : $state.$current.name });
  };

}
