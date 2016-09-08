/**
 * @description
 * This service is responsible for compiling valid HTML documents given a path to a handlebars template
 *
 * @requires express-handlebars
 * @requires server/lib/template
 */
'use strict';

const exhbs = require('express-handlebars');

const hbs = require('../template');
const translateHelperFactory = require('../helpers/translate');

exports.render = renderHTML;

/**
 *
 * @param {Object} data     Object of keys and values that will be made available to the template
 * @param {String} template Path to a handlebars template
 * @param {Object} options  The default options, including language setting
 * @returns {Promise}       Promise resolving in a rendered template (HTML)
 */
function renderHTML(data, template, options) {

  options = options || {};

  // make sure that we have the appropriate language set.  If options.lang is
  // not specified, will default to English.  To change this behavior, see the
  // factory code.
  const translate = translateHelperFactory(options.lang);
  hbs.helpers.translate = translate;

  return hbs.render(template, data);
}