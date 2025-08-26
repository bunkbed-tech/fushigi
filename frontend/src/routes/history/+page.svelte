<script lang="ts">
  let { data } = $props();
</script>

<main class="flex-1 overflow-auto p-6">
  {#if data.error}
    <p class="text-red-600">{data.error}</p>
  {:else if !data.entries || data.entries.length === 0}
    <p>No entries yet.</p>
  {:else}
    <ul class="space-y-4">
      {#each data.entries as entry (entry.id)}
        <li class="p-4 border rounded hover:bg-gray-100 cursor-pointer">
          <h2 class="text-lg font-semibold">
            {#if entry.private}
              <span class="mr-1" title="Private">🔒</span>
            {/if}
            {entry.title}
          </h2>
          <p class="text-sm text-gray-600">
            {new Date(entry.created_at).toLocaleDateString()} –
            {new Date(entry.created_at).toLocaleTimeString()}
          </p>
        </li>
      {/each}
    </ul>
  {/if}
</main>
