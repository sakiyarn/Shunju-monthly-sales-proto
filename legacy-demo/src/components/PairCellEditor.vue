<template>
  <div class="flex min-w-[170px] items-center gap-1 rounded border border-slate-300 bg-white p-1">
    <input ref="firstInput" v-model.number="hours" type="number" min="0" step="0.5" class="w-16 rounded border border-slate-300 bg-white px-1 py-0.5 text-xs text-slate-900" />
    <span class="text-xs text-slate-500">h</span>
    <input v-model.number="unitPrice" type="number" min="0" step="100" class="w-20 rounded border border-slate-300 bg-white px-1 py-0.5 text-xs text-slate-900" />
  </div>
</template>

<script setup lang="ts">
import { nextTick, ref } from 'vue'

const props = defineProps<{ params: { value: { hours: number; unitPrice: number } } }>()

const firstInput = ref<HTMLInputElement | null>(null)
const hours = ref<number>(props.params.value?.hours ?? 0)
const unitPrice = ref<number>(props.params.value?.unitPrice ?? 0)

const getValue = () => ({ hours: Number(hours.value) || 0, unitPrice: Number(unitPrice.value) || 0 })

const afterGuiAttached = () => {
  void nextTick(() => firstInput.value?.focus())
}

defineExpose({ getValue, afterGuiAttached })
</script>
