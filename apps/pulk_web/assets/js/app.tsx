// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "../css/app.css"

import "phoenix_html"
import React from "react";
import { createRoot } from 'react-dom/client';

import App from ".";

import { setup } from "goober";

setup(React.createElement);

const container = document.getElementById("app");
const root = createRoot(container!);
root.render(<App />);
