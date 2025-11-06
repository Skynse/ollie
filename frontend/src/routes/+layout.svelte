<script lang="ts">
    import { page } from "$app/stores";
</script>

<slot />

<style>
    :global(html) {
        scroll-behavior: smooth;
    }
</style>
