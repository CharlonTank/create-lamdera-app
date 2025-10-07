// elm-pkg-js-includes.js
// This file is used with lamdera-dev-watch.sh to include JavaScript modules

const localStorage = require('./elm-pkg-js/localStorage');
const googleOneTap = require('./elm-pkg-js/googleOneTap');

// Export the initialization function
exports.init = async function init(app) {
  localStorage.init(app);
  googleOneTap.init(app);
};
