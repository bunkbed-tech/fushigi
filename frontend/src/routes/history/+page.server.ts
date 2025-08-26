import type { PageServerLoad } from "./$types";

export const load: PageServerLoad = async ({ fetch }) => {
	try {
		const res = await fetch(`${import.meta.env.VITE_API_BASE}/api/journal`);
		if (!res.ok) {
			throw new Error(`Failed to fetch journal entries: ${res.status}`);
		}
		const entries = await res.json();
		return { entries };
	} catch (error) {
		return {
			entries: [],
			error: error instanceof Error ? error.message : String(error),
		};
	}
};
