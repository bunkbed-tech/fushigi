<script lang="ts">
  import { onMount } from "svelte";

  let entries: any[] = [];
  let loading = true;
  let error = "";

  onMount(async () => {
    try {
      const res = await fetch(`${import.meta.env.VITE_API_BASE}/api/journal`);
      if (!res.ok) {
        throw new Error(`Failed to fetch journal entries: ${res.status}`);
      }
      entries = await res.json();
    } catch (e) {
      error = e instanceof Error ? e.message : String(e);
      entries = [];
    } finally {
      loading = false;
    }
  });
</script>

<main class="flex-1 overflow-auto p-6">
  {#if loading}
    <p>Loading journal entries...</p>
  {:else if error}
    <p class="text-red-600">{error}</p>
  {:else if !entries || entries.length === 0}
    <p>No entries yet.</p>
  {:else}
    <ul class="space-y-4">
      {#each entries as entry (entry.id)}
        <li class="p-4 border rounded hover:bg-gray-100 cursor-pointer">
          <h2 class="text-lg font-semibold">
            {#if entry.private}
              <span class="mr-1" title="Private">🔒</span>
            {/if}
            {entry.title}
          </h2>
          <p class="text-sm text-gray-600">
            {new Date(entry.created_at).toLocaleDateString()} —
            {new Date(entry.created_at).toLocaleTimeString()}
          </p>
        </li>
      {/each}
    </ul>
  {/if}
</main>
