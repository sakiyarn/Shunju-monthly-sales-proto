<template>
  <div class="min-h-screen bg-base text-slate-900">
    <header class="global-nav-wrap">
      <div class="global-nav">
        <div class="brand">
          <span class="brand-mark">PL</span>
          <span class="brand-text">案件別収益（P/L）分析</span>
        </div>
        <nav class="menu-links">
          <Link class="menu-link" :class="{ 'menu-link-active': isProjectPage }" href="/">案件</Link>
          <Link class="menu-link" :class="{ 'menu-link-active': isDashboardPage }" href="/dashboard">ダッシュボード</Link>
          <Link class="menu-link" href="/">従業員</Link>
          <Link class="menu-link" href="/">レポート</Link>
          <Link class="menu-link" href="/">設定</Link>
        </nav>
        <div class="menu-actions">
          <button class="icon-btn" type="button">通知</button>
          <Link class="icon-btn" :class="{ 'icon-btn-active': isMasterPage }" href="/master">マスタデータ管理</Link>
        </div>
      </div>
    </header>
    <slot />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Link, usePage } from '@inertiajs/vue3'

const page = usePage()
const isProjectPage = computed(() => page.url === '/' || page.url.startsWith('/?'))
const isDashboardPage = computed(() => page.url.startsWith('/dashboard'))
const isMasterPage = computed(() => page.url.startsWith('/master'))
</script>

<style scoped>
.global-nav-wrap {
  padding: 20px 20px 0;
}

.global-nav {
  max-width: 1500px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 12px 16px;
  background: #fff;
  border: 1px solid #d6d8dd;
  border-radius: 12px;
  box-shadow: 0 6px 18px rgba(28, 37, 54, 0.06);
}

.brand {
  display: flex;
  align-items: center;
  gap: 10px;
}

.brand-mark {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 800;
  color: #fff;
  background: #3f7dd4;
}

.brand-text {
  font-size: 34px;
  font-weight: 800;
  color: #111;
  letter-spacing: 0.01em;
}

.menu-links {
  display: flex;
  gap: 4px;
}

.menu-link {
  border: 1px solid transparent;
  background: transparent;
  color: #334155;
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 14px;
  font-weight: 700;
  text-decoration: none;
}

.menu-link:hover {
  background: #f2f4fb;
}

.menu-link-active {
  color: #1d4ed8;
  background: #e8edff;
  border-color: #c9d7ff;
}

.menu-actions {
  display: flex;
  gap: 8px;
}

.icon-btn {
  border: 1px solid #ccd3dd;
  background: #fff;
  color: #334155;
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 14px;
  font-weight: 700;
  text-decoration: none;
}

.icon-btn-active {
  color: #1d4ed8;
  border-color: #90aaf9;
  background: #eff3ff;
}

@media (max-width: 1320px) {
  .global-nav {
    gap: 10px;
    flex-wrap: wrap;
  }

  .brand-text {
    font-size: 24px;
  }
}
</style>
