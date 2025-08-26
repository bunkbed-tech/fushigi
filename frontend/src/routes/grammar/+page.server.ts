import type { PageServerLoad } from "./$types";

export const load: PageServerLoad = async ({ fetch }) => {
	const res = await fetch(`${import.meta.env.VITE_API_BASE}/api/grammar`);
	if (!res.ok) {
		throw new Error(`Failed to fetch grammar points: ${res.status}`);
	}
	const grammarPoints = await res.json();
	return {
		grammarPoints,
	};
};
