<script lang="ts">
  let title = "";
  let content = "";
  let isPrivate = false;
  let message = "";
  let isSubmitting = false;

  async function handleSubmit() {
    if (!title.trim() || !content.trim()) {
      message = "Please fill out all fields.";
      return;
    }

    isSubmitting = true;
    message = "";

    try {
      const res = await fetch(`${import.meta.env.VITE_API_BASE}/api/journal`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: title.trim(),
          content: content.trim(),
          private: isPrivate
        }),
      });

      if (!res.ok) throw new Error("Failed to save journal entry");

      const result = await res.json();
      message = `Journal saved (ID: ${result.id})`;

      // Reset form
      title = "";
      content = "";
      isPrivate = false;
    } catch (e) {
      message = e instanceof Error ? e.message : String(e);
    } finally {
      isSubmitting = false;
    }
  }
</script>

<form on:submit|preventDefault={handleSubmit} class="space-y-4">
  <div>
    <label class="block text-sm font-medium" for="title">Title</label>
    <input
      id="title"
      bind:value={title}
      type="text"
      class="w-full border rounded p-2"
      required
      disabled={isSubmitting}
    />
  </div>

  <div>
    <label class="block text-sm font-medium" for="content">Content</label>
    <textarea
      id="content"
      bind:value={content}
      class="w-full border rounded p-2 h-32"
      required
      disabled={isSubmitting}
    ></textarea>
  </div>

  <div>
    <input
      type="checkbox"
      id="private"
      bind:checked={isPrivate}
      disabled={isSubmitting}
    />
    <label for="private">Private</label>
  </div>

  <button
    type="submit"
    class="px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50"
    disabled={isSubmitting}
  >
    {isSubmitting ? "Saving..." : "Save"}
  </button>
</form>

{#if message}
  <p class="mt-4" class:text-green-600={message.includes("saved")} class:text-red-600={!message.includes("saved")}>
    {message}
  </p>
{/if}
