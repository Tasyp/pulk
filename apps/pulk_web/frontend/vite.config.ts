import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import sassDts from "vite-plugin-sass-dts";
import postcssPresetEnv from "postcss-preset-env";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [sassDts(), react()],
  css: {
    postcss: {
      plugins: [postcssPresetEnv],
    },
  },
  base: process.env.NODE_ENV === "production" ? "/frontend/" : "/",
  server: {
    proxy: {
      "/api": {
        target: "http://127.0.0.1:4000",
        secure: false,
        ws: true,
      },
    },
  },
});
