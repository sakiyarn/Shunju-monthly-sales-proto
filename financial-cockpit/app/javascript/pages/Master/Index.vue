<template>
  <main class="mx-auto max-w-[1400px] space-y-6 px-6 py-8">
    <section class="card">
      <h2 class="card-title">👥 セクション1: メンバー管理</h2>
      <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
        <button class="btn-accent" @click="openUserModal()">＋ メンバーを追加</button>
        <label class="inline-flex items-center gap-2 text-sm text-slate-700">
          <input v-model="showInactiveUsers" type="checkbox" />
          無効メンバーを表示
        </label>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="text-left text-slate-600">
              <th class="p-2">並び順</th>
              <th class="p-2">名前</th>
              <th class="p-2">表示名</th>
              <th class="p-2">メール</th>
              <th class="p-2">役職</th>
              <th class="p-2">権限</th>
              <th class="p-2">状態</th>
              <th class="p-2">関連件数</th>
              <th class="p-2">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="u in filteredSectionUsers" :key="u.id" class="border-t border-slate-200">
              <td class="p-2">
                <input
                  :value="u.display_order"
                  type="number"
                  min="1"
                  max="9999"
                  class="input w-24"
                  @change="updateDisplayOrder(u, $event)"
                />
              </td>
              <td class="p-2">{{ u.name }}</td>
              <td class="p-2">{{ u.display_name || '—' }}</td>
              <td class="p-2">{{ u.email }}</td>
              <td class="p-2">{{ u.role_name || '未設定' }}</td>
              <td class="p-2">{{ u.system_role }}</td>
              <td class="p-2">
                <span :class="u.is_active ? 'text-emerald-700' : 'text-red-700'">
                  {{ u.is_active ? '有効' : '無効' }}
                </span>
              </td>
              <td class="p-2">
                {{ u.related_records_count }}
              </td>
              <td class="p-2">
                <button class="btn-sub" @click="openUserModal(u.id)">編集</button>
                <button
                  v-if="u.is_active"
                  class="btn-sub ml-1 text-red-600"
                  @click="deactivateUser(u.id)"
                >
                  無効化
                </button>
                <button
                  v-else
                  class="btn-sub ml-1 text-emerald-700"
                  @click="activateUser(u.id)"
                >
                  再有効化
                </button>
                <button
                  class="btn-sub ml-1 text-red-700"
                  :class="u.can_hard_delete ? '' : 'cursor-not-allowed opacity-50 text-slate-400'"
                  :disabled="!u.can_hard_delete"
                  :title="u.can_hard_delete ? '関連データ0件のため削除可能です' : `関連データが${u.related_records_count}件あるため削除できません`"
                  @click="hardDeleteUser(u)"
                >
                  削除
                </button>
              </td>
            </tr>
            <tr v-if="filteredSectionUsers.length === 0" class="border-t border-slate-200">
              <td class="p-3 text-sm text-slate-500" colspan="9">表示対象のメンバーはいません</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section class="card master-s2">
      <div class="master-s2-toolbar">
        <div>
          <h2 class="card-title mb-1">セクション2: 案件管理</h2>
          <p class="text-xs text-slate-600">編集ボタン経由で案件名を変更 / 並び順は1〜9999で即時反映</p>
        </div>
        <div class="master-s2-metrics">
          <span class="master-s2-badge"><strong>{{ section2Stats.active }}件</strong><span>進行中</span></span>
          <span class="master-s2-badge"><strong>{{ section2Stats.closed }}件</strong><span>終了</span></span>
          <span class="master-s2-badge"><strong>{{ section2Stats.deletable }}件</strong><span>削除可</span></span>
        </div>
      </div>

      <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
        <button class="btn-accent cursor-pointer" @click="openProjectModal">＋ 案件を追加</button>
        <label class="inline-flex items-center gap-2 text-sm text-slate-700">
          <input v-model="showInactiveProjects" type="checkbox" />
          終了案件を表示
        </label>
      </div>

      <div class="master-s2-head">
        <div>並び順</div>
        <div>案件名</div>
        <div>状態</div>
        <div class="text-right">操作</div>
      </div>

      <div class="space-y-2">
        <div
          v-for="p in filteredSection2Projects"
          :key="p.id"
          class="master-s2-row"
          :class="p.is_active ? '' : 'opacity-60'"
        >
          <div>
            <input
              :value="p.display_order"
              type="number"
              min="1"
              max="9999"
              class="input w-24"
              @change="updateProjectDisplayOrder(p, $event)"
            />
          </div>
          <div><p class="master-s2-name">{{ p.name }}</p></div>
          <div>
            <span :class="p.is_active ? 'master-s2-status-active' : 'master-s2-status-closed'">
              {{ p.is_active ? '進行中' : '終了' }}
            </span>
          </div>
          <div class="text-right">
            <button class="btn-sub cursor-pointer" @click="openProjectEditModal(p)">編集</button>
            <button v-if="p.is_active" class="btn-sub ml-1 cursor-pointer" @click="closeProject(p.id)">終了する</button>
            <button v-else class="btn-sub ml-1 cursor-pointer text-emerald-700" @click="activateProject(p.id)">再開</button>
            <button
              class="btn-sub ml-1 text-red-700"
              :class="p.can_hard_delete ? 'cursor-pointer' : 'cursor-not-allowed opacity-50 text-slate-400'"
              :disabled="!p.can_hard_delete"
              :title="p.can_hard_delete ? '関連データ0件のため削除可能です' : `関連データが${p.related_records_count}件あるため削除できません`"
              @click="hardDeleteProject(p)"
            >
              削除
            </button>
          </div>
        </div>

        <p v-if="filteredSection2Projects.length === 0" class="rounded border border-slate-200 p-3 text-sm text-slate-500">
          表示対象の案件はありません
        </p>
      </div>
    </section>

    <section class="card">
      <h2 class="card-title">🧩 セクション3: 案件メンバーアサイン</h2>
      <div class="mb-4 flex flex-wrap gap-2">
        <button v-for="p in projects" :key="`tab-${p.id}`" class="tab" :class="activeAssignProjectId === p.id ? 'tab-active' : ''" @click="activeAssignProjectId = p.id">{{ p.name }}</button>
      </div>
      <div class="space-y-3">
        <table class="w-full text-sm">
          <thead><tr class="text-left text-slate-600"><th class="p-2">メンバー</th><th class="p-2">デフォルト売上単価</th><th class="p-2">操作</th></tr></thead>
          <tbody>
            <tr v-for="(a, idx) in activeAssignments" :key="`${a.projectId}-${a.userId}`" class="border-t border-slate-200">
              <td class="p-2">{{ userNameById(a.userId) }}</td>
              <td class="p-2">
                <input v-model.number="a.defaultUnitPrice" type="number" class="input" />
                <p class="text-xs text-slate-500">{{ formatYen(a.defaultUnitPrice) }}</p>
              </td>
              <td class="p-2"><button class="btn-sub" @click="unassignMember(idx)">アサイン解除</button></td>
            </tr>
          </tbody>
        </table>
        <div class="rounded border border-slate-200 p-3">
          <h3 class="mb-2 text-sm font-semibold">＋ メンバーをアサイン</h3>
          <div class="flex flex-wrap items-end gap-2">
            <select v-model="newAssign.userId" class="input">
              <option value="">未アサインメンバーを選択</option>
              <option v-for="u in unassignedUsers" :key="u.id" :value="u.id">{{ u.name }}</option>
            </select>
            <input v-model.number="newAssign.defaultUnitPrice" type="number" class="input" placeholder="デフォルト売上単価" />
            <button class="btn-accent" @click="addAssignment">追加</button>
          </div>
          <p v-if="errors.s3" class="error-msg">{{ errors.s3 }}</p>
        </div>
      </div>
      <button class="btn-save" @click="saveSection('s3')">保存</button>
    </section>

    <section class="card">
      <h2 class="card-title">📥 セクション4: 会計データ（freee CSV インポート）</h2>
      <div class="mb-3 flex flex-wrap gap-2">
        <input ref="csvInput" type="file" accept=".csv" class="hidden" @change="onCsvPicked" />
        <button class="btn-accent" @click="csvInput?.click()">CSV ファイルを選択</button>
      </div>
      <div class="mb-4 rounded border border-dashed border-accent/50 p-6 text-center text-sm text-slate-600" @dragover.prevent @drop.prevent="onCsvDrop">ここに CSV をドラッグ&ドロップ</div>
      <div class="ag-theme-quartz h-[260px] w-full">
        <AgGridVue class="h-full w-full" :rowData="accountingRows" :columnDefs="accountingColDefs" :defaultColDef="defaultColDef" @cell-value-changed="markDirty" />
      </div>
      <button class="btn-save" @click="saveSection('s4')">保存</button>
    </section>

    <section class="card">
      <h2 class="card-title">📊 セクション5: 請求稼働実績（案件×メンバー×月）</h2>
      <div class="mb-3 flex flex-wrap gap-2">
        <button v-for="p in projects" :key="`work-${p.id}`" class="tab" :class="activeWorkProjectId === p.id ? 'tab-active' : ''" @click="activeWorkProjectId = p.id">{{ p.name }}</button>
      </div>
      <div class="ag-theme-quartz h-[320px] w-full">
        <AgGridVue class="h-full w-full" :rowData="workRowsByProject[activeWorkProjectId]" :columnDefs="workColDefs" :defaultColDef="defaultColDef" @cell-value-changed="onWorkCellChanged" />
      </div>
      <button class="btn-save" @click="saveSection('s5')">保存</button>
    </section>

    <section class="card">
      <h2 class="card-title">🗓️ セクション6: 月次営業日数</h2>
      <div class="ag-theme-quartz h-[160px] w-full">
        <AgGridVue class="h-full w-full" :rowData="[businessDaysRow]" :columnDefs="businessDayColDefs" :defaultColDef="defaultColDef" @cell-value-changed="markDirty" />
      </div>
      <button class="btn-save" @click="saveSection('s6')">保存</button>
    </section>

    <section class="card">
      <h2 class="card-title">💼 セクション7: メンバー原価データ（月次）</h2>
      <div class="ag-theme-quartz h-[320px] w-full">
        <AgGridVue class="h-full w-full" :rowData="memberCostRows" :columnDefs="memberCostMatrixColDefs" :defaultColDef="defaultColDef" @cell-value-changed="onCostMatrixChanged" />
      </div>
      <p v-if="errors.s7" class="error-msg">{{ errors.s7 }}</p>
      <button class="btn-save" @click="saveSection('s7')">保存</button>
    </section>

    <section class="card">
      <h2 class="card-title">🏢 セクション8: 役員原価データ（月次）</h2>
      <div class="ag-theme-quartz h-[320px] w-full">
        <AgGridVue class="h-full w-full" :rowData="officerCostRows" :columnDefs="officerCostMatrixColDefs" :defaultColDef="defaultColDef" @cell-value-changed="onCostMatrixChanged" />
      </div>
      <p v-if="errors.s8" class="error-msg">{{ errors.s8 }}</p>
      <button class="btn-save" @click="saveSection('s8')">保存</button>
    </section>

    <section class="card">
      <h2 class="card-title">🧾 セクション9: 特定経費（経費按分用）</h2>
      <button class="btn-accent mb-3" @click="addExpense">＋ 経費を追加</button>
      <div class="space-y-3">
        <div v-for="(e, idx) in expenses" :key="e.id" class="rounded border border-slate-200 p-3">
          <div class="grid grid-cols-1 gap-2 md:grid-cols-4">
            <select v-model="e.month" class="input" :class="errorClass(`s9.${idx}.month`)">
              <option value="">対象月</option><option v-for="m in visibleMonths" :key="m.key" :value="m.key">{{ m.label }}</option>
            </select>
            <input v-model="e.name" class="input" placeholder="経費名" :class="errorClass(`s9.${idx}.name`)" />
            <input v-model.number="e.amount" type="number" class="input" placeholder="金額" :class="errorClass(`s9.${idx}.amount`)" />
            <button class="btn-sub" @click="removeExpense(idx)">削除</button>
          </div>
          <p class="mt-1 text-xs text-slate-500">{{ formatYen(e.amount) }}</p>
          <div class="mt-2 flex flex-wrap gap-3 text-xs">
            <label v-for="p in projects" :key="`${e.id}-${p.id}`" class="inline-flex items-center gap-1">
              <input type="checkbox" :checked="e.projectIds.includes(p.id)" @change="toggleExpenseProject(e, p.id, ($event.target as HTMLInputElement).checked)" />
              {{ p.name }}
            </label>
          </div>
          <p v-if="errors[`s9.${idx}.month`]" class="error-msg">{{ errors[`s9.${idx}.month`] }}</p>
          <p v-if="errors[`s9.${idx}.name`]" class="error-msg">{{ errors[`s9.${idx}.name`] }}</p>
          <p v-if="errors[`s9.${idx}.amount`]" class="error-msg">{{ errors[`s9.${idx}.amount`] }}</p>
        </div>
      </div>
      <button class="btn-save" @click="saveSection('s9')">保存</button>
    </section>

    <section class="card">
      <h2 class="card-title">🛠️ セクション10: 請求調整</h2>
      <button class="btn-accent mb-3" @click="addAdjustment">＋ 調整を追加</button>
      <div class="space-y-3">
        <div v-for="(a, idx) in adjustments" :key="a.id" class="rounded border border-slate-200 p-3">
          <div class="grid grid-cols-1 gap-2 md:grid-cols-3">
            <select v-model="a.userId" class="input" :class="errorClass(`s10.${idx}.userId`)">
              <option value="">対象メンバー</option><option v-for="u in users" :key="u.id" :value="u.id">{{ u.name }}</option>
            </select>
            <select v-model="a.projectId" class="input" :class="errorClass(`s10.${idx}.projectId`)">
              <option value="">対象案件</option><option v-for="p in projects" :key="p.id" :value="p.id">{{ p.name }}</option>
            </select>
            <input v-model.number="a.amount" type="number" class="input" placeholder="調整金額" :class="errorClass(`s10.${idx}.amount`)" />
            <select v-model="a.fromMonth" class="input" :class="errorClass(`s10.${idx}.fromMonth`)">
              <option value="">元の月</option><option v-for="m in visibleMonths" :key="`from-${m.key}`" :value="m.key">{{ m.label }}</option>
            </select>
            <select v-model="a.toMonth" class="input" :class="errorClass(`s10.${idx}.toMonth`)">
              <option value="">反映月</option><option v-for="m in visibleMonths" :key="`to-${m.key}`" :value="m.key">{{ m.label }}</option>
            </select>
            <button class="btn-sub" @click="removeAdjustment(idx)">削除</button>
          </div>
          <input v-model="a.memo" class="mt-2 w-full rounded border border-slate-300 bg-base px-3 py-2 text-sm" placeholder="メモ" :class="errorClass(`s10.${idx}.memo`)" />
          <p class="mt-1 text-xs text-slate-500">{{ formatYen(a.amount) }}</p>
          <p v-if="errors[`s10.${idx}.userId`]" class="error-msg">{{ errors[`s10.${idx}.userId`] }}</p>
          <p v-if="errors[`s10.${idx}.projectId`]" class="error-msg">{{ errors[`s10.${idx}.projectId`] }}</p>
          <p v-if="errors[`s10.${idx}.amount`]" class="error-msg">{{ errors[`s10.${idx}.amount`] }}</p>
          <p v-if="errors[`s10.${idx}.fromMonth`]" class="error-msg">{{ errors[`s10.${idx}.fromMonth`] }}</p>
          <p v-if="errors[`s10.${idx}.toMonth`]" class="error-msg">{{ errors[`s10.${idx}.toMonth`] }}</p>
          <p v-if="errors[`s10.${idx}.memo`]" class="error-msg">{{ errors[`s10.${idx}.memo`] }}</p>
        </div>
      </div>
      <button class="btn-save" @click="saveSection('s10')">保存</button>
    </section>

    <div v-if="toast.show" class="fixed right-4 top-20 rounded px-4 py-2 text-sm font-semibold" :class="toast.type === 'success' ? 'bg-green-600' : 'bg-red-600'">{{ toast.message }}</div>

    <div v-if="userModal.open" class="fixed inset-0 z-50 grid place-items-center bg-black/60">
      <div class="w-full max-w-md rounded-lg border border-slate-200 bg-card p-4">
        <h3 class="mb-3 text-lg font-semibold">{{ userModal.editingUserId === null ? 'メンバー追加' : 'メンバー編集' }}</h3>
        <div class="space-y-2">
          <input v-model="userModal.form.name" class="input w-full" placeholder="名前" />
          <p v-if="userFormErrors.name" class="error-msg">{{ userFormErrors.name }}</p>
          <input v-model="userModal.form.display_name" class="input w-full" placeholder="表示名（例: 三千人将A）" />
          <p v-if="userFormErrors.display_name" class="error-msg">{{ userFormErrors.display_name }}</p>
          <input
            v-model.number="userModal.form.display_order"
            type="number"
            min="1"
            max="9999"
            class="input w-full"
            placeholder="並び順（1〜9999）"
          />
          <p v-if="userFormErrors.display_order" class="error-msg">{{ userFormErrors.display_order }}</p>
          <input v-model="userModal.form.email" class="input w-full" placeholder="メール" />
          <p v-if="userFormErrors.email" class="error-msg">{{ userFormErrors.email }}</p>
          <select v-model="userModal.form.role_id" class="input w-full">
            <option :value="null">役職を選択</option>
            <option v-for="r in props.roles" :key="r.id" :value="r.id">{{ r.name }}</option>
          </select>
          <p v-if="userFormErrors.role_id" class="error-msg">{{ userFormErrors.role_id }}</p>
          <select v-model="userModal.form.system_role" class="input w-full">
            <option value="admin">admin</option><option value="member">member</option>
          </select>
          <p v-if="userFormErrors.system_role" class="error-msg">{{ userFormErrors.system_role }}</p>
          <p v-if="userFormErrors.base" class="error-msg">{{ userFormErrors.base }}</p>
        </div>
        <div class="mt-4 flex justify-end gap-2"><button class="btn-sub" @click="closeUserModal">キャンセル</button><button class="btn-accent" @click="saveUserModal">保存</button></div>
      </div>
    </div>

    <div v-if="projectModalOpen" class="fixed inset-0 z-50 grid place-items-center bg-black/60">
      <div class="w-full max-w-md rounded-lg border border-slate-200 bg-card p-4">
        <h3 class="mb-3 text-lg font-semibold">案件追加</h3>
        <div class="space-y-2"><input v-model="projectForm.name" class="input w-full" placeholder="案件名" /></div>
        <div class="mt-4 flex justify-end gap-2"><button class="btn-sub" @click="projectModalOpen = false">キャンセル</button><button class="btn-accent" @click="saveProjectModal">保存</button></div>
      </div>
    </div>

    <div v-if="projectEditModal.open" class="fixed inset-0 z-50 grid place-items-center bg-black/60">
      <div class="w-full max-w-md rounded-lg border border-slate-200 bg-card p-4">
        <h3 class="mb-1 text-lg font-semibold">案件名を編集</h3>
        <p class="mb-3 text-xs text-slate-600">反映後は他画面の案件名表示にも影響します。</p>
        <div class="space-y-2">
          <input v-model="projectEditModal.name" class="input w-full" placeholder="案件名" @keydown.enter.prevent="saveProjectEditModal" />
        </div>
        <div class="mt-4 flex justify-end gap-2">
          <button class="btn-sub" @click="closeProjectEditModal">キャンセル</button>
          <button class="btn-accent" @click="saveProjectEditModal">保存</button>
        </div>
      </div>
    </div>
  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { router, usePage } from '@inertiajs/vue3'
import { AgGridVue } from 'ag-grid-vue3'
import type { ColDef, ColGroupDef, ValueFormatterParams } from 'ag-grid-community'
import PairCellEditor from '../../components/PairCellEditor.vue'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'

interface RoleOption {
  id: number
  name: string
}

interface UserRecord {
  id: number
  name: string
  email: string
  system_role: 'admin' | 'member'
  role_id: number | null
  display_name: string | null
  role_name: string | null
  display_order: number
  is_active: boolean
  related_records_count: number
  can_hard_delete: boolean
}

interface ProjectRecord {
  id: number
  name: string
  is_active: boolean
  display_order: number
  related_records_count: number
  can_hard_delete: boolean
}

interface InertiaFlash {
  notice?: string
  alert?: string
}

interface InertiaPageProps {
  [key: string]: unknown
  flash?: InertiaFlash
  errors?: Record<string, string | string[]>
}

const props = defineProps<{
  users: UserRecord[]
  roles: RoleOption[]
  projects: ProjectRecord[]
  initialData?: Record<string, unknown>
}>()

const page = usePage<InertiaPageProps>()
const showInactiveUsers = ref(false)
const filteredSectionUsers = computed(() => {
  if (showInactiveUsers.value) return props.users
  return props.users.filter((user) => user.is_active)
})

type UserRole = 'admin' | 'member'

interface User { id: string; name: string; email: string; role: UserRole }
interface DemoProject { id: string; name: string; client: string; status: 'open' | 'closed' }
interface Assignment { projectId: string; userId: string; defaultUnitPrice: number }
interface MonthDef { key: string; label: string; month: number }
interface Expense { id: string; month: string; name: string; amount: number; projectIds: string[] }
interface Adjustment { id: string; userId: string; projectId: string; fromMonth: string; toMonth: string; amount: number; memo: string }
interface PersistedBillingAdjustment {
  userId: string
  userName: string
  projectId: string
  projectName: string
  fromMonth: string
  toMonth: string
  amount: number
  memo: string
}

const formatYen = (v: number) => new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', maximumFractionDigits: 0 }).format(Number(v) || 0)
const BILLING_ADJUSTMENTS_STORAGE_KEY = 'proto.billing-adjustments.v1'

const monthMaster: MonthDef[] = [
  { key: '2025-08', label: '2025年8月', month: 8 },
  { key: '2025-09', label: '2025年9月', month: 9 },
  { key: '2025-10', label: '2025年10月', month: 10 },
  { key: '2025-11', label: '2025年11月', month: 11 },
  { key: '2025-12', label: '2025年12月', month: 12 },
  { key: '2026-01', label: '2026年1月', month: 1 },
  { key: '2026-02', label: '2026年2月', month: 2 }
]

const visibleMonths = computed(() => monthMaster)

const users = reactive<User[]>([
  { id: 'u01', name: '田中 太郎', email: 'tanaka@example.com', role: 'admin' },
  { id: 'u02', name: '佐藤 花子', email: 'sato@example.com', role: 'admin' },
  { id: 'u03', name: '鈴木 一郎', email: 'suzuki@example.com', role: 'member' },
  { id: 'u04', name: '高橋 春菜', email: 'takahashi@example.com', role: 'member' },
  { id: 'u05', name: '伊藤 翔', email: 'ito@example.com', role: 'member' },
  { id: 'u06', name: '渡辺 美咲', email: 'watanabe@example.com', role: 'member' },
  { id: 'u07', name: '山本 隆', email: 'yamamoto@example.com', role: 'member' },
  { id: 'u08', name: '中村 彩', email: 'nakamura@example.com', role: 'member' },
  { id: 'u09', name: '小林 健', email: 'kobayashi@example.com', role: 'member' },
  { id: 'u10', name: '加藤 綾', email: 'kato@example.com', role: 'member' }
])

const projects = reactive<DemoProject[]>([
  { id: 'p001', name: '案件001', client: 'Alpha株式会社', status: 'open' },
  { id: 'p002', name: '案件002', client: 'Beta株式会社', status: 'open' },
  { id: 'p003', name: '案件003', client: 'Gamma株式会社', status: 'closed' }
])
const section2Projects = reactive<ProjectRecord[]>([])
const showInactiveProjects = ref(false)

const syncSection2Projects = () => {
  section2Projects.splice(
    0,
    section2Projects.length,
    ...props.projects.map((project) => ({
      id: project.id,
      name: project.name,
      is_active: project.is_active,
      display_order: project.display_order,
      related_records_count: project.related_records_count,
      can_hard_delete: project.can_hard_delete
    }))
  )
}
syncSection2Projects()

const orderedSection2Projects = computed(() => {
  return [...section2Projects].sort((a, b) => {
    if (a.is_active !== b.is_active) return a.is_active ? -1 : 1
    if (a.display_order !== b.display_order) return a.display_order - b.display_order
    return a.name.localeCompare(b.name, 'ja')
  })
})

const filteredSection2Projects = computed(() => {
  if (showInactiveProjects.value) return orderedSection2Projects.value
  return orderedSection2Projects.value.filter((project) => project.is_active)
})

const section2Stats = computed(() => {
  const active = section2Projects.filter((project) => project.is_active).length
  const closed = section2Projects.length - active
  const deletable = section2Projects.filter((project) => project.can_hard_delete).length
  return { active, closed, deletable }
})

const assignments = reactive<Assignment[]>([
  { projectId: 'p001', userId: 'u01', defaultUnitPrice: 12000 },
  { projectId: 'p001', userId: 'u03', defaultUnitPrice: 7000 },
  { projectId: 'p001', userId: 'u04', defaultUnitPrice: 6800 },
  { projectId: 'p001', userId: 'u05', defaultUnitPrice: 6500 },
  { projectId: 'p002', userId: 'u02', defaultUnitPrice: 11500 },
  { projectId: 'p002', userId: 'u06', defaultUnitPrice: 6400 },
  { projectId: 'p002', userId: 'u07', defaultUnitPrice: 6200 },
  { projectId: 'p003', userId: 'u08', defaultUnitPrice: 6600 },
  { projectId: 'p003', userId: 'u09', defaultUnitPrice: 6300 },
  { projectId: 'p003', userId: 'u10', defaultUnitPrice: 6100 }
])

const activeAssignProjectId = ref('p001')
const activeAssignments = computed(() => assignments.filter((a) => a.projectId === activeAssignProjectId.value))
const unassignedUsers = computed(() => {
  const assignedIds = new Set(activeAssignments.value.map((a) => a.userId))
  return users.filter((u) => !assignedIds.has(u.id))
})
const newAssign = reactive({ userId: '', defaultUnitPrice: 6000 })

const accountingRows = reactive([
  { item: '売上高', '2025-08': 3600000, '2025-09': 3800000, '2025-10': 3900000, '2025-11': 4100000, '2025-12': 4200000, '2026-01': 3950000, '2026-02': 4050000 },
  { item: '人件費', '2025-08': 1850000, '2025-09': 1920000, '2025-10': 1990000, '2025-11': 2060000, '2025-12': 2120000, '2026-01': 2010000, '2026-02': 2050000 },
  { item: '販促費（経費の総額）', '2025-08': 180000, '2025-09': 220000, '2025-10': 210000, '2025-11': 240000, '2025-12': 260000, '2026-01': 200000, '2026-02': 195000 },
  { item: '会計上の営業利益', '2025-08': 1570000, '2025-09': 1660000, '2025-10': 1700000, '2025-11': 1790000, '2025-12': 1820000, '2026-01': 1740000, '2026-02': 1805000 }
])

const activeWorkProjectId = ref('p001')
const workRowsByProject = reactive<Record<string, Record<string, unknown>[]>>({})

const defaultHours = [120, 125, 130, 132, 128, 118, 120]
const seedMemberIds = ['u03', 'u04', 'u05', 'u06', 'u07', 'u08', 'u09', 'u10']
projects.forEach((p, projectIdx) => {
  workRowsByProject[p.id] = seedMemberIds.map((uid, rowIdx) => {
    const row: Record<string, unknown> = { member: userNameById(uid) }
    monthMaster.forEach((m, idx) => {
      row[m.key] = { hours: defaultHours[idx] - rowIdx * 2 + projectIdx, unitPrice: 6200 + projectIdx * 100 }
    })
    return row
  })
})

const businessDaysRow = reactive<Record<string, unknown>>({ item: '営業日数', '2025-08': 22, '2025-09': 20, '2025-10': 22, '2025-11': 20, '2025-12': 20, '2026-01': 18, '2026-02': 20 })

type CostPart = 'salary' | 'legal' | 'welfare' | 'bonus' | 'internal'
const editableCostParts: CostPart[] = ['salary', 'legal', 'welfare', 'bonus']

const costField = (monthKey: string, part: CostPart) => `${monthKey}_${part}`

const recalcInternalCost = (row: Record<string, unknown>) => {
  visibleMonths.value.forEach((m) => {
    const salary = Number(row[costField(m.key, 'salary')]) || 0
    const legal = Number(row[costField(m.key, 'legal')]) || 0
    const welfare = Number(row[costField(m.key, 'welfare')]) || 0
    const bonus = Number(row[costField(m.key, 'bonus')]) || 0
    const days = Number(businessDaysRow[m.key]) || 1
    row[costField(m.key, 'internal')] = Math.round((salary + legal + welfare + bonus) / days / 8)
  })
}

const createCostMatrixRows = (members: string[], salaryBase: number, officerMode = false) => {
  return members.map((member, memberIndex) => {
    const row: Record<string, unknown> = { member }
    visibleMonths.value.forEach((m, monthIndex) => {
      const salary = salaryBase + memberIndex * (officerMode ? 15000 : 12000) + monthIndex * 4000
      const legal = Math.round(salary * 0.16)
      const welfare = 12000 + memberIndex * 1000 + monthIndex * 400
      const isBonusMonth = m.key.endsWith('-12') || m.key.endsWith('-02')
      const bonus = isBonusMonth ? 70000 + memberIndex * (officerMode ? 5000 : 3000) : 0

      row[costField(m.key, 'salary')] = salary
      row[costField(m.key, 'legal')] = legal
      row[costField(m.key, 'welfare')] = welfare
      row[costField(m.key, 'bonus')] = bonus
      row[costField(m.key, 'internal')] = 0
    })
    recalcInternalCost(row)
    return row
  })
}

const memberCostRows = reactive(createCostMatrixRows(
  ['鈴木 一郎', '高橋 春菜', '伊藤 翔', '渡辺 美咲', '山本 隆', '中村 彩', '小林 健', '加藤 綾'],
  280000
))
const officerCostRows = reactive(createCostMatrixRows(['代表A', '代表B'], 500000, true))

const expenses = reactive<Expense[]>([
  { id: 'e1', month: '2025-11', name: 'Kaigi on Rails 参加費', amount: 100000, projectIds: ['p001', 'p002'] },
  { id: 'e2', month: '2025-12', name: 'Laravel ライセンス', amount: 50000, projectIds: ['p003'] }
])

const adjustments = reactive<Adjustment[]>([
  { id: 'a1', userId: 'u04', projectId: 'p002', fromMonth: '2026-01', toMonth: '2026-02', amount: -18000, memo: '1月分 請求時間誤り修正' }
])

const defaultColDef: ColDef = { editable: true, resizable: true }
const makeMonthCols = (formatter?: (v: number) => string): ColDef[] => visibleMonths.value.map((m) => ({
  headerName: m.label,
  field: m.key,
  editable: true,
  valueFormatter: formatter
    ? (params: ValueFormatterParams) => formatter(Number(params.value))
    : undefined
}))

const accountingColDefs = computed<ColDef[]>(() => [
  { field: 'item', headerName: '項目', pinned: 'left', editable: false, minWidth: 200 },
  ...makeMonthCols((v) => formatYen(v))
])

const workColDefs = computed<ColDef[]>(() => [
  { field: 'member', headerName: 'メンバー', pinned: 'left', editable: false, minWidth: 180 },
  ...visibleMonths.value.map((m) => ({
    headerName: m.label,
    field: m.key,
    editable: true,
    cellEditor: PairCellEditor,
    valueFormatter: (params: ValueFormatterParams) => {
      const val = params.value as { hours: number; unitPrice: number }
      if (!val) return ''
      return `${val.hours}h / ${formatYen(val.unitPrice)}`
    }
  }))
])

const businessDayColDefs = computed<ColDef[]>(() => [
  { field: 'item', headerName: '項目', pinned: 'left', editable: false, minWidth: 140 },
  ...makeMonthCols((v) => `${v}`)
])

const createCostMatrixColDefs = (salaryLabel: string, bonusLabel: string): Array<ColDef | ColGroupDef> => [
  {
    field: 'member',
    headerName: 'スタッフ',
    pinned: 'left',
    editable: false,
    minWidth: 170,
    cellStyle: { fontWeight: '700', background: '#f8fafc' }
  },
  ...visibleMonths.value.map((m) => ({
    headerName: `${m.month}月`,
    marryChildren: true,
    children: [
      {
        field: costField(m.key, 'salary'),
        headerName: salaryLabel,
        minWidth: 120,
        valueFormatter: (params: ValueFormatterParams) => formatYen(Number(params.value) || 0)
      },
      {
        field: costField(m.key, 'legal'),
        headerName: '法定福利費',
        minWidth: 120,
        valueFormatter: (params: ValueFormatterParams) => formatYen(Number(params.value) || 0)
      },
      {
        field: costField(m.key, 'welfare'),
        headerName: '福利厚生費',
        minWidth: 120,
        valueFormatter: (params: ValueFormatterParams) => formatYen(Number(params.value) || 0)
      },
      {
        field: costField(m.key, 'bonus'),
        headerName: bonusLabel,
        minWidth: 110,
        valueFormatter: (params: ValueFormatterParams) => formatYen(Number(params.value) || 0)
      },
      {
        field: costField(m.key, 'internal'),
        headerName: '社内原価(h)',
        editable: false,
        minWidth: 120,
        cellStyle: { fontWeight: '700' },
        valueFormatter: (params: ValueFormatterParams) => formatYen(Number(params.value) || 0)
      }
    ]
  }))
]

const memberCostMatrixColDefs = computed(() => createCostMatrixColDefs('給与', '賞与'))
const officerCostMatrixColDefs = computed(() => createCostMatrixColDefs('役員報酬', '役員賞与'))

const csvInput = ref<HTMLInputElement | null>(null)
const toast = reactive({ show: false, type: 'success' as 'success' | 'error', message: '' })

const errors = reactive<Record<string, string>>({})
const dirty = ref(false)
let skipDirtyTracking = true
let suppressBeforeVisitGuard = false

const userModal = reactive({
  open: false,
  editingUserId: null as number | null,
  form: {
    name: '',
    email: '',
    system_role: 'member' as UserRole,
    role_id: null as number | null,
    display_name: '',
    display_order: 1
  }
})
const projectModalOpen = ref(false)
const projectForm = reactive({ name: '' })
const projectEditModal = reactive({
  open: false,
  id: null as number | null,
  name: '',
  originalName: ''
})

const clearErrors = (prefix: string) => {
  Object.keys(errors).forEach((k) => {
    if (k === prefix || k.startsWith(`${prefix}.`)) delete errors[k]
  })
}

const markDirty = () => { dirty.value = true }
const errorClass = (key: string) => (errors[key] ? 'border-red-500' : '')
const serverErrors = computed<Record<string, string | string[]>>(() => {
  return page.props.errors ?? {}
})

const firstServerError = (key: string) => {
  const value = serverErrors.value[key]
  if (Array.isArray(value)) return value[0] ?? ''
  return value ?? ''
}

const userFormErrors = computed(() => ({
  name: firstServerError('name'),
  display_name: firstServerError('display_name'),
  display_order: firstServerError('display_order'),
  email: firstServerError('email'),
  role_id: firstServerError('role_id'),
  system_role: firstServerError('system_role'),
  base: firstServerError('base')
}))

function userNameById(userId: string) {
  return users.find((u) => u.id === userId)?.name ?? userId
}

function projectNameById(projectId: string) {
  return projects.find((p) => p.id === projectId)?.name ?? projectId
}

const resetUserModalForm = () => {
  userModal.form.name = ''
  userModal.form.email = ''
  userModal.form.system_role = 'member'
  userModal.form.role_id = null
  userModal.form.display_name = ''
  userModal.form.display_order = suggestedDisplayOrder()
}

function openUserModal(userId?: number) {
  if (typeof userId === 'number') {
    const user = props.users.find((candidate) => candidate.id === userId)
    if (!user) return
    userModal.form.name = user.name
    userModal.form.email = user.email
    userModal.form.system_role = user.system_role
    userModal.form.role_id = user.role_id
    userModal.form.display_name = user.display_name ?? ''
    userModal.form.display_order = user.display_order
    userModal.editingUserId = user.id
  } else {
    resetUserModalForm()
    userModal.editingUserId = null
  }
  userModal.open = true
}

function closeUserModal() {
  userModal.open = false
  userModal.editingUserId = null
}

function saveUserModal() {
  const payload = {
    name: userModal.form.name,
    email: userModal.form.email,
    system_role: userModal.form.system_role,
    role_id: userModal.form.role_id,
    display_name: userModal.form.display_name,
    display_order: userModal.form.display_order
  }

  suppressBeforeVisitGuard = true

  if (userModal.editingUserId === null) {
    router.post('/users', { user: payload }, {
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => {
        userModal.open = false
        userModal.editingUserId = null
      },
      onFinish: () => {
        suppressBeforeVisitGuard = false
      }
    })
  } else {
    router.patch(`/users/${userModal.editingUserId}`, { user: payload }, {
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => {
        userModal.open = false
        userModal.editingUserId = null
      },
      onFinish: () => {
        suppressBeforeVisitGuard = false
      }
    })
  }
}

function deactivateUser(id: number) {
  if (!window.confirm('このメンバーを無効化してよろしいですか？')) return
  suppressBeforeVisitGuard = true
  router.delete(`/users/${id}`, {
    preserveScroll: true,
    preserveState: true,
    onFinish: () => {
      suppressBeforeVisitGuard = false
    }
  })
}

function activateUser(id: number) {
  suppressBeforeVisitGuard = true
  router.patch(`/users/${id}/activate`, {}, {
    preserveScroll: true,
    preserveState: true,
    onFinish: () => {
      suppressBeforeVisitGuard = false
    }
  })
}

function suggestedDisplayOrder() {
  const maxDisplayOrder = props.users.reduce((max, user) => {
    return Math.max(max, user.display_order)
  }, 0)
  return Math.min(9999, Math.max(1, maxDisplayOrder + 1))
}

function firstValidationMessage(validationErrors: Record<string, string | string[]>) {
  const firstError = Object.values(validationErrors)[0]
  if (Array.isArray(firstError)) return firstError[0] ?? ''
  return firstError ?? ''
}

function updateDisplayOrder(user: UserRecord, event: Event) {
  const target = event.target as HTMLInputElement
  const nextDisplayOrder = Number(target.value)

  if (!Number.isInteger(nextDisplayOrder) || nextDisplayOrder < 1 || nextDisplayOrder > 9999) {
    target.value = String(user.display_order)
    showToast('error', '並び順は1〜9999の整数で入力してください')
    return
  }

  if (nextDisplayOrder === user.display_order) return

  suppressBeforeVisitGuard = true
  router.patch(`/users/${user.id}`, { user: { display_order: nextDisplayOrder } }, {
    preserveScroll: true,
    preserveState: true,
    onError: (validationErrors) => {
      target.value = String(user.display_order)
      const message = firstValidationMessage(validationErrors)
      showToast('error', message || '並び順を更新できませんでした')
    },
    onFinish: () => {
      suppressBeforeVisitGuard = false
    }
  })
}

function hardDeleteUser(user: UserRecord) {
  if (!user.can_hard_delete) {
    showToast('error', `関連データが${user.related_records_count}件あるため削除できません`)
    return
  }

  if (!window.confirm('このメンバーを完全に削除します。元に戻せません。よろしいですか？')) return

  suppressBeforeVisitGuard = true
  router.delete(`/users/${user.id}/hard_destroy`, {
    preserveScroll: true,
    preserveState: true,
    onFinish: () => {
      suppressBeforeVisitGuard = false
    }
  })
}

function openProjectModal() { projectModalOpen.value = true }
function saveProjectModal() {
  const name = projectForm.name.trim()
  if (!name) {
    showToast('error', '案件名を入力してください')
    return
  }

  suppressBeforeVisitGuard = true
  router.post('/projects', { project: { name } }, {
    preserveScroll: true,
    preserveState: true,
    onSuccess: () => {
      projectForm.name = ''
      projectModalOpen.value = false
    },
    onError: (validationErrors) => {
      const message = firstValidationMessage(validationErrors)
      showToast('error', message || '案件を追加できませんでした')
    },
    onFinish: () => {
      suppressBeforeVisitGuard = false
    }
  })
}

function openProjectEditModal(project: ProjectRecord) {
  projectEditModal.open = true
  projectEditModal.id = project.id
  projectEditModal.name = project.name
  projectEditModal.originalName = project.name
}

function closeProjectEditModal() {
  projectEditModal.open = false
  projectEditModal.id = null
  projectEditModal.name = ''
  projectEditModal.originalName = ''
}

function saveProjectEditModal() {
  if (projectEditModal.id === null) return

  const normalizedName = projectEditModal.name.trim()
  if (!normalizedName) {
    showToast('error', '案件名を入力してください')
    return
  }

  if (normalizedName === projectEditModal.originalName) {
    closeProjectEditModal()
    return
  }

  const project = section2Projects.find((item) => item.id === projectEditModal.id)
  const previousName = project?.name ?? projectEditModal.originalName
  if (project) project.name = normalizedName

  suppressBeforeVisitGuard = true
  router.patch(`/projects/${projectEditModal.id}`, { project: { name: normalizedName } }, {
    preserveScroll: true,
    preserveState: true,
    onSuccess: () => {
      closeProjectEditModal()
    },
    onError: (validationErrors) => {
      if (project) project.name = previousName
      const message = firstValidationMessage(validationErrors)
      showToast('error', message || '案件名を更新できませんでした')
    },
    onFinish: () => {
      suppressBeforeVisitGuard = false
    }
  })
}

function updateProjectDisplayOrder(project: ProjectRecord, event: Event) {
  const target = event.target as HTMLInputElement
  const nextDisplayOrder = Number(target.value)

  if (!Number.isInteger(nextDisplayOrder) || nextDisplayOrder < 1 || nextDisplayOrder > 9999) {
    target.value = String(project.display_order)
    showToast('error', '並び順は1〜9999の整数で入力してください')
    return
  }

  if (nextDisplayOrder === project.display_order) return

  const previousDisplayOrder = project.display_order
  project.display_order = nextDisplayOrder

  suppressBeforeVisitGuard = true
  router.patch(`/projects/${project.id}`, { project: { display_order: nextDisplayOrder } }, {
    preserveScroll: true,
    preserveState: true,
    onError: (validationErrors) => {
      project.display_order = previousDisplayOrder
      target.value = String(previousDisplayOrder)
      const message = firstValidationMessage(validationErrors)
      showToast('error', message || '並び順を更新できませんでした')
    },
    onFinish: () => {
      suppressBeforeVisitGuard = false
    }
  })
}

function closeProject(projectId: number) {
  if (!window.confirm('この案件を終了してよろしいですか？')) return
  suppressBeforeVisitGuard = true
  router.delete(`/projects/${projectId}`, {
    preserveScroll: true,
    preserveState: true,
    onFinish: () => {
      suppressBeforeVisitGuard = false
    }
  })
}

function activateProject(projectId: number) {
  suppressBeforeVisitGuard = true
  router.patch(`/projects/${projectId}/activate`, {}, {
    preserveScroll: true,
    preserveState: true,
    onFinish: () => {
      suppressBeforeVisitGuard = false
    }
  })
}

function hardDeleteProject(project: ProjectRecord) {
  if (!project.can_hard_delete) {
    showToast('error', `関連データが${project.related_records_count}件あるため削除できません`)
    return
  }

  if (!window.confirm('この案件を完全に削除します。元に戻せません。よろしいですか？')) return

  suppressBeforeVisitGuard = true
  router.delete(`/projects/${project.id}/hard_destroy`, {
    preserveScroll: true,
    preserveState: true,
    onFinish: () => {
      suppressBeforeVisitGuard = false
    }
  })
}

function addAssignment() {
  clearErrors('s3')
  if (!newAssign.userId) {
    errors.s3 = '未アサインメンバーを選択してください。'
    return
  }
  if (Number.isNaN(Number(newAssign.defaultUnitPrice))) {
    errors.s3 = 'デフォルト売上単価は数値で入力してください。'
    return
  }
  assignments.push({ projectId: activeAssignProjectId.value, userId: newAssign.userId, defaultUnitPrice: Number(newAssign.defaultUnitPrice) })
  newAssign.userId = ''
  newAssign.defaultUnitPrice = 6000
  markDirty()
}

function unassignMember(indexInFiltered: number) {
  if (!window.confirm('アサイン解除してよろしいですか？')) return
  const item = activeAssignments.value[indexInFiltered]
  const realIndex = assignments.findIndex((a) => a.projectId === item.projectId && a.userId === item.userId)
  if (realIndex >= 0) assignments.splice(realIndex, 1)
  markDirty()
}

function showToast(type: 'success' | 'error', message: string) {
  toast.show = true
  toast.type = type
  toast.message = message
  window.setTimeout(() => { toast.show = false }, 2500)
}

function processCsv(fileName: string) {
  if (!fileName.endsWith('.csv')) {
    showToast('error', 'CSV形式のファイルを指定してください')
    return
  }
  if (window.confirm('同月のデータが既に存在します。既存データを上書きしますか？')) {
    showToast('success', '8月〜2月のデータを取り込みました')
    markDirty()
  }
}

function onCsvPicked(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (file) processCsv(file.name)
}

function onCsvDrop(event: DragEvent) {
  const file = event.dataTransfer?.files?.[0]
  if (file) processCsv(file.name)
}

function onWorkCellChanged(event: { colDef?: { field?: string }; data?: Record<string, unknown> }) {
  const key = event.colDef?.field
  if (!key || !monthMaster.find((m) => m.key === key)) {
    markDirty()
    return
  }
  const row = event.data
  if (!row) {
    markDirty()
    return
  }
  const prevMonth = monthMaster[monthMaster.findIndex((m) => m.key === key) - 1]
  if (!prevMonth) {
    markDirty()
    return
  }
  const currentValue = row[key] as { hours: number; unitPrice: number }
  const prevValue = row[prevMonth.key] as { hours: number; unitPrice: number }
  if (currentValue && prevValue && (!currentValue.unitPrice || currentValue.unitPrice <= 0)) {
    currentValue.unitPrice = prevValue.unitPrice
  }
  markDirty()
}

function onCostMatrixChanged(event: { data?: Record<string, unknown>; api?: { refreshCells?: (params?: unknown) => void }; node?: unknown }) {
  if (!event.data) {
    markDirty()
    return
  }
  recalcInternalCost(event.data)
  event.api?.refreshCells?.({ rowNodes: event.node ? [event.node] : undefined, force: true })
  markDirty()
}

function addExpense() {
  expenses.push({ id: `e${Date.now()}`, month: visibleMonths.value[0]?.key ?? '', name: '', amount: 0, projectIds: [] })
  markDirty()
}

function removeExpense(index: number) {
  expenses.splice(index, 1)
  markDirty()
}

function toggleExpenseProject(expense: Expense, projectId: string, checked: boolean) {
  const has = expense.projectIds.includes(projectId)
  if (checked && !has) expense.projectIds.push(projectId)
  if (!checked && has) expense.projectIds = expense.projectIds.filter((id) => id !== projectId)
  markDirty()
}

function addAdjustment() {
  adjustments.push({ id: `a${Date.now()}`, userId: '', projectId: '', fromMonth: '', toMonth: '', amount: 0, memo: '' })
  markDirty()
}

function removeAdjustment(index: number) {
  adjustments.splice(index, 1)
  markDirty()
}

const toPersistedBillingAdjustments = (): PersistedBillingAdjustment[] => {
  return adjustments.map((adjustment) => ({
    userId: adjustment.userId,
    userName: userNameById(adjustment.userId),
    projectId: adjustment.projectId,
    projectName: projectNameById(adjustment.projectId),
    fromMonth: adjustment.fromMonth,
    toMonth: adjustment.toMonth,
    amount: Number(adjustment.amount) || 0,
    memo: adjustment.memo
  }))
}

function persistBillingAdjustments() {
  if (typeof window === 'undefined') return
  try {
    window.localStorage.setItem(BILLING_ADJUSTMENTS_STORAGE_KEY, JSON.stringify(toPersistedBillingAdjustments()))
  } catch {
    // no-op
  }
}

function loadBillingAdjustments() {
  if (typeof window === 'undefined') return
  try {
    const raw = window.localStorage.getItem(BILLING_ADJUSTMENTS_STORAGE_KEY)
    if (!raw) return

    const parsed = JSON.parse(raw)
    if (!Array.isArray(parsed)) return

    const loaded = parsed.reduce<Adjustment[]>((acc, item, index) => {
      if (!item || typeof item !== 'object') return acc
      const candidate = item as Partial<Adjustment> & Partial<PersistedBillingAdjustment>
      const userId = typeof candidate.userId === 'string' ? candidate.userId : ''
      const projectId = typeof candidate.projectId === 'string' ? candidate.projectId : ''
      const fromMonth = typeof candidate.fromMonth === 'string' ? candidate.fromMonth : ''
      const toMonth = typeof candidate.toMonth === 'string' ? candidate.toMonth : ''
      const memo = typeof candidate.memo === 'string' ? candidate.memo : ''
      const amount = Number(candidate.amount)

      if (!userId || !projectId || !fromMonth || !toMonth || !memo || Number.isNaN(amount)) return acc

      acc.push({
        id: typeof candidate.id === 'string' ? candidate.id : `a_imported_${index + 1}`,
        userId,
        projectId,
        fromMonth,
        toMonth,
        amount,
        memo
      })
      return acc
    }, [])

    if (loaded.length === 0) return
    adjustments.splice(0, adjustments.length, ...loaded)
  } catch {
    // no-op
  }
}

function validateSection(section: string) {
  clearErrors(section)
  if (section === 's1') {
    const invalid = users.some((u) => !u.name || !u.email)
    if (invalid) errors.s1 = '名前・メールアドレスは必須です。'
    return !invalid
  }
  if (section === 's3') {
    const invalid = assignments.some((a) => Number.isNaN(Number(a.defaultUnitPrice)))
    if (invalid) errors.s3 = 'デフォルト売上単価は数値で入力してください。'
    return !invalid
  }
  if (section === 's7') {
    const invalid = memberCostRows.some((row) =>
      visibleMonths.value.some((m) =>
        editableCostParts.some((part) => Number.isNaN(Number(row[costField(m.key, part)])))
      )
    )
    if (invalid) errors.s7 = 'メンバー原価データは数値で入力してください。'
    return !invalid
  }
  if (section === 's8') {
    const invalid = officerCostRows.some((row) =>
      visibleMonths.value.some((m) =>
        editableCostParts.some((part) => Number.isNaN(Number(row[costField(m.key, part)])))
      )
    )
    if (invalid) errors.s8 = '役員原価データは数値で入力してください。'
    return !invalid
  }
  if (section === 's9') {
    let ok = true
    expenses.forEach((e, idx) => {
      if (!e.month) { errors[`s9.${idx}.month`] = '対象月は必須です'; ok = false }
      if (!e.name) { errors[`s9.${idx}.name`] = '経費名は必須です'; ok = false }
      if (Number.isNaN(Number(e.amount))) { errors[`s9.${idx}.amount`] = '金額は数値で入力してください'; ok = false }
    })
    return ok
  }
  if (section === 's10') {
    let ok = true
    adjustments.forEach((a, idx) => {
      if (!a.userId) { errors[`s10.${idx}.userId`] = '対象メンバーは必須です'; ok = false }
      if (!a.projectId) { errors[`s10.${idx}.projectId`] = '対象案件は必須です'; ok = false }
      if (!a.fromMonth) { errors[`s10.${idx}.fromMonth`] = '元の月は必須です'; ok = false }
      if (!a.toMonth) { errors[`s10.${idx}.toMonth`] = '反映月は必須です'; ok = false }
      if (!a.memo) { errors[`s10.${idx}.memo`] = 'メモは必須です'; ok = false }
      if (Number.isNaN(Number(a.amount))) { errors[`s10.${idx}.amount`] = '調整金額は数値で入力してください'; ok = false }
    })
    return ok
  }
  return true
}

function saveSection(section: string) {
  const ok = validateSection(section)
  if (!ok) return
  if (section === 's10') {
    persistBillingAdjustments()
  }
  showToast('success', `${section.toUpperCase()} を保存しました`)
  dirty.value = false
}

const beforeUnload = (event: BeforeUnloadEvent) => {
  if (!dirty.value) return
  event.preventDefault()
  event.returnValue = ''
}

let stopBeforeVisitListener: VoidFunction | null = null

onMounted(() => {
  loadBillingAdjustments()
  window.addEventListener('beforeunload', beforeUnload)

  stopBeforeVisitListener = router.on('before', (event) => {
    if (suppressBeforeVisitGuard) return
    if (event.detail.visit.method !== 'get') return
    if (!dirty.value) return
    if (!window.confirm('保存していない変更があります。移動しますか？')) {
      event.preventDefault()
    }
  })

  window.setTimeout(() => {
    skipDirtyTracking = false
  }, 0)
})

onUnmounted(() => {
  window.removeEventListener('beforeunload', beforeUnload)
  if (stopBeforeVisitListener) {
    stopBeforeVisitListener()
    stopBeforeVisitListener = null
  }
})

watch(
  () => page.props.flash,
  (flash) => {
    if (flash?.notice) showToast('success', flash.notice)
    if (flash?.alert) showToast('error', flash.alert)
  },
  { immediate: true }
)

watch(
  () => props.projects,
  () => {
    syncSection2Projects()
  },
  { deep: true }
)

watch([users, projects, assignments, expenses, adjustments, accountingRows, memberCostRows, officerCostRows], () => {
  if (skipDirtyTracking) return
  markDirty()
}, { deep: true })
</script>
