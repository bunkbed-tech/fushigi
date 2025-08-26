import { sveltekit } from "@sveltejs/kit/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

export default defineConfig({
	plugins: [sveltekit(), tailwindcss()],
	server: {
		host: true, // makes the dev server accessible on LAN IP, not just localhost
		port: 5173,
		proxy: {
			"/api": {
				target: import.meta.env.VITE_API_BASE,
				changeOrigin: true, // rewrite the Host header of proxied requests to match the target
				secure: false, // allow proxying to servers with self-signed TLS certificates
			},
		},
	},
});
