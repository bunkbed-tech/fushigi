<script lang="ts">
  let { form } = $props();
</script>

<form method="POST" class="space-y-4">
  <div>
    <label class="block text-sm font-medium" for="title">Title</label>
    <input id="title" name="title" type="text" class="w-full border rounded p-2" required />
  </div>

  <div>
    <label class="block text-sm font-medium" for="content">Content</label>
    <textarea id="content" name="content" class="w-full border rounded p-2 h-32" required></textarea>
  </div>

  <div>
    <input type="checkbox" id="private" name="private" />
    <label for="private">Private</label>
  </div>

  <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded">Save</button>
</form>

{#if form?.message}
  <p class="mt-4 text-green-600">{form.message}</p>
{/if}
