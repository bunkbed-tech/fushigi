import { sveltekit } from "@sveltejs/kit/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

export default defineConfig({
	plugins: [sveltekit(), tailwindcss()],
	server: {
		host: true, // makes the dev server accessible on LAN IP
		port: 5173,
		proxy: {
			"/api": {
				target: process.env.VITE_API_BASE || "http://localhost:8090",
				changeOrigin: true,
				secure: false,
			},
		},
	},
});
