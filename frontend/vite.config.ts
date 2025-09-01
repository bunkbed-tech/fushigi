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
				target: import.meta.env.VITE_API_BASE,
				changeOrigin: true,
				secure: false,
			},
		},
	},
});
