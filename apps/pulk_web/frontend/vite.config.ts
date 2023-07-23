import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
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
