<template>
  <main class="mx-auto max-w-[1400px] space-y-6 px-6 py-8">
    <div
      v-if="hasUnsavedChanges"
      class="fixed right-4 top-20 z-40 rounded-full border border-amber-300 bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-900 shadow-sm transition-all duration-200"
      aria-live="polite"
    >
      未保存の変更あり
    </div>

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

    <section class="card master-s3">
      <h2 class="card-title">🧩 セクション3: 案件メンバーアサイン</h2>
      <div class="master-s3-tabs">
        <div class="master-s3-active-tabs">
          <p class="master-s3-tab-label">進行中案件</p>
          <div class="master-s3-active-scroll">
            <button
              v-for="p in s3ActiveProjects"
              :key="`tab-active-${p.id}`"
              class="tab master-s3-tab"
              :class="activeAssignProjectId === p.id ? 'tab-active' : ''"
              @click="activeAssignProjectId = p.id"
            >
              {{ p.name }}
            </button>
            <p v-if="s3ActiveProjects.length === 0" class="master-s3-tab-empty">進行中案件はありません</p>
          </div>
        </div>
        <div v-if="s3ClosedProjects.length > 0" class="master-s3-closed-slot">
          <div class="master-s3-closed-head">
            <p class="master-s3-tab-label">終了案件</p>
            <span class="master-s3-closed-count">{{ s3ClosedProjects.length }}件</span>
          </div>
          <select class="input master-s3-closed-select" :value="selectedClosedProjectValue" @change="selectClosedProject(($event.target as HTMLSelectElement).value)">
            <option value="">終了案件を表示</option>
            <option v-for="p in s3ClosedProjects" :key="`closed-select-${p.id}`" :value="String(p.id)">{{ p.name }}</option>
          </select>
        </div>
      </div>
      <div class="space-y-3">
        <p v-if="!activeAssignProject" class="rounded border border-slate-200 p-3 text-sm text-slate-500">
          表示対象の案件がありません
        </p>
        <template v-else>
          <div class="master-s3-tools">
            <label class="master-s3-sort-wrap">
              <span class="master-s3-sort-label">メンバー並び</span>
              <select v-model="s3MemberSortMode" class="input master-s3-sort-select">
                <option value="section_order">セクション1の並び順</option>
                <option value="unit_price_desc">単価（高い順）</option>
              </select>
            </label>
          </div>
          <p v-if="!isActiveAssignProject" class="master-s3-readonly-note">
            終了案件は閲覧専用です。アサイン追加・解除・単価編集はできません。
          </p>
          <table class="w-full text-sm">
            <thead>
              <tr class="text-left text-slate-600">
                <th class="p-2">メンバー</th>
                <th class="p-2">デフォルト売上単価</th>
                <th class="p-2 text-right">操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="assignment in sortedActiveAssignments" :key="assignment.id" class="border-t border-slate-200">
                <td class="p-2">
                  <p class="font-semibold text-slate-900">{{ assignment.userLabel }}</p>
                  <span v-if="!assignment.userIsActive" class="master-s3-inactive-badge">無効</span>
                </td>
                <td class="p-2">
                  <p class="font-semibold text-slate-900">{{ formatYen(assignment.defaultUnitPrice) }}</p>
                  <p class="text-xs text-slate-500">{{ assignment.defaultUnitPrice.toLocaleString('ja-JP') }}円</p>
                </td>
                <td class="p-2 text-right">
                  <button
                    class="btn-sub"
                    :disabled="!isActiveAssignProject || s3State.processingAdd || s3State.processingRemoveId === assignment.id || s3PriceModal.processing"
                    @click="openAssignmentPriceModal(assignment)"
                  >
                    編集
                  </button>
                  <button
                    class="btn-sub ml-1"
                    :disabled="!isActiveAssignProject || s3State.processingAdd || s3State.processingRemoveId === assignment.id || s3PriceModal.processing"
                    @click="unassignMember(assignment)"
                  >
                    アサイン解除
                  </button>
                </td>
              </tr>
              <tr v-if="sortedActiveAssignments.length === 0" class="border-t border-slate-200">
                <td class="p-3 text-sm text-slate-500" colspan="3">この案件にはアサイン済みメンバーがいません</td>
              </tr>
            </tbody>
          </table>
          <div class="rounded border border-slate-200 p-3">
            <h3 class="mb-2 text-sm font-semibold">＋ メンバーをアサイン</h3>
            <div class="flex flex-wrap items-end gap-2">
              <select v-model.number="newAssign.userId" class="input" :disabled="!isActiveAssignProject || s3State.processingAdd">
                <option :value="null">未アサインメンバーを選択</option>
                <option v-for="u in unassignedUsers" :key="u.id" :value="u.id">{{ formatS3UserLabel(u) }}</option>
              </select>
              <input
                v-model.number="newAssign.defaultUnitPrice"
                type="number"
                min="0"
                step="1"
                class="input"
                placeholder="デフォルト売上単価"
                :disabled="!isActiveAssignProject || s3State.processingAdd"
              />
              <button class="btn-accent" :disabled="!isActiveAssignProject || s3State.processingAdd" @click="addAssignment">
                {{ s3State.processingAdd ? '追加中...' : '追加' }}
              </button>
            </div>
            <p v-if="!isActiveAssignProject" class="mt-2 text-xs text-slate-500">終了案件には新規アサインできません。</p>
            <p v-if="errors.s3" class="error-msg">{{ errors.s3 }}</p>
            <p v-else-if="s3ServerError" class="error-msg">{{ s3ServerError }}</p>
          </div>
        </template>
      </div>
    </section>

    <section class="card">
      <h2 class="card-title">📥 セクション4: 会計データ（freee CSV インポート）</h2>
      <div class="mb-3 flex flex-wrap items-center gap-2">
        <input ref="csvInput" type="file" accept=".csv" class="hidden" @change="onCsvPicked" />
        <button class="btn-accent" :disabled="s4State.processing || s4State.restoring" @click="csvInput?.click()">
          {{ s4State.processing ? '取込中...' : 'CSV ファイルを選択' }}
        </button>
        <p class="text-xs text-slate-500">手入力はできません。CSVのみ取り込み可能です。</p>
      </div>
      <div class="mb-3 flex flex-wrap items-center gap-2">
        <select
          v-model.number="s4State.selectedHistoryId"
          class="input min-w-[280px]"
          :disabled="s4State.processing || s4State.restoring || s4HistoryOptions.length === 0"
        >
          <option :value="null">復元履歴を選択</option>
          <option v-for="history in s4HistoryOptions" :key="history.id" :value="history.id">{{ history.label }}</option>
        </select>
        <button
          class="btn-sub"
          :disabled="s4State.processing || s4State.restoring || s4State.selectedHistoryId === null"
          @click="restoreS4History"
        >
          {{ s4State.restoring ? '復元中...' : 'この履歴に戻す' }}
        </button>
        <p class="text-xs text-slate-500">インポート直前の状態を最大3件保持します。</p>
      </div>
      <div
        class="mb-4 rounded border border-dashed border-accent/50 p-6 text-center text-sm text-slate-600"
        @dragover.prevent
        @drop.prevent="onCsvDrop"
      >
        ここに CSV をドラッグ&ドロップ
      </div>
      <p v-if="errors.s4" class="mb-3 error-msg">{{ errors.s4 }}</p>
      <p v-else class="mb-3 text-xs text-slate-500">表示内容は最新のCSV取り込み結果です。</p>
      <div class="ag-theme-quartz h-[260px] w-full">
        <AgGridVue class="h-full w-full" :rowData="accountingRows" :columnDefs="accountingColDefs" :defaultColDef="s4DefaultColDef" />
      </div>
      <p class="mt-2 text-xs text-slate-500">
        表示月: {{ s4MonthLabels.length > 0 ? s4MonthLabels.join(' / ') : 'データなし' }}
      </p>
    </section>

    <section class="card master-s5-card transition-colors duration-200" :class="s5Edited ? 'border-amber-300 bg-amber-50/60' : ''">
      <div class="master-s5-head">
        <div class="master-s5-head-main">
          <h2 class="card-title mb-0">📊 セクション5: 請求稼働実績（案件×メンバー×月）</h2>
          <div class="master-s5-status">
            <span
              v-if="s5Edited"
              class="inline-flex items-center rounded-full border border-amber-300 bg-amber-100 px-2 py-0.5 text-xs font-semibold text-amber-900"
            >
              未保存
            </span>
            <span class="master-s5-target-badge">
              {{ activeWorkProject ? `対象案件: ${activeWorkProject.name}` : '対象案件なし' }}
            </span>
          </div>
        </div>
        <div class="master-s5-head-actions">
          <p class="master-s5-head-note">操作ミス時は「未保存を破棄」で入力前の状態に戻せます。</p>
          <button
            class="master-s5-reset-btn"
            :disabled="!s5Edited || s5State.processing"
            @click="resetS5DraftWithConfirm"
          >
            未保存を破棄
          </button>
        </div>
      </div>

      <div class="master-s5-toolbar">
        <div class="master-s5-pane">
          <p class="master-s5-pane-label">案件</p>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="p in s5ActiveProjects"
              :key="`work-active-${p.id}`"
              class="tab cursor-pointer"
              :class="activeWorkProjectId === p.id ? 'tab-active' : ''"
              @click="attemptSwitchS5Project(p.id)"
            >
              {{ p.name }}
            </button>
          </div>
          <div v-if="s5ClosedProjects.length > 0" class="mt-2 min-w-56">
            <select class="input w-full" :value="selectedS5ClosedProjectValue" @change="selectS5ClosedProject(($event.target as HTMLSelectElement).value)">
              <option value="">終了案件を表示</option>
              <option v-for="p in s5ClosedProjects" :key="`work-closed-${p.id}`" :value="String(p.id)">{{ p.name }}</option>
            </select>
          </div>
        </div>

        <div class="master-s5-pane master-s5-pane-right">
          <p class="master-s5-pane-label">表示設定</p>
          <div class="flex flex-wrap items-center gap-2">
            <label class="text-sm text-slate-700">
              表示軸
              <select class="input ml-2" :value="s5DisplayMode" @change="onS5DisplayModeChanged(($event.target as HTMLSelectElement).value)">
                <option value="calendar">暦年（1月〜12月）</option>
                <option value="fiscal">決算年度（7月〜翌6月）</option>
              </select>
            </label>
            <label v-if="s5DisplayMode === 'calendar'" class="text-sm text-slate-700">
              年
              <select class="input ml-2" :value="s5CalendarYear" @change="onS5CalendarYearChanged(($event.target as HTMLSelectElement).value)">
                <option v-for="year in s5CalendarYears" :key="`s5-calendar-${year}`" :value="year">{{ year }}年</option>
              </select>
            </label>
            <label v-else class="text-sm text-slate-700">
              決算年度
              <select class="input ml-2" :value="s5FiscalYear" @change="onS5FiscalYearChanged(($event.target as HTMLSelectElement).value)">
                <option v-for="year in s5FiscalYears" :key="`s5-fiscal-${year}`" :value="year">{{ formatFiscalTermLabel(year) }}</option>
              </select>
            </label>
          </div>
          <div class="master-s5-shortcuts" aria-label="S5 keyboard shortcuts">
            <span class="master-s5-shortcut-chip">Enter: 編集開始 / 確定して下へ</span>
            <span class="master-s5-shortcut-chip">Tab: 右セルへ移動</span>
            <span class="master-s5-shortcut-chip">矢印キー: セル移動</span>
          </div>
        </div>
      </div>

      <p v-if="!activeWorkProject" class="mb-3 text-sm text-slate-500">表示対象の案件がありません。</p>
      <p v-else-if="!isActiveWorkProject" class="mb-3 text-sm text-slate-500">終了案件は閲覧専用です。</p>
      <p v-if="errors.s5" class="mb-3 error-msg whitespace-pre-line">{{ errors.s5 }}</p>
      <div v-if="s5MonthKeys.length === 0" class="rounded border border-slate-200 p-3 text-sm text-slate-500">
        表示可能な月データがありません。
      </div>
      <div v-else class="master-s5-grid-wrap">
        <div class="ag-theme-quartz h-[340px] w-full">
          <AgGridVue
            class="s5-grid h-full w-full"
            :rowData="activeWorkProjectId !== null ? (workRowsByProject[String(activeWorkProjectId)] ?? []) : []"
            :columnDefs="workColDefs"
            :defaultColDef="defaultColDef"
            :enterNavigatesVertically="false"
            :enterNavigatesVerticallyAfterEdit="true"
            @grid-ready="onWorkGridReady"
            @cell-value-changed="onWorkCellChanged"
          />
        </div>
      </div>
      <div class="master-s5-footer">
        <button class="btn-save cursor-pointer" :disabled="s5State.processing || !isActiveWorkProject || s5MonthKeys.length === 0" @click="saveSection('s5')">
          {{ s5Edited ? '保存（未保存あり）' : '保存' }}
        </button>
      </div>
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

    <div v-if="s3PriceModal.open" class="fixed inset-0 z-50 grid place-items-center bg-black/60">
      <div class="w-full max-w-md rounded-lg border border-slate-200 bg-card p-4">
        <h3 class="mb-1 text-lg font-semibold">請求単価を編集</h3>
        <p class="mb-3 text-sm text-slate-600">{{ s3PriceModal.userLabel }}</p>
        <div class="space-y-2">
          <input
            v-model.number="s3PriceModal.rate"
            type="number"
            min="0"
            step="1"
            class="input w-full"
            placeholder="デフォルト売上単価"
          />
          <p class="text-xs text-slate-500">{{ formatYen(s3PriceModal.rate) }}</p>
          <p v-if="s3PriceModal.error" class="error-msg">{{ s3PriceModal.error }}</p>
        </div>
        <div class="mt-4 flex justify-end gap-2">
          <button class="btn-sub" :disabled="s3PriceModal.processing" @click="closeAssignmentPriceModal">キャンセル</button>
          <button class="btn-accent" :disabled="s3PriceModal.processing" @click="saveAssignmentPriceModal">
            {{ s3PriceModal.processing ? '保存中...' : '保存' }}
          </button>
        </div>
      </div>
    </div>

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
import type {
  CellClassParams,
  ColDef,
  ColGroupDef,
  GridApi,
  GridReadyEvent,
  ValueFormatterParams,
  ValueGetterParams,
  ValueSetterParams
} from 'ag-grid-community'
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

interface ProjectMemberRecord {
  id: number
  project_id: number
  user_id: number
  default_billing_rate: number | string
}

interface BillingWorkLogRecord {
  project_id: number
  user_id: number
  work_month: string
  billed_hours: number
  billing_rate: number
}

interface MonthlyAccountingDataRecord {
  work_month: string
  sales: number | null
  gross_profit: number | null
  selling_general_admin_cost: number | null
  accounting_operating_profit: number | null
}

interface MonthlyAccountingHistoryRecord {
  id: number
  event_type: string
  created_at: string
}

type S4MetricKey = 'sales' | 'gross_profit' | 'selling_general_admin_cost' | 'accounting_operating_profit'

interface S4DiffMetric {
  key: S4MetricKey
  label: string
  existing: number | null
  incoming: number | null
}

interface S4DiffRecord {
  work_month: string
  metrics: S4DiffMetric[]
}

interface S4ImportSummary {
  target_months: number
  imported_months?: number
  created_months?: number
  updated_months?: number
  unchanged_months: number
  skipped_future_months: number
  new_months?: number
  changed_months?: number
}

interface S4ImportResponse {
  status: 'imported' | 'confirmation_required' | 'error'
  message?: string
  summary?: S4ImportSummary
  diffs?: S4DiffRecord[]
  errors?: string[]
}

interface S4RestoreResponse {
  status: 'restored' | 'error'
  message?: string
}

interface S3AssignmentRow {
  id: number
  projectId: number
  userId: number
  defaultUnitPrice: number
  userLabel: string
  userIsActive: boolean
  userDisplayOrder: number
}

type S3MemberSortMode = 'section_order' | 'unit_price_desc'
type S5DisplayMode = 'calendar' | 'fiscal'
type S5MetricKind = 'hours' | 'unitPrice'
type S5UnsavedAction = 'save' | 'discard' | 'cancel'
const FISCAL_TERM_START_YEAR = 2022

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
  project_members: ProjectMemberRecord[]
  s5_month_keys: string[]
  billing_work_logs: BillingWorkLogRecord[]
  monthly_accounting_data: MonthlyAccountingDataRecord[]
  monthly_accounting_histories: MonthlyAccountingHistoryRecord[]
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
interface MonthDef { key: string; label: string; month: number }
interface S5CellValue { hours: number; unitPrice: number }
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

interface S5DisplaySelection {
  mode: S5DisplayMode
  calendarYear: number
  fiscalYear: number
}

interface ParsedS5ChildField {
  monthKey: string
  kind: S5MetricKind
}

const formatYen = (v: number) => new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', maximumFractionDigits: 0 }).format(Number(v) || 0)
const BILLING_ADJUSTMENTS_STORAGE_KEY = 'proto.billing-adjustments.v1'

const legacyMonthMaster: MonthDef[] = [
  { key: '2025-08', label: '2025年8月', month: 8 },
  { key: '2025-09', label: '2025年9月', month: 9 },
  { key: '2025-10', label: '2025年10月', month: 10 },
  { key: '2025-11', label: '2025年11月', month: 11 },
  { key: '2025-12', label: '2025年12月', month: 12 },
  { key: '2026-01', label: '2026年1月', month: 1 },
  { key: '2026-02', label: '2026年2月', month: 2 }
]

const visibleMonths = computed(() => legacyMonthMaster)

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

const s3Users = computed(() => props.users)
const s3Projects = computed(() => {
  return [...props.projects].sort((a, b) => {
    if (a.is_active !== b.is_active) return a.is_active ? -1 : 1
    if (a.display_order !== b.display_order) return a.display_order - b.display_order
    return a.name.localeCompare(b.name, 'ja')
  })
})
const s3ActiveProjects = computed(() => s3Projects.value.filter((project) => project.is_active))
const s3ClosedProjects = computed(() => s3Projects.value.filter((project) => !project.is_active))
const activeAssignProjectId = ref<number | null>(null)

const s3State = reactive({
  processingAdd: false,
  processingRemoveId: null as number | null
})
const s3MemberSortMode = ref<S3MemberSortMode>('section_order')

const s3PriceModal = reactive({
  open: false,
  assignmentId: null as number | null,
  userLabel: '',
  rate: 0,
  processing: false,
  error: ''
})

const newAssign = reactive({
  userId: null as number | null,
  defaultUnitPrice: 6000
})

const formatS3UserLabel = (user: UserRecord) => {
  const displayName = user.display_name?.trim() || user.name
  const roleName = user.role_name?.trim() || '未設定'
  return `${displayName}（${roleName}）`
}

const activeAssignProject = computed(() => {
  if (activeAssignProjectId.value === null) return null
  return s3Projects.value.find((project) => project.id === activeAssignProjectId.value) ?? null
})

const isActiveAssignProject = computed(() => activeAssignProject.value?.is_active ?? false)

const activeAssignments = computed<S3AssignmentRow[]>(() => {
  if (activeAssignProjectId.value === null) return []

  return props.project_members
    .filter((assignment) => assignment.project_id === activeAssignProjectId.value)
    .map((assignment) => {
      const user = props.users.find((candidate) => candidate.id === assignment.user_id)
      return {
        id: assignment.id,
        projectId: assignment.project_id,
        userId: assignment.user_id,
        defaultUnitPrice: Number(assignment.default_billing_rate) || 0,
        userLabel: user ? formatS3UserLabel(user) : `不明なメンバー（ID:${assignment.user_id}）`,
        userIsActive: user?.is_active ?? false,
        userDisplayOrder: user?.display_order ?? 9999
      }
    })
})

const sortedActiveAssignments = computed(() => {
  return [...activeAssignments.value].sort((a, b) => {
    if (a.userIsActive !== b.userIsActive) return a.userIsActive ? -1 : 1

    if (s3MemberSortMode.value === 'unit_price_desc') {
      if (a.defaultUnitPrice !== b.defaultUnitPrice) return b.defaultUnitPrice - a.defaultUnitPrice
      if (a.userDisplayOrder !== b.userDisplayOrder) return a.userDisplayOrder - b.userDisplayOrder
      return a.userLabel.localeCompare(b.userLabel, 'ja')
    }

    if (a.userDisplayOrder !== b.userDisplayOrder) return a.userDisplayOrder - b.userDisplayOrder
    if (a.defaultUnitPrice !== b.defaultUnitPrice) return b.defaultUnitPrice - a.defaultUnitPrice
    return a.userLabel.localeCompare(b.userLabel, 'ja')
  })
})

const unassignedUsers = computed(() => {
  if (activeAssignProjectId.value === null) return []
  const assignedIds = new Set(activeAssignments.value.map((assignment) => assignment.userId))
  return s3Users.value
    .filter((user) => user.is_active)
    .filter((user) => !assignedIds.has(user.id))
    .sort((a, b) => {
      if (a.display_order !== b.display_order) return a.display_order - b.display_order
      return a.name.localeCompare(b.name, 'ja')
    })
})

const s3ServerError = computed(() => {
  return firstServerError('default_billing_rate') || firstServerError('project') || firstServerError('user')
})

const selectedClosedProjectValue = computed(() => {
  if (activeAssignProjectId.value === null) return ''
  return s3ClosedProjects.value.some((project) => project.id === activeAssignProjectId.value)
    ? String(activeAssignProjectId.value)
    : ''
})

const pickDefaultAssignProjectId = (projects: ProjectRecord[]) => {
  return projects.find((project) => project.is_active)?.id ?? projects[0]?.id ?? null
}

activeAssignProjectId.value = pickDefaultAssignProjectId(s3Projects.value)

function selectClosedProject(projectId: string) {
  if (!projectId) return
  activeAssignProjectId.value = Number(projectId)
}

const s4MetricRows: Array<{ key: S4MetricKey; item: string }> = [
  { key: 'sales', item: '売上高 計' },
  { key: 'gross_profit', item: '売上総損益金額' },
  { key: 'selling_general_admin_cost', item: '販売管理費 計' },
  { key: 'accounting_operating_profit', item: '営業損益金額' }
]

const s4Months = computed(() => {
  const monthKeys = new Set(props.monthly_accounting_data.map((row) => row.work_month))
  return [...monthKeys].sort()
})

const formatMonthLabel = (monthKey: string) => {
  const [year, month] = monthKey.split('-')
  const monthNumber = Number(month)
  if (!year || Number.isNaN(monthNumber)) return monthKey
  return `${year}年${monthNumber}月`
}

const s4MonthLabels = computed(() => s4Months.value.map((monthKey) => formatMonthLabel(monthKey)))

const formatHistoryDateTime = (text: string) => {
  const date = new Date(text)
  if (Number.isNaN(date.getTime())) return text
  return new Intl.DateTimeFormat('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date)
}

const s4HistoryOptions = computed(() => {
  return props.monthly_accounting_histories.map((history, index) => ({
    id: history.id,
    label: `${index + 1}個前 (${formatHistoryDateTime(history.created_at)})`
  }))
})

const s4DataByMonth = computed(() => {
  return new Map(props.monthly_accounting_data.map((row) => [row.work_month, row]))
})

const accountingRows = computed<Record<string, string | number | null>[]>(() => {
  return s4MetricRows.map((metric) => {
    const row: Record<string, string | number | null> = { item: metric.item }
    s4Months.value.forEach((monthKey) => {
      row[monthKey] = s4DataByMonth.value.get(monthKey)?.[metric.key] ?? null
    })
    return row
  })
})

const s5Projects = computed(() => [...s3Projects.value])
const s5ActiveProjects = computed(() => s5Projects.value.filter((project) => project.is_active))
const s5ClosedProjects = computed(() => s5Projects.value.filter((project) => !project.is_active))
const s5DataMonthKeys = computed(() => [...new Set(props.s5_month_keys)].sort())
const s5DisplayMode = ref<S5DisplayMode>('calendar')
const now = new Date()
const currentYear = now.getFullYear()
const currentMonth = now.getMonth() + 1
const currentFiscalYear = currentMonth >= 7 ? currentYear : currentYear - 1
const fallbackYears = [currentYear - 1, currentYear]

const s5CalendarYears = computed(() => {
  const years = new Set<number>(
    s5DataMonthKeys.value.map((monthKey) => Number(monthKey.slice(0, 4))).filter((year) => Number.isInteger(year))
  )
  fallbackYears.forEach((year) => years.add(year))
  return [...years].sort((a, b) => a - b)
})

const s5FiscalYears = computed(() => {
  const years = new Set<number>(
    s5DataMonthKeys.value
      .map((monthKey) => {
        const year = Number(monthKey.slice(0, 4))
        const month = Number(monthKey.slice(5, 7))
        if (!Number.isInteger(year) || !Number.isInteger(month)) return null
        return month >= 7 ? year : year - 1
      })
      .filter((year): year is number => year !== null)
  )
  fallbackYears.forEach((year) => years.add(year))
  return [...years].sort((a, b) => a - b)
})

const s5CalendarYear = ref<number>(s5CalendarYears.value[s5CalendarYears.value.length - 1] ?? currentYear)
const s5FiscalYear = ref<number>(s5FiscalYears.value[s5FiscalYears.value.length - 1] ?? currentFiscalYear)

const monthKey = (year: number, month: number) => `${year}-${String(month).padStart(2, '0')}`

const formatFiscalTermLabel = (fiscalYear: number) => {
  const termNumber = fiscalYear - FISCAL_TERM_START_YEAR + 1
  if (termNumber <= 0) return `${fiscalYear}年度（${fiscalYear}年7月〜${fiscalYear + 1}年6月）`
  return `${termNumber}期目（${fiscalYear}年7月-${fiscalYear + 1}年6月）`
}

const s5MonthKeys = computed(() => {
  if (s5DisplayMode.value === 'calendar') {
    return Array.from({ length: 12 }, (_, index) => monthKey(s5CalendarYear.value, index + 1))
  }
  return [
    monthKey(s5FiscalYear.value, 7),
    monthKey(s5FiscalYear.value, 8),
    monthKey(s5FiscalYear.value, 9),
    monthKey(s5FiscalYear.value, 10),
    monthKey(s5FiscalYear.value, 11),
    monthKey(s5FiscalYear.value, 12),
    monthKey(s5FiscalYear.value + 1, 1),
    monthKey(s5FiscalYear.value + 1, 2),
    monthKey(s5FiscalYear.value + 1, 3),
    monthKey(s5FiscalYear.value + 1, 4),
    monthKey(s5FiscalYear.value + 1, 5),
    monthKey(s5FiscalYear.value + 1, 6)
  ]
})
const activeWorkProjectId = ref<number | null>(null)
const pendingS5ProjectId = ref<number | null>(null)
const pendingS5DisplayChange = ref<S5DisplaySelection | null>(null)
const isSwitchingS5Project = ref(false)
const workGridApi = ref<GridApi | null>(null)
const s5State = reactive({
  processing: false
})
const s5Edited = ref(false)
const s5DirtyCellKeys = reactive(new Set<string>())
const workRowsByProject = reactive<Record<string, Record<string, unknown>[]>>({})

const activeWorkProject = computed(() => {
  if (activeWorkProjectId.value === null) return null
  return s5Projects.value.find((project) => project.id === activeWorkProjectId.value) ?? null
})

const isActiveWorkProject = computed(() => activeWorkProject.value?.is_active ?? false)

const selectedS5ClosedProjectValue = computed(() => {
  if (activeWorkProjectId.value === null) return ''
  return s5ClosedProjects.value.some((project) => project.id === activeWorkProjectId.value)
    ? String(activeWorkProjectId.value)
    : ''
})

const pickDefaultWorkProjectId = (projects: ProjectRecord[]) => {
  return projects.find((project) => project.is_active)?.id ?? projects[0]?.id ?? null
}

const normalizeS5CellValue = (value: unknown): S5CellValue => {
  if (!value || typeof value !== 'object') return { hours: 0, unitPrice: 0 }
  const candidate = value as Partial<{ hours: unknown; unitPrice: unknown }>
  const hours = Number.parseInt(String(candidate.hours ?? 0), 10)
  const unitPrice = Number.parseInt(String(candidate.unitPrice ?? 0), 10)
  return {
    hours: Number.isFinite(hours) ? hours : 0,
    unitPrice: Number.isFinite(unitPrice) ? unitPrice : 0
  }
}

const normalizeS5MetricValue = (value: unknown) => {
  const parsed = Number.parseInt(String(value ?? 0), 10)
  return Number.isFinite(parsed) ? parsed : 0
}

const s5ChildField = (monthKey: string, kind: S5MetricKind) => `${monthKey}_${kind}`

const parseS5ChildField = (field: string): ParsedS5ChildField | null => {
  const match = field.match(/^(\d{4}-\d{2})_(hours|unitPrice)$/)
  if (!match) return null
  return { monthKey: match[1], kind: match[2] as S5MetricKind }
}

const buildS5PersistedValueKey = (projectId: number, userId: number, monthKey: string) => `${projectId}:${userId}:${monthKey}`
const buildS5DirtyCellKey = (projectId: number, userId: number, monthKey: string, kind: S5MetricKind) => `${projectId}:${userId}:${monthKey}:${kind}`

const s5PersistedValuesByKey = computed(() => {
  return new Map(
    props.billing_work_logs.map((log) => [
      buildS5PersistedValueKey(log.project_id, log.user_id, log.work_month),
      { hours: Number(log.billed_hours) || 0, unitPrice: Number(log.billing_rate) || 0 }
    ])
  )
})

const s5PersistedValueFor = (projectId: number, userId: number, monthKey: string): S5CellValue => {
  return s5PersistedValuesByKey.value.get(buildS5PersistedValueKey(projectId, userId, monthKey)) ?? { hours: 0, unitPrice: 0 }
}

const clearS5DirtyCells = () => {
  s5DirtyCellKeys.clear()
  s5Edited.value = false
  workGridApi.value?.refreshCells({ force: true })
}

const syncS5DirtyCell = (projectId: number, userId: number, monthKey: string, kind: S5MetricKind, current: S5CellValue) => {
  const persisted = s5PersistedValueFor(projectId, userId, monthKey)
  const currentMetric = kind === 'hours' ? current.hours : current.unitPrice
  const persistedMetric = kind === 'hours' ? persisted.hours : persisted.unitPrice
  const dirtyKey = buildS5DirtyCellKey(projectId, userId, monthKey, kind)

  if (currentMetric === persistedMetric) {
    s5DirtyCellKeys.delete(dirtyKey)
  } else {
    s5DirtyCellKeys.add(dirtyKey)
  }

  s5Edited.value = s5DirtyCellKeys.size > 0
}

const isS5DirtyCell = (projectId: number, userId: number, monthKey: string, kind: S5MetricKind) => {
  return s5DirtyCellKeys.has(buildS5DirtyCellKey(projectId, userId, monthKey, kind))
}

const rebuildWorkRowsByProject = () => {
  clearS5DirtyCells()

  Object.keys(workRowsByProject).forEach((key) => {
    delete workRowsByProject[key]
  })

  const userById = new Map(props.users.map((user) => [user.id, user]))

  s5Projects.value.forEach((project) => {
    const assignments = props.project_members
      .filter((assignment) => assignment.project_id === project.id)
      .sort((a, b) => {
        const userA = userById.get(a.user_id)
        const userB = userById.get(b.user_id)
        const orderA = userA?.display_order ?? 9999
        const orderB = userB?.display_order ?? 9999
        if (orderA !== orderB) return orderA - orderB
        return (userA?.name ?? '').localeCompare(userB?.name ?? '', 'ja')
      })

    workRowsByProject[String(project.id)] = assignments.map((assignment) => {
      const user = userById.get(assignment.user_id)
      const row: Record<string, unknown> = {
        projectId: project.id,
        userId: assignment.user_id,
        member: user?.name ?? `不明なメンバー（ID:${assignment.user_id}）`
      }

      s5MonthKeys.value.forEach((monthKey) => {
        row[monthKey] = s5PersistedValueFor(project.id, assignment.user_id, monthKey)
      })
      return row
    })
  })
}

activeWorkProjectId.value = pickDefaultWorkProjectId(s5Projects.value)
rebuildWorkRowsByProject()

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
const s4DefaultColDef: ColDef = { editable: false, resizable: true }
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
  ...s4Months.value.map((monthKey) => ({
    headerName: formatMonthLabel(monthKey),
    field: monthKey,
    editable: false,
    valueFormatter: (params: ValueFormatterParams) => {
      if (params.value === null || params.value === undefined || params.value === '') return '—'
      return formatYen(Number(params.value))
    }
  }))
])

const createS5ChildColumn = (monthKey: string, kind: S5MetricKind): ColDef => ({
  field: s5ChildField(monthKey, kind),
  headerName: kind === 'hours' ? '稼働' : '単価',
  minWidth: kind === 'hours' ? 80 : 110,
  width: kind === 'hours' ? 88 : 120,
  maxWidth: kind === 'hours' ? 96 : 130,
  editable: () => isActiveWorkProject.value,
  cellEditor: 'agNumberCellEditor',
  cellEditorParams: () => ({
    min: 0,
    max: kind === 'hours' ? 999 : 99_999,
    step: kind === 'hours' ? 1 : 10,
    showStepperButtons: true
  }),
  valueGetter: (params: ValueGetterParams<Record<string, unknown>>) => {
    const normalized = normalizeS5CellValue(params.data?.[monthKey])
    return kind === 'hours' ? normalized.hours : normalized.unitPrice
  },
  valueSetter: (params: ValueSetterParams<Record<string, unknown>>) => {
    if (!params.data) return false
    const normalized = normalizeS5CellValue(params.data[monthKey])
    const metricValue = normalizeS5MetricValue(params.newValue)
    if (kind === 'hours') {
      normalized.hours = metricValue
    } else {
      normalized.unitPrice = metricValue
    }
    params.data[monthKey] = normalized
    return true
  },
  valueFormatter: (params: ValueFormatterParams<Record<string, unknown>>) => {
    const value = Number(params.value ?? 0)
    if (kind === 'unitPrice') return formatYen(value)
    return `${value}h`
  },
  cellClass: (params: CellClassParams<Record<string, unknown>>) => {
    if (!params.data || activeWorkProjectId.value === null) return ''
    const userId = Number(params.data.userId)
    if (!Number.isInteger(userId)) return ''
    return isS5DirtyCell(activeWorkProjectId.value, userId, monthKey, kind) ? 's5-cell-dirty' : ''
  }
})

const workColDefs = computed<Array<ColDef | ColGroupDef>>(() => [
  { field: 'member', headerName: 'メンバー', pinned: 'left', editable: false, minWidth: 180 },
  ...s5MonthKeys.value.map((monthKey) => ({
    headerName: formatMonthLabel(monthKey),
    marryChildren: true,
    children: [
      createS5ChildColumn(monthKey, 'hours'),
      createS5ChildColumn(monthKey, 'unitPrice')
    ]
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
const s4State = reactive({
  processing: false,
  restoring: false,
  pendingFile: null as File | null,
  selectedHistoryId: null as number | null
})
const toast = reactive({ show: false, type: 'success' as 'success' | 'error', message: '' })

const errors = reactive<Record<string, string>>({})
const dirty = ref(false)
const hasUnsavedChanges = computed(() => dirty.value || s5Edited.value)
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

function firstInertiaError(source: unknown, key: string) {
  if (!source || typeof source !== 'object') return ''
  const value = (source as Record<string, unknown>)[key]
  if (Array.isArray(value)) return typeof value[0] === 'string' ? value[0] : ''
  return typeof value === 'string' ? value : ''
}

function addAssignment() {
  clearErrors('s3')
  if (!isActiveAssignProject.value) {
    errors.s3 = '終了案件にはアサインを追加できません。'
    return
  }
  if (activeAssignProjectId.value === null) {
    errors.s3 = '対象案件を選択してください。'
    return
  }
  if (newAssign.userId === null) {
    errors.s3 = '未アサインメンバーを選択してください。'
    return
  }

  const nextRate = Number(newAssign.defaultUnitPrice)
  if (!Number.isInteger(nextRate) || nextRate < 0) {
    errors.s3 = 'デフォルト売上単価は0以上の整数で入力してください。'
    return
  }

  s3State.processingAdd = true
  suppressBeforeVisitGuard = true

  router.post('/project_members', {
    project_member: {
      project_id: activeAssignProjectId.value,
      user_id: newAssign.userId,
      default_billing_rate: nextRate
    }
  }, {
    preserveScroll: true,
    preserveState: true,
    onSuccess: () => {
      newAssign.userId = null
      newAssign.defaultUnitPrice = 6000
      clearErrors('s3')
    },
    onError: (serverErrors) => {
      errors.s3 = firstInertiaError(serverErrors, 'default_billing_rate') || firstInertiaError(serverErrors, 'user') || 'アサインを追加できませんでした。'
    },
    onFinish: () => {
      s3State.processingAdd = false
      suppressBeforeVisitGuard = false
    }
  })
}

function openAssignmentPriceModal(assignment: S3AssignmentRow) {
  if (!isActiveAssignProject.value) return
  s3PriceModal.assignmentId = assignment.id
  s3PriceModal.userLabel = assignment.userLabel
  s3PriceModal.rate = assignment.defaultUnitPrice
  s3PriceModal.error = ''
  s3PriceModal.open = true
}

function closeAssignmentPriceModal() {
  if (s3PriceModal.processing) return
  s3PriceModal.open = false
  s3PriceModal.assignmentId = null
  s3PriceModal.userLabel = ''
  s3PriceModal.rate = 0
  s3PriceModal.error = ''
}

function saveAssignmentPriceModal() {
  const assignmentId = s3PriceModal.assignmentId
  if (!isActiveAssignProject.value || assignmentId === null) return

  const nextRate = Number(s3PriceModal.rate)
  if (!Number.isInteger(nextRate) || nextRate < 0) {
    s3PriceModal.error = 'デフォルト売上単価は0以上の整数で入力してください。'
    return
  }

  s3PriceModal.error = ''
  s3PriceModal.processing = true
  suppressBeforeVisitGuard = true

  router.patch(`/project_members/${assignmentId}`, {
    project_member: {
      default_billing_rate: nextRate
    }
  }, {
    preserveScroll: true,
    preserveState: true,
    onSuccess: () => {
      s3PriceModal.processing = false
      closeAssignmentPriceModal()
    },
    onError: (serverErrors) => {
      s3PriceModal.error = firstInertiaError(serverErrors, 'default_billing_rate') || '単価を更新できませんでした。'
    },
    onFinish: () => {
      s3PriceModal.processing = false
      suppressBeforeVisitGuard = false
    }
  })
}

function unassignMember(assignment: S3AssignmentRow) {
  if (!isActiveAssignProject.value) return
  if (!window.confirm('アサイン解除してよろしいですか？')) return

  s3State.processingRemoveId = assignment.id
  suppressBeforeVisitGuard = true

  router.delete(`/project_members/${assignment.id}`, {
    preserveScroll: true,
    preserveState: true,
    onError: () => {
      errors.s3 = 'アサインを解除できませんでした。'
    },
    onFinish: () => {
      s3State.processingRemoveId = null
      suppressBeforeVisitGuard = false
    }
  })
}

function showToast(type: 'success' | 'error', message: string) {
  toast.show = true
  toast.type = type
  toast.message = message
  window.setTimeout(() => { toast.show = false }, 2500)
}

const csrfToken = () => {
  const token = document.querySelector('meta[name="csrf-token"]')
  return token instanceof HTMLMetaElement ? token.content : ''
}

const formatS4DiffMonths = (diffs: S4DiffRecord[] | undefined) => {
  if (!diffs || diffs.length === 0) return ''
  return diffs.map((item) => item.work_month).join(', ')
}

const reloadS4Data = (successMessage: string) => {
  return new Promise<void>((resolve) => {
    router.visit(window.location.pathname, {
      method: 'get',
      replace: true,
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => {
        showToast('success', successMessage)
        resolve()
      },
      onError: () => {
        errors.s4 = '会計データの再読込に失敗しました。画面を再読み込みしてください。'
        showToast('error', errors.s4)
        resolve()
      }
    })
  })
}

async function requestS4CsvImport(file: File, confirmOverwriteChanged: boolean): Promise<S4ImportResponse> {
  const formData = new FormData()
  formData.append('file', file)
  if (confirmOverwriteChanged) {
    formData.append('confirm_overwrite_changed', 'true')
  }

  const response = await fetch('/monthly_accounting_data_import', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': csrfToken()
    },
    body: formData,
    credentials: 'same-origin'
  })

  let body: S4ImportResponse
  try {
    body = await response.json() as S4ImportResponse
  } catch {
    throw new Error('CSV取り込みAPIの応答を解析できませんでした')
  }

  if (!response.ok || body.status === 'error') {
    const message = body.message || body.errors?.[0] || 'CSVを取り込めませんでした'
    throw new Error(message)
  }

  return body
}

async function requestS4Restore(historyId: number): Promise<S4RestoreResponse> {
  const response = await fetch(`/monthly_accounting_data_histories/${historyId}/restore`, {
    method: 'POST',
    headers: {
      'X-CSRF-Token': csrfToken()
    },
    credentials: 'same-origin'
  })

  let body: S4RestoreResponse
  try {
    body = await response.json() as S4RestoreResponse
  } catch {
    throw new Error('復元APIの応答を解析できませんでした')
  }

  if (!response.ok || body.status === 'error') {
    throw new Error(body.message || '会計データを復元できませんでした')
  }

  return body
}

async function processCsv(file: File) {
  clearErrors('s4')

  if (s4State.processing || s4State.restoring) return
  if (!file.name.toLowerCase().endsWith('.csv')) {
    errors.s4 = 'CSV形式のファイルを指定してください'
    showToast('error', errors.s4)
    return
  }

  s4State.pendingFile = file
  s4State.processing = true

  try {
    const firstResult = await requestS4CsvImport(file, false)

    if (firstResult.status === 'confirmation_required') {
      const diffMonths = formatS4DiffMonths(firstResult.diffs)
      const shouldOverwrite = window.confirm(
        `${firstResult.message ?? '同月データに差分があります。'}\n差分月: ${diffMonths || '不明'}`
      )

      if (!shouldOverwrite) {
        showToast('success', 'CSV取り込みを中止しました')
        return
      }

      if (!s4State.pendingFile) {
        errors.s4 = '確認後の再送に失敗しました。CSVを選択し直してください。'
        showToast('error', errors.s4)
        return
      }

      const confirmedResult = await requestS4CsvImport(s4State.pendingFile, true)
      await reloadS4Data(confirmedResult.message ?? '会計データを更新しました')
      return
    }

    await reloadS4Data(firstResult.message ?? '会計データを取り込みました')
  } catch (error) {
    const message = error instanceof Error ? error.message : 'CSVを取り込めませんでした'
    errors.s4 = message
    showToast('error', message)
  } finally {
    s4State.processing = false
    s4State.pendingFile = null
    if (csvInput.value) csvInput.value.value = ''
  }
}

async function restoreS4History() {
  clearErrors('s4')

  if (s4State.processing || s4State.restoring) return
  if (s4State.selectedHistoryId === null) {
    errors.s4 = '復元履歴を選択してください'
    return
  }

  if (!window.confirm('選択した履歴の状態に戻します。よろしいですか？')) return

  s4State.restoring = true

  try {
    const result = await requestS4Restore(s4State.selectedHistoryId)
    await reloadS4Data(result.message || '会計データを復元しました')
  } catch (error) {
    const message = error instanceof Error ? error.message : '会計データを復元できませんでした'
    errors.s4 = message
    showToast('error', message)
  } finally {
    s4State.restoring = false
  }
}

function onCsvPicked(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (file) void processCsv(file)
}

function onCsvDrop(event: DragEvent) {
  const file = event.dataTransfer?.files?.[0]
  if (file) void processCsv(file)
}

function onWorkGridReady(event: GridReadyEvent) {
  workGridApi.value = event.api
}

function applyS5ProjectSwitch(projectId: number) {
  isSwitchingS5Project.value = true
  activeWorkProjectId.value = projectId
  isSwitchingS5Project.value = false
}

function applyS5DisplayChange(selection: S5DisplaySelection) {
  clearS5DirtyCells()
  s5DisplayMode.value = selection.mode
  s5CalendarYear.value = selection.calendarYear
  s5FiscalYear.value = selection.fiscalYear
}

function promptS5UnsavedAction(): S5UnsavedAction {
  const answer = window.prompt(
    'S5に未保存の変更があります。\n1: 保存して切替\n2: 破棄して切替\n3: キャンセル',
    '3'
  )
  if (answer === '1') return 'save'
  if (answer === '2') return 'discard'
  return 'cancel'
}

function discardS5DraftAndRun(action: () => void) {
  rebuildWorkRowsByProject()
  dirty.value = false
  clearS5DirtyCells()
  clearErrors('s5')
  pendingS5ProjectId.value = null
  pendingS5DisplayChange.value = null
  action()
}

function confirmS5UnsavedAndRun(action: () => void, onSave: () => void) {
  if (!dirty.value && !s5Edited.value) {
    action()
    return
  }
  if (s5State.processing) return

  const decision = promptS5UnsavedAction()
  if (decision === 'save') {
    onSave()
    return
  }
  if (decision === 'discard') {
    discardS5DraftAndRun(action)
  }
}

function attemptSwitchS5Project(projectId: number) {
  if (isSwitchingS5Project.value) return
  if (activeWorkProjectId.value === projectId) return

  confirmS5UnsavedAndRun(
    () => {
      pendingS5ProjectId.value = null
      applyS5ProjectSwitch(projectId)
    },
    () => {
      pendingS5ProjectId.value = projectId
      pendingS5DisplayChange.value = null
      saveSection('s5')
    }
  )
}

function attemptChangeS5Display(selection: S5DisplaySelection) {
  if (
    selection.mode === s5DisplayMode.value &&
    selection.calendarYear === s5CalendarYear.value &&
    selection.fiscalYear === s5FiscalYear.value
  ) {
    return
  }

  confirmS5UnsavedAndRun(
    () => {
      pendingS5ProjectId.value = null
      pendingS5DisplayChange.value = null
      applyS5DisplayChange(selection)
    },
    () => {
      pendingS5DisplayChange.value = selection
      pendingS5ProjectId.value = null
      saveSection('s5')
    }
  )
}

function selectS5ClosedProject(projectId: string) {
  if (!projectId) return
  attemptSwitchS5Project(Number(projectId))
}

function onS5DisplayModeChanged(value: string) {
  const mode: S5DisplayMode = value === 'fiscal' ? 'fiscal' : 'calendar'
  attemptChangeS5Display({
    mode,
    calendarYear: s5CalendarYear.value,
    fiscalYear: s5FiscalYear.value
  })
}

function onS5CalendarYearChanged(value: string) {
  const year = Number(value)
  if (!Number.isInteger(year)) return
  attemptChangeS5Display({
    mode: 'calendar',
    calendarYear: year,
    fiscalYear: s5FiscalYear.value
  })
}

function onS5FiscalYearChanged(value: string) {
  const year = Number(value)
  if (!Number.isInteger(year)) return
  attemptChangeS5Display({
    mode: 'fiscal',
    calendarYear: s5CalendarYear.value,
    fiscalYear: year
  })
}

function resetS5DraftWithConfirm() {
  if (!s5Edited.value || s5State.processing) return

  const confirmed = window.confirm('未保存の変更を破棄して元の状態に戻します。よろしいですか？\nこの操作は保存されません。')
  if (!confirmed) return

  discardS5DraftAndRun(() => {})
}

function onWorkCellChanged(event: { colDef?: { field?: string }; data?: Record<string, unknown> }) {
  const field = event.colDef?.field
  const row = event.data
  if (!field || !row) {
    markDirty()
    return
  }

  const parsed = parseS5ChildField(field)
  if (!parsed) {
    markDirty()
    return
  }

  row[parsed.monthKey] = normalizeS5CellValue(row[parsed.monthKey])

  const projectId = Number(row.projectId ?? activeWorkProjectId.value)
  const userId = Number(row.userId)
  if (Number.isInteger(projectId) && Number.isInteger(userId)) {
    const currentValue = normalizeS5CellValue(row[parsed.monthKey])
    syncS5DirtyCell(projectId, userId, parsed.monthKey, parsed.kind, currentValue)
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
  if (section === 's5') {
    if (activeWorkProjectId.value === null) {
      errors.s5 = '対象案件を選択してください。'
      return false
    }
    if (!isActiveWorkProject.value) {
      errors.s5 = '終了案件は閲覧専用です。'
      return false
    }
    if (s5MonthKeys.value.length === 0) {
      errors.s5 = '保存対象の月データがありません。'
      return false
    }

    const rows = workRowsByProject[String(activeWorkProjectId.value)] ?? []
    const messages: string[] = []
    rows.forEach((row) => {
      const member = String(row.member ?? '不明メンバー')
      s5MonthKeys.value.forEach((monthKey) => {
        const value = normalizeS5CellValue(row[monthKey])
        if (!Number.isInteger(value.hours) || value.hours < 0 || value.hours > 999) {
          messages.push(`${member} ${formatMonthLabel(monthKey)} 稼働時間は0〜999の整数で入力してください`)
        }
        if (!Number.isInteger(value.unitPrice) || value.unitPrice < 0 || value.unitPrice > 99_999 || value.unitPrice % 10 !== 0) {
          messages.push(`${member} ${formatMonthLabel(monthKey)} 請求単価は0〜99,999の10円単位で入力してください`)
        }
      })
    })
    if (messages.length > 0) {
      errors.s5 = messages.slice(0, 5).join('\n')
      return false
    }
    return true
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
  if (section === 's5') {
    void submitS5()
    return
  }
  if (section === 's10') {
    persistBillingAdjustments()
  }
  showToast('success', `${section.toUpperCase()} を保存しました`)
  dirty.value = false
}

function submitS5() {
  if (activeWorkProjectId.value === null) return

  const rows = workRowsByProject[String(activeWorkProjectId.value)] ?? []
  const entries = rows.flatMap((row) => {
    const userId = Number(row.userId)
    if (!Number.isInteger(userId)) return []
    return s5MonthKeys.value.map((monthKey) => {
      const value = normalizeS5CellValue(row[monthKey])
      return {
        user_id: userId,
        work_month: monthKey,
        billed_hours: value.hours,
        billing_rate: value.unitPrice
      }
    })
  })

  s5State.processing = true
  suppressBeforeVisitGuard = true
  clearErrors('s5')

  router.post('/billing_work_logs/bulk_upsert', {
    project_id: activeWorkProjectId.value,
    entries
  }, {
    preserveScroll: true,
    preserveState: true,
    onSuccess: () => {
      dirty.value = false
      clearS5DirtyCells()
      clearErrors('s5')

      if (pendingS5DisplayChange.value) {
        const nextDisplay = pendingS5DisplayChange.value
        pendingS5DisplayChange.value = null
        applyS5DisplayChange(nextDisplay)
      }

      if (pendingS5ProjectId.value !== null) {
        const nextProjectId = pendingS5ProjectId.value
        pendingS5ProjectId.value = null
        applyS5ProjectSwitch(nextProjectId)
      }
    },
    onError: (serverErrors) => {
      errors.s5 = firstInertiaError(serverErrors, 'entries') ||
        firstInertiaError(serverErrors, 'project') ||
        firstInertiaError(serverErrors, 'billing_rate') ||
        firstInertiaError(serverErrors, 'billed_hours') ||
        firstInertiaError(serverErrors, 'work_month') ||
        firstInertiaError(serverErrors, 'user_id') ||
        'S5を保存できませんでした。'
    },
    onFinish: () => {
      s5State.processing = false
      suppressBeforeVisitGuard = false
    }
  })
}

const beforeUnload = (event: BeforeUnloadEvent) => {
  if (!hasUnsavedChanges.value) return
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
    if (!hasUnsavedChanges.value) return
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

watch(s5CalendarYears, (years) => {
  if (years.length === 0) return
  if (!years.includes(s5CalendarYear.value)) {
    s5CalendarYear.value = years[years.length - 1]
  }
}, { immediate: true })

watch(s5FiscalYears, (years) => {
  if (years.length === 0) return
  if (!years.includes(s5FiscalYear.value)) {
    s5FiscalYear.value = years[years.length - 1]
  }
}, { immediate: true })

watch(
  () => props.projects,
  (nextProjects) => {
    syncSection2Projects()

    if (nextProjects.length === 0) {
      activeAssignProjectId.value = null
      activeWorkProjectId.value = null
      return
    }

    if (
      activeAssignProjectId.value === null ||
      !nextProjects.some((project) => project.id === activeAssignProjectId.value)
    ) {
      activeAssignProjectId.value = pickDefaultAssignProjectId(nextProjects)
    }

    if (
      activeWorkProjectId.value === null ||
      !nextProjects.some((project) => project.id === activeWorkProjectId.value)
    ) {
      activeWorkProjectId.value = pickDefaultWorkProjectId(nextProjects)
    }
  },
  { deep: true }
)

watch(
  () => props.project_members,
  (nextProjectMembers) => {
    if (
      s3PriceModal.assignmentId !== null &&
      !nextProjectMembers.some((assignment) => assignment.id === s3PriceModal.assignmentId)
    ) {
      closeAssignmentPriceModal()
    }
  },
  { deep: true }
)

watch(
  [() => props.project_members, () => props.billing_work_logs, () => props.s5_month_keys, () => props.projects, () => props.users],
  () => {
    rebuildWorkRowsByProject()
  },
  { deep: true }
)

watch([s5DisplayMode, s5CalendarYear, s5FiscalYear], () => {
  rebuildWorkRowsByProject()
})

watch(
  () => props.monthly_accounting_histories,
  (histories) => {
    if (histories.length === 0) {
      s4State.selectedHistoryId = null
      return
    }

    if (
      s4State.selectedHistoryId === null ||
      !histories.some((history) => history.id === s4State.selectedHistoryId)
    ) {
      s4State.selectedHistoryId = histories[0]?.id ?? null
    }
  },
  { immediate: true, deep: true }
)

watch([users, projects, expenses, adjustments, memberCostRows, officerCostRows], () => {
  if (skipDirtyTracking) return
  markDirty()
}, { deep: true })

</script>
