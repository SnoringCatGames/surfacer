'use strict';

/** This module defines a singleton that drives the app. */
(function () {

  var main = {};

  main.grid = null;

  window.app = window.app || {};
  app.main = main;

  window.addEventListener('load', initApp, false);

  // ---  --- //

  /** Bootstraps the app. */
  function initApp() {
    console.log('onDocumentLoad');

    window.removeEventListener('load', initApp);
	
	// TODO
  }

  console.log('main module loaded');
})();
