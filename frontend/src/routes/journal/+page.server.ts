import type { Actions } from "./$types";

export const actions: Actions = {
	default: async ({ request, fetch }) => {
		const formData = await request.formData();
		const title = formData.get("title") as string;
		const content = formData.get("content") as string;
		const isPrivate = formData.get("private") === "on";

		if (!title?.trim() || !content?.trim()) {
			return { success: false, message: "Please fill out all fields." };
		}

		try {
			const res = await fetch(`${import.meta.env.VITE_API_BASE}/api/journal`, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({ title, content, private: isPrivate }),
			});

			if (!res.ok) throw new Error("Failed to save journal entry");

			const id = await res.json();
			return { success: true, message: `Journal saved (ID: ${id.id})` };
		} catch (e) {
			return {
				success: false,
				message: e instanceof Error ? e.message : String(e),
			};
		}
	},
};
