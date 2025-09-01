<script lang="ts">
  import SearchForm from "$lib/components/search-form.svelte";
  import DataTable from "./data-table.svelte";
  import { columns } from "./columns.js";
  import { onMount } from "svelte";

  let grammarPoints: any[] = [];
  let loading = true;
  let error = "";

  onMount(async () => {
    try {
      const res = await fetch(`${import.meta.env.VITE_API_BASE}/api/grammar`);
      if (!res.ok) {
        throw new Error(`Failed to fetch grammar points: ${res.status}`);
      }
      grammarPoints = await res.json();
    } catch (e) {
      error = e instanceof Error ? e.message : String(e);
    } finally {
      loading = false;
    }
  });
</script>

<div>
  <div class="mb-4">
    <SearchForm />
  </div>

  {#if loading}
    <p>Loading grammar points...</p>
  {:else if error}
    <p class="text-red-600">Error: {error}</p>
  {:else}
    <DataTable data={grammarPoints} {columns} />
  {/if}
</div>
