import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import sassDts from 'vite-plugin-sass-dts'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [sassDts(), react()],
  base: process.env.NODE_ENV === "production" ? "/frontend/" : "/",
  server: {
    proxy: {
      "/api": {
        target: "http://localhost:4000",
        secure: false,
        ws: true,
      },
    },
  },
});
