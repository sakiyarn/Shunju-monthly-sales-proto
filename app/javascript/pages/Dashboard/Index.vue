<template>
  <main class="dashboard-page">
    <section class="dashboard-shell">
      <header class="dashboard-header">
        <div>
          <h1 class="dashboard-title">財務ダッシュボード</h1>
          <p class="dashboard-subtitle">受託開発の月次収益・利益率を閲覧専用で確認</p>
        </div>
      </header>

      <nav class="tab-nav" aria-label="ダッシュボードタブ">
        <button v-for="tab in tabs" :key="tab.id" class="tab-btn" :class="{ 'tab-btn-active': activeTab === tab.id }"
          type="button" @click="activeTab = tab.id">
          {{ tab.label }}
        </button>
      </nav>

      <section v-if="activeTab === 'workHours'" class="tab-panel">
        <div class="work-hours-controls">
          <div class="work-hours-filter-box">
            <div class="work-hours-filter-group">
              <span class="work-hours-filter-label">案件</span>
              <div class="work-hours-filter-buttons">
                <button v-for="projectName in projects" :key="`work-filter-${projectName}`"
                  class="work-hours-filter-btn"
                  :class="{ 'work-hours-filter-btn-active': isWorkHoursProjectVisible(projectName) }" type="button"
                  @click="toggleWorkHoursProject(projectName)">
                  {{ projectName }}
                </button>
              </div>
            </div>

            <div class="work-hours-filter-group">
              <span class="work-hours-filter-label">メンバー</span>
              <div class="work-hours-filter-buttons">
                <button v-for="memberName in members" :key="`work-member-filter-${memberName}`"
                  class="work-hours-filter-btn work-hours-member-filter-btn"
                  :class="{ 'work-hours-member-filter-btn-active': selectedWorkHoursMember === memberName }"
                  type="button" @click="toggleWorkHoursMember(memberName)">
                  {{ memberName }}
                </button>
              </div>
            </div>
          </div>
          <div ref="workHoursScaleMenuWrapRef" class="work-hours-scale-control">
            <span>表示倍率</span>
            <button class="work-hours-scale-trigger" type="button" aria-label="表示倍率選択"
              @click="workHoursScaleMenuOpen = !workHoursScaleMenuOpen">
              {{ workHoursScale }}%
            </button>
            <div v-if="workHoursScaleMenuOpen" class="work-hours-scale-menu">
              <button v-for="scale in workHoursScaleOptions" :key="`scale-${scale}`" class="work-hours-scale-option"
                :class="{ 'work-hours-scale-option-active': workHoursScale === scale }" type="button"
                @click="setWorkHoursScale(scale)">
                {{ scale }}%
              </button>
            </div>
          </div>
        </div>
        <div class="work-hours-stage">
          <div class="work-hours-zoom" :style="workHoursScaleStyle">
            <div class="ag-theme-quartz grid-shell grid-shell-hours">
              <AgGridVue class="h-full w-full work-hours-grid" :columnDefs="workHoursColumnDefs"
                :rowData="filteredWorkHoursRows" :defaultColDef="readOnlyColDef" :animateRows="false" :rowHeight="34"
                :headerHeight="34" :groupHeaderHeight="34" :getRowClass="getWorkHoursRowClass" />
            </div>
          </div>
        </div>
      </section>

      <section v-else-if="activeTab === 'budget'" class="tab-panel">
        <div class="panel-header">
          <h2>予算収支表</h2>
        </div>
        <div class="ag-theme-quartz grid-shell grid-shell-md">
          <AgGridVue class="h-full w-full" :columnDefs="budgetColumnDefs" :rowData="budgetRows"
            :defaultColDef="readOnlyColDef" :animateRows="false" :getRowClass="getBudgetRowClass" />
        </div>
      </section>

      <section v-else-if="activeTab === 'memberSales'" class="tab-panel">
        <div class="panel-header panel-header-split">
          <h2>メンバー別売上内訳</h2>
          <div class="member-sales-header-controls">
            <div class="member-sales-filter-group" aria-label="メンバー別売上内訳のメンバーフィルタ">
              <span class="work-hours-filter-label">メンバー</span>
              <div class="member-sales-filter-buttons">
                <button v-for="memberName in allPeople" :key="`member-sales-filter-${memberName}`"
                  class="work-hours-filter-btn"
                  :class="{ 'work-hours-member-filter-btn-active': isMemberSalesMemberSelected(memberName) }"
                  type="button" @click="toggleMemberSalesMember(memberName)">
                  {{ memberName }}
                </button>
              </div>
            </div>

            <div class="member-sales-scale-control" aria-label="メンバー別売上内訳の表示倍率">
              <span>表示倍率</span>
              <div class="member-sales-scale-buttons">
                <button v-for="scale in memberSalesScaleOptions" :key="`member-sales-scale-${scale}`"
                  class="member-sales-scale-btn"
                  :class="{ 'member-sales-scale-btn-active': memberSalesScale === scale }" type="button"
                  @click="setMemberSalesScale(scale)">
                  {{ scale }}%
                </button>
              </div>
            </div>
          </div>
        </div>
        <div class="member-sales-stage">
          <div class="member-sales-zoom" :style="memberSalesScaleStyle">
            <div class="ag-theme-quartz grid-shell grid-shell-member-sales">
              <AgGridVue class="h-full w-full" :columnDefs="memberSalesColumnDefs" :rowData="filteredMemberSalesRows"
                :defaultColDef="readOnlyColDef" :animateRows="false" :tooltipShowDelay="120"
                :getRowClass="getMemberSalesRowClass" />
            </div>
          </div>
        </div>
      </section>

      <section v-else-if="activeTab === 'memberChart'" class="tab-panel">
        <div class="panel-header">
          <h2>メンバー別売上グラフ</h2>
        </div>
        <div class="chart-layout">
          <article class="chart-card chart-card-large">
            <div class="chart-card-head chart-card-head-wrap">
              <h3>月次売上推移（積み上げ）</h3>
              <div class="member-chart-controls" aria-label="月次売上推移の表示期間設定">
                <select v-model="memberChartRangeMode" class="period-select" aria-label="表示期間モード">
                  <option value="period">期で表示</option>
                  <option value="year">年度で表示</option>
                  <option value="custom">月範囲で表示</option>
                </select>

                <select v-if="memberChartRangeMode === 'period'" v-model.number="selectedMemberChartPeriod"
                  class="period-select" aria-label="期選択">
                  <option v-for="option in memberChartPeriodOptions" :key="`member-chart-period-${option.value}`"
                    :value="option.value" :disabled="!option.available">
                    {{ option.label }}{{ option.available ? '' : '（データなし）' }}
                  </option>
                </select>

                <select v-else-if="memberChartRangeMode === 'year'" v-model.number="selectedMemberChartYear"
                  class="period-select" aria-label="年度選択">
                  <option v-for="year in memberChartYearOptions" :key="`member-chart-year-${year}`" :value="year">
                    {{ year }}年度
                  </option>
                </select>

                <div v-else class="member-chart-custom-range">
                  <select v-model="memberChartRangeFrom" class="period-select" aria-label="表示開始月">
                    <option v-for="month in allMonths" :key="`member-chart-from-${month.key}`" :value="month.key">
                      {{ month.label }}
                    </option>
                  </select>
                  <span class="member-chart-range-separator">〜</span>
                  <select v-model="memberChartRangeTo" class="period-select" aria-label="表示終了月">
                    <option v-for="month in allMonths" :key="`member-chart-to-${month.key}`" :value="month.key">
                      {{ month.label }}
                    </option>
                  </select>
                </div>
              </div>
            </div>
            <div ref="memberStackedChartEl" class="chart-canvas chart-canvas-large" />
          </article>

          <article class="chart-card chart-card-small">
            <div class="chart-card-head chart-card-head-wrap">
              <h3>選択月の売上構成比</h3>
              <div class="member-chart-controls" aria-label="売上構成比の表示設定">
                <select v-model="selectedDonutMonth" class="period-select donut-select" aria-label="ドーナツ対象月選択">
                  <option v-for="month in memberChartVisibleMonths" :key="`donut-${month.key}`" :value="month.key">
                    {{ month.label }}
                  </option>
                </select>
                <select v-model="memberDonutSortMode" class="period-select" aria-label="売上構成比の並び順">
                  <option value="shareDesc">割合が大きい順</option>
                  <option value="roleOrder">役職順（代表A/B優先）</option>
                </select>
              </div>
            </div>
            <div ref="memberDonutChartEl" class="chart-canvas chart-canvas-small" />
          </article>
        </div>
      </section>

      <section v-else class="tab-panel">
        <div class="panel-header">
          <h2>営業利益率（ボーナス達成トラッカー）</h2>
        </div>

        <div class="kpi-grid">
          <article class="kpi-card">
            <p class="kpi-label">先月の営業利益率</p>
            <p class="kpi-value">{{ formatPercent(kpiLastMonthMargin) }}</p>
            <p class="kpi-note">{{ kpiLastMonthLabel }}</p>
          </article>

          <article class="kpi-card">
            <p class="kpi-label">前月比（先々月比）</p>
            <p class="kpi-value" :class="monthOverMonthDiff >= 0 ? 'kpi-positive' : 'kpi-negative'">
              {{ monthOverMonthDiff >= 0 ? '▲' : '▼' }} {{ formatSignedPercent(monthOverMonthDiff) }}
            </p>
            <p class="kpi-note">{{ kpiPreviousMonthLabel }} 比較</p>
          </article>

          <article class="kpi-card">
            <p class="kpi-label">対前年同月比</p>
            <p class="kpi-value" :class="yearOverYearDiff >= 0 ? 'kpi-positive' : 'kpi-negative'">
              {{ yearOverYearDiff >= 0 ? '▲' : '▼' }} {{ formatSignedPercent(yearOverYearDiff) }}
            </p>
            <p class="kpi-note">{{ kpiPreviousYearLabel }} 比較</p>
          </article>
        </div>

        <article class="tracker-card">
          <div class="tracker-head">
            <h3>{{ halfYearRangeLabel }}</h3>
            <span class="tracker-badge" :class="trackerBadgeClass">{{ trackerBadgeLabel }}</span>
          </div>

          <div class="tracker-period-controls" aria-label="半期切替">
            <button v-for="period in halfYearPeriods" :key="`tracker-period-${period.id}`" class="tracker-period-btn"
              :class="{ 'tracker-period-btn-active': selectedHalfYearPeriodId === period.id }" type="button"
              @click="selectedHalfYearPeriodId = period.id">
              {{ period.label }}
            </button>
          </div>

          <div class="tracker-meter-wrap">
            <div class="tracker-meter">
              <span class="tracker-target-line" :style="{ left: `${bonusTargetPosition}%` }" />
              <span class="tracker-fill" :style="{ width: `${trackerFillWidth}%`, backgroundColor: trackerColor }" />
            </div>
            <div class="tracker-scale">
              <span>0%</span>
              <span>20%</span>
              <span>25%</span>
              <span>40%</span>
            </div>
          </div>

          <div class="tracker-summary">
            <p>半期累計売上: <strong>{{ formatYen(halfYearSalesTotal) }}</strong></p>
            <p>半期累計営業利益: <strong>{{ formatYen(halfYearProfitTotal) }}</strong></p>
            <p>半期累計営業利益率: <strong>{{ formatPercent(halfYearProfitRate) }}</strong></p>
          </div>

          <div class="tracker-table-wrap">
            <table class="tracker-table">
              <thead>
                <tr>
                  <th>月</th>
                  <th>売上</th>
                  <th>営業利益</th>
                  <th>利益率</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in halfYearTableRows" :key="`half-${row.key}`">
                  <td>{{ monthLabelForTable(row.key) }}</td>
                  <td>{{ formatYen(row.sales) }}</td>
                  <td>{{ formatYen(row.profit) }}</td>
                  <td>{{ formatPercent(row.margin) }}</td>
                </tr>
                <tr class="tracker-table-total">
                  <td>累計</td>
                  <td>{{ formatYen(halfYearSalesTotal) }}</td>
                  <td>{{ formatYen(halfYearProfitTotal) }}</td>
                  <td>{{ formatPercent(halfYearProfitRate) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </article>

        <article class="chart-card chart-card-full">
          <h3>月次営業利益率 推移</h3>
          <div ref="profitTrendChartEl" class="chart-canvas chart-canvas-large" />
        </article>
      </section>
    </section>
  </main>
</template>

<script setup lang="ts">
import { AgGridVue } from 'ag-grid-vue3'
import type {
  CellClassParams,
  ColDef,
  ColGroupDef,
  ICellRendererParams,
  RowClassParams,
  ValueFormatterParams
} from 'ag-grid-community'
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import * as echarts from 'echarts'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'

const props = defineProps<{
  initialData?: Record<string, unknown>
  projects: Array<{ id: number; name: string; is_active: boolean; display_order: number }>
  users: Array<{ id: number; name: string; display_name: string; is_active: boolean; system_role: string }>
}>()

type DashboardTabId = 'workHours' | 'budget' | 'memberSales' | 'memberChart' | 'profitTracker'
type WorkHoursRowType = 'projectHeader' | 'member' | 'subtotal'
type MemberSalesRowType = 'memberHeader' | 'project' | 'subtotal'
type MemberChartRangeMode = 'period' | 'year' | 'custom'
type MemberDonutSortMode = 'shareDesc' | 'roleOrder'

interface MonthDef {
  key: string
  label: string
  shortLabel: string
  year: number
  month: number
  period: string
  fiscalYear: number
}

interface WorkHoursRow {
  projectName: string
  displayName: string
  leftLabel: string
  rowType: WorkHoursRowType
  [key: string]: string | number | null
}

interface BudgetRow {
  item: string
  [key: string]: string | number
}

interface MemberSalesRow {
  memberName: string
  displayName: string
  leftLabel: string
  rowType: MemberSalesRowType
  [key: string]: string | number | null
}

interface SalesCellDetail {
  billedHours: number
  billingRate: number
  baseRevenue: number
  adjustment: number
  memo?: string
  totalRevenue: number
}

interface PersistedBillingAdjustment {
  userId?: string
  userName?: string
  projectId?: string
  projectName?: string
  fromMonth?: string
  toMonth?: string
  amount?: number
  memo?: string
}

interface ProfitMonthData {
  key: string
  sales: number
  profit: number
  previousYearMargin: number
}

interface HalfYearPeriod {
  id: string
  label: string
  startKey: string
  endKey: string
  monthKeys: string[]
}

const tabs: Array<{ id: DashboardTabId; label: string }> = [
  { id: 'workHours', label: '案件別稼働時間' },
  { id: 'budget', label: '予算収支表' },
  { id: 'memberSales', label: 'メンバー別売上内訳' },
  { id: 'memberChart', label: 'メンバー別売上グラフ' },
  { id: 'profitTracker', label: '営業利益率（ボーナス達成トラッカー）' }
]

const activeTab = ref<DashboardTabId>('workHours')

const allMonths: MonthDef[] = [
  { key: '2025-08', label: '2025年8月', shortLabel: '8月', year: 2025, month: 8, period: '第3期', fiscalYear: 2025 },
  { key: '2025-09', label: '2025年9月', shortLabel: '9月', year: 2025, month: 9, period: '第3期', fiscalYear: 2025 },
  { key: '2025-10', label: '2025年10月', shortLabel: '10月', year: 2025, month: 10, period: '第3期', fiscalYear: 2025 },
  { key: '2025-11', label: '2025年11月', shortLabel: '11月', year: 2025, month: 11, period: '第3期', fiscalYear: 2025 },
  { key: '2025-12', label: '2025年12月', shortLabel: '12月', year: 2025, month: 12, period: '第3期', fiscalYear: 2025 },
  { key: '2026-01', label: '2026年1月', shortLabel: '1月', year: 2026, month: 1, period: '第4期', fiscalYear: 2025 },
  { key: '2026-02', label: '2026年2月', shortLabel: '2月', year: 2026, month: 2, period: '第4期', fiscalYear: 2025 }
]

const monthLookup = new Map(allMonths.map((month) => [month.key, month]))
const visibleMonths = computed(() => allMonths)

const visibleMonthKeys = computed(() => visibleMonths.value.map((month) => month.key))

const formatYen = (value: number) => {
  return new Intl.NumberFormat('ja-JP', {
    style: 'currency',
    currency: 'JPY',
    maximumFractionDigits: 0
  }).format(value)
}

const formatSignedYen = (value: number) => {
  const abs = formatYen(Math.abs(value))
  return value < 0 ? `-${abs}` : `+${abs}`
}

const formatPercent = (value: number) => `${value.toFixed(1)}%`
const formatSignedPercent = (value: number) => `${value >= 0 ? '+' : ''}${value.toFixed(1)}%`

const readOnlyColDef: ColDef = {
  editable: false,
  sortable: false,
  filter: false,
  resizable: true,
  suppressHeaderMenuButton: true,
  cellStyle: {
    textAlign: 'right',
    fontVariantNumeric: 'tabular-nums'
  }
}

const seededInt = (seed: string, min: number, max: number) => {
  let hash = 2166136261
  for (let index = 0; index < seed.length; index += 1) {
    hash ^= seed.charCodeAt(index)
    hash = Math.imul(hash, 16777619)
  }
  const range = max - min + 1
  const normalized = Math.abs(hash) % range
  return min + normalized
}

const projectNames = props.projects.map((p) => p.name)
const projects = projectNames
const members = props.users
  .map((user) => user.display_name || user.name)

const executives = props.users
  .filter((user) => user.system_role === 'admin')
  .map((user) => user.display_name || user.name)

const allPeople = [...new Set([...members, ...executives])]
const allMonthIndexByKey = new Map(allMonths.map((month, index) => [month.key, index]))
const memberRoleOrder = ['代表A', '代表B', '三千人将A', '千人将A', '三百人将A', '百人将A', '什長A', '什長B', '什長C', '什長D']
const memberRoleOrderIndex = new Map(memberRoleOrder.map((name, index) => [name, index]))
const getMemberRoleRank = (name: string) => memberRoleOrderIndex.get(name) ?? memberRoleOrder.length

const memberChartRangeMode = ref<MemberChartRangeMode>('period')
const memberChartPeriodOptions = computed(() => {
  return [1, 2, 3, 4].map((periodNumber) => {
    const periodLabel = `第${periodNumber}期`
    return {
      value: periodNumber,
      label: periodLabel,
      available: allMonths.some((month) => month.period === periodLabel)
    }
  })
})
const initialMemberChartPeriod = memberChartPeriodOptions.value.find((option) => option.available)?.value ?? 1
const selectedMemberChartPeriod = ref<number>(initialMemberChartPeriod)
const memberChartYearOptions = [...new Set(allMonths.map((month) => month.year))].sort((a, b) => a - b)
const selectedMemberChartYear = ref<number>(memberChartYearOptions[0] ?? allMonths[0].year)
const memberChartRangeFrom = ref<string>(allMonths[0].key)
const memberChartRangeTo = ref<string>(allMonths[allMonths.length - 1].key)
const memberDonutSortMode = ref<MemberDonutSortMode>('shareDesc')

const memberChartVisibleMonths = computed<MonthDef[]>(() => {
  if (memberChartRangeMode.value === 'period') {
    const periodLabel = `第${selectedMemberChartPeriod.value}期`
    return allMonths.filter((month) => month.period === periodLabel)
  }

  if (memberChartRangeMode.value === 'year') {
    return allMonths.filter((month) => month.year === selectedMemberChartYear.value)
  }

  const fromIndex = allMonthIndexByKey.get(memberChartRangeFrom.value) ?? -1
  const toIndex = allMonthIndexByKey.get(memberChartRangeTo.value) ?? -1
  if (fromIndex < 0 || toIndex < 0) return allMonths

  const start = Math.min(fromIndex, toIndex)
  const end = Math.max(fromIndex, toIndex)
  return allMonths.slice(start, end + 1)
})
const memberChartVisibleMonthKeys = computed(() => memberChartVisibleMonths.value.map((month) => month.key))

const projectParticipants: Record<string, string[]> = {
  案件001: ['三千人将A', '千人将A', '三百人将A', '百人将A', '什長A', '代表A'],
  案件002: ['三千人将A', '千人将A', '什長B', '什長C', '什長D', '代表B'],
  案件003: ['三百人将A', '百人将A', '什長A', '什長B', '什長C', '什長D', '代表A', '代表B']
}
const workHoursMonths: MonthDef[] = [
  { key: '2025-01', label: '2025年1月', shortLabel: '1月', year: 2025, month: 1, period: '第2期', fiscalYear: 2025 },
  { key: '2025-02', label: '2025年2月', shortLabel: '2月', year: 2025, month: 2, period: '第2期', fiscalYear: 2025 },
  { key: '2025-03', label: '2025年3月', shortLabel: '3月', year: 2025, month: 3, period: '第2期', fiscalYear: 2025 },
  { key: '2025-04', label: '2025年4月', shortLabel: '4月', year: 2025, month: 4, period: '第2期', fiscalYear: 2025 },
  { key: '2025-05', label: '2025年5月', shortLabel: '5月', year: 2025, month: 5, period: '第2期', fiscalYear: 2025 },
  { key: '2025-06', label: '2025年6月', shortLabel: '6月', year: 2025, month: 6, period: '第2期', fiscalYear: 2025 },
  { key: '2025-07', label: '2025年7月', shortLabel: '7月', year: 2025, month: 7, period: '第2期', fiscalYear: 2025 },
  { key: '2025-08', label: '2025年8月', shortLabel: '8月', year: 2025, month: 8, period: '第3期', fiscalYear: 2025 },
  { key: '2025-09', label: '2025年9月', shortLabel: '9月', year: 2025, month: 9, period: '第3期', fiscalYear: 2025 },
  { key: '2025-10', label: '2025年10月', shortLabel: '10月', year: 2025, month: 10, period: '第3期', fiscalYear: 2025 },
  { key: '2025-11', label: '2025年11月', shortLabel: '11月', year: 2025, month: 11, period: '第3期', fiscalYear: 2025 },
  { key: '2025-12', label: '2025年12月', shortLabel: '12月', year: 2025, month: 12, period: '第3期', fiscalYear: 2025 },
  { key: '2026-01', label: '2026年1月', shortLabel: '1月', year: 2026, month: 1, period: '第4期', fiscalYear: 2025 },
  { key: '2026-02', label: '2026年2月', shortLabel: '2月', year: 2026, month: 2, period: '第4期', fiscalYear: 2025 },
  { key: '2026-03', label: '2026年3月', shortLabel: '3月', year: 2026, month: 3, period: '第4期', fiscalYear: 2025 },
  { key: '2026-04', label: '2026年4月', shortLabel: '4月', year: 2026, month: 4, period: '第4期', fiscalYear: 2025 },
  { key: '2026-05', label: '2026年5月', shortLabel: '5月', year: 2026, month: 5, period: '第4期', fiscalYear: 2025 },
  { key: '2026-06', label: '2026年6月', shortLabel: '6月', year: 2026, month: 6, period: '第4期', fiscalYear: 2025 },
  { key: '2026-07', label: '2026年7月', shortLabel: '7月', year: 2026, month: 7, period: '第4期', fiscalYear: 2025 }
]
const hasWorkHoursDummyValue = (monthKey: string) => monthKey >= '2025-08' && monthKey <= '2026-01'
const workHoursScaleOptions = [100, 90, 80, 70]
const workHoursScale = ref(100)
const workHoursScaleMenuOpen = ref(false)
const workHoursScaleMenuWrapRef = ref<HTMLElement | null>(null)
const memberSalesScaleOptions = [100, 90, 80, 70]
const memberSalesScale = ref(100)
const memberSalesMemberFilter = ref<Record<string, boolean>>(
  allPeople.reduce<Record<string, boolean>>((acc, memberName) => {
    acc[memberName] = false
    return acc
  }, {})
)
const setWorkHoursScale = (scale: number) => {
  workHoursScale.value = scale
  workHoursScaleMenuOpen.value = false
}
const setMemberSalesScale = (scale: number) => {
  memberSalesScale.value = scale
}
const isMemberSalesMemberSelected = (memberName: string) => Boolean(memberSalesMemberFilter.value[memberName])
const toggleMemberSalesMember = (memberName: string) => {
  memberSalesMemberFilter.value[memberName] = !memberSalesMemberFilter.value[memberName]
}
const workHoursScaleStyle = computed(() => {
  const ratio = workHoursScale.value / 100
  return {
    transform: `scale(${ratio})`,
    transformOrigin: 'top left'
  }
})
const memberSalesScaleStyle = computed(() => {
  const ratio = memberSalesScale.value / 100
  return {
    transform: `scale(${ratio})`,
    transformOrigin: 'top left',
    width: `${100 / ratio}%`,
    height: `${100 / ratio}%`
  }
})
const workHoursProjectVisible = ref<Record<string, boolean>>(
  projects.reduce<Record<string, boolean>>((acc, projectName) => {
    acc[projectName] = true
    return acc
  }, {})
)
const selectedWorkHoursMember = ref<string | null>(null)
const toggleWorkHoursProject = (projectName: string) => {
  workHoursProjectVisible.value[projectName] = !workHoursProjectVisible.value[projectName]
}
const isWorkHoursProjectVisible = (projectName: string) => Boolean(workHoursProjectVisible.value[projectName])
const toggleWorkHoursMember = (memberName: string) => {
  selectedWorkHoursMember.value = selectedWorkHoursMember.value === memberName ? null : memberName
}

const buildWorkHoursRows = (): WorkHoursRow[] => {
  const rows: WorkHoursRow[] = []

  projects.forEach((projectName) => {
    const headerRow: WorkHoursRow = {
      projectName,
      displayName: projectName,
      leftLabel: projectName,
      rowType: 'projectHeader'
    }
    workHoursMonths.forEach((month) => {
      headerRow[month.key] = null
    })

    const memberRows = (projectParticipants[projectName] ?? []).map((memberName) => {
      const row: WorkHoursRow = {
        projectName,
        displayName: memberName,
        leftLabel: memberName,
        rowType: 'member'
      }

      workHoursMonths.forEach((month) => {
        row[month.key] = hasWorkHoursDummyValue(month.key)
          ? seededInt(`${projectName}:${memberName}:${month.key}:hours`, 10, 80)
          : null
      })

      return row
    })

    const subtotalRow: WorkHoursRow = {
      projectName,
      displayName: '合計時間',
      leftLabel: '合計時間',
      rowType: 'subtotal'
    }

    workHoursMonths.forEach((month) => {
      subtotalRow[month.key] = hasWorkHoursDummyValue(month.key)
        ? memberRows.reduce((sum, row) => sum + Number(row[month.key] ?? 0), 0)
        : null
    })

    rows.push(headerRow, ...memberRows, subtotalRow)
  })

  return rows
}

const workHoursRows = buildWorkHoursRows()
const filteredWorkHoursRows = computed(() => {
  const visibleProjects = new Set(
    projects.filter((projectName) => isWorkHoursProjectVisible(projectName))
  )
  const selectedMember = selectedWorkHoursMember.value

  if (!selectedMember) {
    return workHoursRows.filter((row) => visibleProjects.has(row.projectName))
  }

  const visibleProjectsForMember = new Set(
    projects.filter((projectName) => {
      return visibleProjects.has(projectName) && (projectParticipants[projectName] ?? []).includes(selectedMember)
    })
  )

  return workHoursRows.filter((row) => {
    if (!visibleProjectsForMember.has(row.projectName)) return false
    if (row.rowType === 'projectHeader') return true
    if (row.rowType === 'member') return row.displayName === selectedMember
    return false
  })
})

const buildWorkHoursMonthGroups = (): ColGroupDef<WorkHoursRow>[] => {
  const periodBuckets = new Map<string, MonthDef[]>()

  workHoursMonths.forEach((month) => {
    const bucket = periodBuckets.get(month.period) ?? []
    bucket.push(month)
    periodBuckets.set(month.period, bucket)
  })

  return [...periodBuckets.entries()].map(([period, monthsInPeriod]) => {
    const yearBuckets = new Map<number, MonthDef[]>()

    monthsInPeriod.forEach((month) => {
      const yearMonths = yearBuckets.get(month.year) ?? []
      yearMonths.push(month)
      yearBuckets.set(month.year, yearMonths)
    })

    return {
      headerName: period,
      children: [...yearBuckets.entries()].map(([year, monthsInYear]) => ({
        headerName: `${year}年`,
        children: monthsInYear.map((month): ColDef<WorkHoursRow> => ({
          field: month.key,
          headerName: month.shortLabel,
          minWidth: 78,
          width: 82,
          maxWidth: 90,
          valueFormatter: (params: ValueFormatterParams<WorkHoursRow>) => {
            if (params.data?.rowType === 'projectHeader' || params.value === null || params.value === undefined) return ''
            return String(Number(params.value))
          },
          cellClass: (params) => {
            return params.data?.rowType === 'subtotal' ? 'cell-subtotal' : ''
          }
        }))
      }))
    }
  })
}

const workHoursColumnDefs = computed<Array<ColDef<WorkHoursRow> | ColGroupDef<WorkHoursRow>>>(() => [
  {
    field: 'leftLabel',
    headerName: '案件 / メンバー',
    pinned: 'left',
    minWidth: 170,
    width: 180,
    maxWidth: 220,
    cellClass: (params) => {
      if (params.data?.rowType === 'projectHeader') return 'cell-group-label'
      return params.data?.rowType === 'subtotal' ? 'cell-subtotal-label' : 'cell-member-label'
    },
    cellStyle: {
      textAlign: 'left'
    }
  },
  ...buildWorkHoursMonthGroups()
])

const getWorkHoursRowClass = (params: RowClassParams<WorkHoursRow>) => {
  if (params.data?.rowType === 'projectHeader') return 'row-group-header'
  if (params.data?.rowType === 'subtotal') return 'row-subtotal'
  return ''
}

const budgetSeeds = {
  sales: [2662000, 2107000, 2621000, 2231000, 2729500, 2400000, 2550000],
  grossProfit: [1800000, 1500000, 1750000, 1600000, 1850000, 1700000, 1780000],
  promotionCost: [400000, 350000, 420000, 380000, 410000, 390000, 400000],
  executiveNonWorking: [150000, 120000, 140000, 130000, 145000, 135000, 140000]
}

const budgetByMonth = new Map<string, { sales: number; grossProfit: number; promotionCost: number; executiveNonWorking: number; operatingProfit: number }>()

allMonths.forEach((month, index) => {
  const sales = budgetSeeds.sales[index] ?? 0
  const grossProfit = budgetSeeds.grossProfit[index] ?? 0
  const promotionCost = budgetSeeds.promotionCost[index] ?? 0
  const executiveNonWorking = budgetSeeds.executiveNonWorking[index] ?? 0
  const operatingProfit = sales - grossProfit - promotionCost - executiveNonWorking

  budgetByMonth.set(month.key, {
    sales,
    grossProfit,
    promotionCost,
    executiveNonWorking,
    operatingProfit
  })
})

const budgetRows = computed<BudgetRow[]>(() => {
  const createRow = (
    label: string,
    getter: (data: { sales: number; grossProfit: number; promotionCost: number; executiveNonWorking: number; operatingProfit: number }) => number
  ) => {
    const row: BudgetRow = { item: label }
    allMonths.forEach((month) => {
      const data = budgetByMonth.get(month.key)
      row[month.key] = data ? getter(data) : 0
    })
    return row
  }

  return [
    createRow('売上', (data) => data.sales),
    createRow('粗利', (data) => data.grossProfit),
    createRow('販促費', (data) => data.promotionCost),
    createRow('役員非稼働分', (data) => data.executiveNonWorking),
    createRow('営業利益', (data) => data.operatingProfit)
  ]
})

const budgetColumnDefs = computed<ColDef<BudgetRow>[]>(() => [
  {
    field: 'item',
    headerName: '項目',
    pinned: 'left',
    minWidth: 210,
    cellClass: 'cell-item-label',
    cellStyle: {
      textAlign: 'left'
    }
  },
  ...visibleMonths.value.map((month) => ({
    field: month.key,
    headerName: month.label,
    minWidth: 150,
    valueFormatter: (params: ValueFormatterParams<BudgetRow>) => formatYen(Number(params.value ?? 0)),
    cellClass: (params: CellClassParams<BudgetRow>) => {
      const classes = ['cell-money']
      if (Number(params.value ?? 0) < 0) classes.push('cell-negative')
      if (params.data?.item === '営業利益') classes.push('cell-profit-row')
      return classes.join(' ')
    }
  }))
])

const getBudgetRowClass = (params: RowClassParams<BudgetRow>) => {
  if (params.data?.item === '営業利益') return 'row-operating-profit'
  return ''
}

const BILLING_ADJUSTMENTS_STORAGE_KEY = 'proto.billing-adjustments.v1'
const salesAdjustmentKey = '三千人将A|案件001|2026-02'
const resolveIndexFromId = (id: string, prefix: string) => {
  if (!id.startsWith(prefix)) return -1
  const numericPart = Number(id.slice(prefix.length))
  if (Number.isNaN(numericPart)) return -1
  return numericPart - 1
}
const resolveMemberNameForAdjustment = (adjustment: PersistedBillingAdjustment) => {
  if (typeof adjustment.userName === 'string' && allPeople.includes(adjustment.userName)) return adjustment.userName
  if (typeof adjustment.userId !== 'string') return ''
  const memberIndex = resolveIndexFromId(adjustment.userId, 'u')
  return memberIndex >= 0 && memberIndex < allPeople.length ? allPeople[memberIndex] : ''
}
const resolveProjectNameForAdjustment = (adjustment: PersistedBillingAdjustment) => {
  if (typeof adjustment.projectName === 'string' && projects.includes(adjustment.projectName)) return adjustment.projectName
  if (typeof adjustment.projectId !== 'string') return ''
  const projectIndex = resolveIndexFromId(adjustment.projectId, 'p')
  return projectIndex >= 0 && projectIndex < projects.length ? projects[projectIndex] : ''
}
const loadPersistedSalesAdjustments = (): Array<[string, { adjustment: number; memo: string }]> => {
  if (typeof window === 'undefined') return []
  try {
    const raw = window.localStorage.getItem(BILLING_ADJUSTMENTS_STORAGE_KEY)
    if (!raw) return []

    const parsed = JSON.parse(raw)
    if (!Array.isArray(parsed)) return []

    return parsed.reduce<Array<[string, { adjustment: number; memo: string }]>>((acc, item) => {
      if (!item || typeof item !== 'object') return acc
      const adjustment = item as PersistedBillingAdjustment
      const memberName = resolveMemberNameForAdjustment(adjustment)
      const projectName = resolveProjectNameForAdjustment(adjustment)
      const monthKey = typeof adjustment.toMonth === 'string' ? adjustment.toMonth : ''
      const memo = typeof adjustment.memo === 'string' ? adjustment.memo : ''
      const amount = Number(adjustment.amount)

      if (!memberName || !projectName || !monthKey || !memo || Number.isNaN(amount)) return acc
      acc.push([`${memberName}|${projectName}|${monthKey}`, { adjustment: amount, memo }])
      return acc
    }, [])
  } catch {
    return []
  }
}
const salesAdjustments = new Map<string, { adjustment: number; memo: string }>([
  [salesAdjustmentKey, { adjustment: -18000, memo: '1月分 請求時間誤り修正' }],
  ...loadPersistedSalesAdjustments()
])

const salesCellDetails = new Map<string, SalesCellDetail>()

allPeople.forEach((person) => {
  projects.forEach((project) => {
    allMonths.forEach((month) => {
      const billedHours = seededInt(`${person}:${project}:${month.key}:billed-hours`, 12, 68)
      const billingRate = seededInt(`${person}:${project}:${month.key}:billing-rate`, 4000, 7600)
      const baseRevenueRaw = billedHours * billingRate
      const baseRevenue = Math.max(50000, Math.min(500000, baseRevenueRaw))
      const adjustmentInfo = salesAdjustments.get(`${person}|${project}|${month.key}`)
      const adjustment = adjustmentInfo?.adjustment ?? 0
      const memo = adjustmentInfo?.memo
      const totalRevenue = baseRevenue + adjustment

      salesCellDetails.set(`${person}|${project}|${month.key}`, {
        billedHours,
        billingRate,
        baseRevenue,
        adjustment,
        memo,
        totalRevenue
      })
    })
  })
})

const getSalesCellDetail = (person: string, project: string, monthKey: string) => {
  return salesCellDetails.get(`${person}|${project}|${monthKey}`)
}
const getSalesMemoTooltip = (row: MemberSalesRow | undefined, monthKey: string | undefined) => {
  if (!row || row.rowType !== 'project' || !monthKey) return ''
  const detail = getSalesCellDetail(row.memberName, row.displayName, monthKey)
  if (!detail || detail.adjustment === 0 || !detail.memo) return ''
  return `${detail.memo} ${formatSignedYen(detail.adjustment)}`
}

const memberSalesRows = computed<MemberSalesRow[]>(() => {
  const rows: MemberSalesRow[] = []

  allPeople.forEach((person) => {
    const headerRow: MemberSalesRow = {
      memberName: person,
      displayName: person,
      leftLabel: person,
      rowType: 'memberHeader'
    }
    allMonths.forEach((month) => {
      headerRow[month.key] = null
    })

    const projectRows = projects.map((project) => {
      const row: MemberSalesRow = {
        memberName: person,
        displayName: project,
        leftLabel: `　${project}`,
        rowType: 'project'
      }

      allMonths.forEach((month) => {
        const detail = getSalesCellDetail(person, project, month.key)
        row[month.key] = detail?.totalRevenue ?? 0
      })

      return row
    })

    const subtotalRow: MemberSalesRow = {
      memberName: person,
      displayName: '合計',
      leftLabel: '　合計',
      rowType: 'subtotal'
    }

    allMonths.forEach((month) => {
      subtotalRow[month.key] = projectRows.reduce((sum, row) => sum + Number(row[month.key] ?? 0), 0)
    })

    rows.push(headerRow, ...projectRows, subtotalRow)
  })

  return rows
})

const filteredMemberSalesRows = computed<MemberSalesRow[]>(() => {
  const selectedMembers = allPeople.filter((memberName) => isMemberSalesMemberSelected(memberName))
  if (selectedMembers.length === 0) return memberSalesRows.value

  const selectedMemberSet = new Set(selectedMembers)
  return memberSalesRows.value.filter((row) => selectedMemberSet.has(row.memberName))
})

const createMemberSalesCellRenderer = (params: ICellRendererParams<MemberSalesRow, number | null>) => {
  if (params.value === null || params.value === undefined) return ''

  const wrapper = document.createElement('div')
  wrapper.className = 'sales-cell-wrap'

  const amount = document.createElement('span')
  amount.textContent = formatYen(Number(params.value))
  wrapper.appendChild(amount)

  const monthKey = params.colDef?.field
  if (!monthKey || params.data?.rowType !== 'project') return wrapper

  const memoText = getSalesMemoTooltip(params.data, monthKey)
  if (!memoText) return wrapper

  const memoIcon = document.createElement('span')
  memoIcon.className = 'sales-memo-icon'
  memoIcon.textContent = '📝'
  memoIcon.title = memoText
  memoIcon.setAttribute('aria-label', memoText)
  wrapper.appendChild(memoIcon)

  return wrapper
}

const memberSalesColumnDefs = computed<Array<ColDef<MemberSalesRow> | ColGroupDef<MemberSalesRow>>>(() => [
  {
    field: 'leftLabel',
    headerName: 'メンバー / 案件',
    pinned: 'left',
    minWidth: 280,
    cellClass: (params: CellClassParams<MemberSalesRow>) => {
      if (params.data?.rowType === 'memberHeader') return 'cell-group-label'
      return params.data?.rowType === 'subtotal' ? 'cell-subtotal-label' : 'cell-member-label'
    },
    cellStyle: {
      textAlign: 'left'
    }
  },
  {
    headerName: '年月',
    children: visibleMonths.value.map((month): ColDef<MemberSalesRow> => ({
      field: month.key,
      headerName: month.label,
      minWidth: 160,
      valueFormatter: (params: ValueFormatterParams<MemberSalesRow>) => {
        if (params.value === null || params.value === undefined) return ''
        return formatYen(Number(params.value))
      },
      cellRenderer: createMemberSalesCellRenderer,
      tooltipValueGetter: (params) => {
        const monthKey = params.colDef && 'field' in params.colDef ? params.colDef.field : undefined
        return getSalesMemoTooltip(params.data, monthKey)
      },
      cellClass: (params: CellClassParams<MemberSalesRow>) => {
        return params.data?.rowType === 'subtotal' ? 'cell-subtotal' : 'cell-money'
      }
    }))
  }
])

const getMemberSalesRowClass = (params: RowClassParams<MemberSalesRow>) => {
  if (params.data?.rowType === 'memberHeader') return 'row-group-header'
  if (params.data?.rowType === 'subtotal') return 'row-subtotal'
  return ''
}

const memberMonthSalesTotals = computed(() => {
  const map = new Map<string, number[]>()

  allPeople.forEach((person) => {
    const values = allMonths.map((month) => {
      return projects.reduce((sum, project) => {
        const detail = getSalesCellDetail(person, project, month.key)
        return sum + (detail?.totalRevenue ?? 0)
      }, 0)
    })
    map.set(person, values)
  })

  return map
})

const selectedDonutMonth = ref<string>(allMonths[allMonths.length - 1].key)

watch(
  memberChartVisibleMonthKeys,
  (monthKeys) => {
    if (monthKeys.length === 0) return
    if (!monthKeys.includes(selectedDonutMonth.value)) {
      selectedDonutMonth.value = monthKeys[monthKeys.length - 1]
    }
  },
  { immediate: true }
)

const memberColorPalette = ['#4361ee', '#4cc9f0', '#f72585', '#3a0ca3', '#4895ef', '#b5179e', '#2ec4b6', '#ff9f1c', '#6a4c93', '#80ed99']
const memberColorByName = new Map(allPeople.map((person, index) => [person, memberColorPalette[index % memberColorPalette.length]]))
const chartTextColor = '#334155'
const chartAxisColor = '#94a3b8'
const chartSplitLineColor = 'rgba(148, 163, 184, 0.28)'

const memberStackedChartEl = ref<HTMLDivElement | null>(null)
const memberDonutChartEl = ref<HTMLDivElement | null>(null)
const profitTrendChartEl = ref<HTMLDivElement | null>(null)

let memberStackedChart: echarts.ECharts | null = null
let memberDonutChart: echarts.ECharts | null = null
let profitTrendChart: echarts.ECharts | null = null

const ensureChartInstance = (chart: echarts.ECharts | null, el: HTMLDivElement | null) => {
  if (!el) return chart
  if (chart && chart.getDom() !== el) {
    chart.dispose()
    chart = null
  }
  if (!chart) {
    chart = echarts.init(el)
  }
  return chart
}

const initMemberCharts = () => {
  memberStackedChart = ensureChartInstance(memberStackedChart, memberStackedChartEl.value)
  memberDonutChart = ensureChartInstance(memberDonutChart, memberDonutChartEl.value)
}

const initProfitChart = () => {
  if (profitTrendChartEl.value && !profitTrendChart) {
    profitTrendChart = echarts.init(profitTrendChartEl.value)
  }
}

const renderMemberCharts = () => {
  if (!memberStackedChart || !memberDonutChart) return

  const monthsForChart = memberChartVisibleMonths.value
  const monthLabels = monthsForChart.map((month) => month.label)
  const monthIndexes = monthsForChart.map((month) => allMonthIndexByKey.get(month.key) ?? -1)

  if (monthLabels.length === 0) {
    memberStackedChart.setOption({
      backgroundColor: 'transparent',
      xAxis: { type: 'category', data: [] },
      yAxis: { type: 'value' },
      series: [],
      graphic: [
        {
          type: 'text',
          left: 'center',
          top: 'middle',
          style: {
            text: '表示対象のデータがありません',
            fill: chartTextColor,
            fontSize: 14
          }
        }
      ]
    }, true)
    memberDonutChart.setOption({
      backgroundColor: 'transparent',
      series: [],
      graphic: [
        {
          type: 'text',
          left: 'center',
          top: 'middle',
          style: {
            text: '表示対象のデータがありません',
            fill: chartTextColor,
            fontSize: 14
          }
        }
      ]
    }, true)
    return
  }

  const memberSeries = allPeople.map((person) => ({
    name: person,
    type: 'bar' as const,
    stack: 'sales',
    emphasis: { focus: 'series' as const },
    itemStyle: { color: memberColorByName.get(person) ?? '#64748b' },
    data: monthIndexes.map((monthIndex) => {
      if (monthIndex < 0) return 0
      return memberMonthSalesTotals.value.get(person)?.[monthIndex] ?? 0
    })
  }))

  memberStackedChart.setOption({
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      valueFormatter: (value: string | number) => formatYen(Number(value))
    },
    legend: {
      type: 'scroll',
      top: 0,
      textStyle: { color: chartTextColor }
    },
    grid: {
      left: 72,
      right: 20,
      top: 56,
      bottom: 40
    },
    xAxis: {
      type: 'category',
      data: monthLabels,
      axisLine: { lineStyle: { color: chartAxisColor } },
      axisLabel: { color: chartTextColor }
    },
    yAxis: {
      type: 'value',
      axisLine: { lineStyle: { color: chartAxisColor } },
      splitLine: { lineStyle: { color: chartSplitLineColor } },
      axisLabel: {
        color: chartTextColor,
        formatter: (value: number) => `${Math.round(value / 10000)}万`
      }
    },
    series: memberSeries
  }, true)

  const donutMonth = selectedDonutMonth.value
  const donutMonthIndex = allMonthIndexByKey.get(donutMonth) ?? -1
  const donutData = allPeople.map((person) => {
    const monthValues = memberMonthSalesTotals.value.get(person) ?? []
    return {
      name: person,
      value: donutMonthIndex >= 0 ? monthValues[donutMonthIndex] : 0,
      itemStyle: { color: memberColorByName.get(person) ?? '#64748b' }
    }
  })
  const sortedDonutData = [...donutData].sort((left, right) => {
    if (memberDonutSortMode.value === 'shareDesc') {
      const valueDiff = Number(right.value) - Number(left.value)
      if (valueDiff !== 0) return valueDiff
    }
    return getMemberRoleRank(left.name) - getMemberRoleRank(right.name)
  })

  const total = sortedDonutData.reduce((sum, item) => sum + Number(item.value), 0)

  memberDonutChart.setOption({
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'item',
      formatter: (params: { name: string; value: number; percent: number }) => {
        return `${params.name}<br/>${formatYen(params.value)} (${params.percent.toFixed(1)}%)`
      }
    },
    title: {
      text: `${formatYen(total)}\n合計`,
      left: 'center',
      top: '43%',
      textStyle: {
        color: '#0f172a',
        fontSize: 15,
        fontWeight: 700,
        lineHeight: 22
      }
    },
    legend: {
      bottom: 0,
      type: 'scroll',
      textStyle: { color: chartTextColor }
    },
    series: [
      {
        name: '売上構成比',
        type: 'pie',
        radius: ['52%', '76%'],
        center: ['50%', '40%'],
        avoidLabelOverlap: true,
        minShowLabelAngle: 5,
        label: {
          color: chartTextColor,
          fontSize: 11,
          formatter: (params: { name: string; percent: number }) => `${params.percent.toFixed(1)}% ${params.name}`
        },
        labelLine: {
          lineStyle: {
            color: chartAxisColor
          }
        },
        labelLayout: {
          hideOverlap: true
        },
        data: sortedDonutData
      }
    ]
  }, true)
}

const buildMonthKey = (year: number, month: number) => `${year}-${String(month).padStart(2, '0')}`
const parseMonthKey = (key: string) => {
  const [yearRaw, monthRaw] = key.split('-')
  const year = Number(yearRaw)
  const month = Number(monthRaw)
  if (Number.isNaN(year) || Number.isNaN(month)) return null
  return { year, month }
}
const formatMonthLabel = (key: string) => {
  const parsed = parseMonthKey(key)
  if (!parsed) return key
  return `${parsed.year}年${parsed.month}月`
}
const formatMonthShortLabel = (key: string) => {
  const parsed = parseMonthKey(key)
  if (!parsed) return key
  return `${parsed.month}月`
}
const shiftYearInMonthKey = (key: string, yearDiff: number) => {
  const parsed = parseMonthKey(key)
  if (!parsed) return key
  return buildMonthKey(parsed.year + yearDiff, parsed.month)
}
const calcProfitMargin = (row?: Pick<ProfitMonthData, 'sales' | 'profit'>) => {
  if (!row || row.sales === 0) return 0
  return (row.profit / row.sales) * 100
}
const buildSequentialMonthKeys = (startYear: number, startMonth: number, count: number) => {
  const keys: string[] = []
  let year = startYear
  let month = startMonth
  for (let index = 0; index < count; index += 1) {
    keys.push(buildMonthKey(year, month))
    month += 1
    if (month > 12) {
      month = 1
      year += 1
    }
  }
  return keys
}

const profitMonthKeys = buildSequentialMonthKeys(2024, 8, 24)
const monthlyProfitData: ProfitMonthData[] = profitMonthKeys.map((key) => {
  const sales = seededInt(`${key}:profit-sales`, 2000000, 3200000)
  const marginPercent = seededInt(`${key}:profit-margin`, 10, 28) / 100
  const previousYearMargin = seededInt(`${key}:profit-prev-margin`, 8, 24)
  let profit = Math.round(sales * marginPercent)

  // マイナス利益の描画確認用ダミー
  if (key === '2025-11') {
    profit = -180000
  }

  return { key, sales, profit, previousYearMargin }
})

const monthlyProfitMap = new Map(monthlyProfitData.map((item) => [item.key, item]))

const halfYearPeriods: HalfYearPeriod[] = []
for (let index = 0; index + 5 < profitMonthKeys.length; index += 6) {
  const monthKeys = profitMonthKeys.slice(index, index + 6)
  const startKey = monthKeys[0]
  const endKey = monthKeys[monthKeys.length - 1]
  const start = parseMonthKey(startKey)
  const fiscalYear = start ? (start.month >= 8 ? start.year : start.year - 1) : 0
  const halfLabel = start && start.month >= 8 ? '上半期' : '下半期'
  const halfId = halfLabel === '上半期' ? 'h1' : 'h2'

  halfYearPeriods.push({
    id: `${fiscalYear}-${halfId}`,
    label: `${fiscalYear}年度${halfLabel}`,
    startKey,
    endKey,
    monthKeys
  })
}

const selectedHalfYearPeriodId = ref<string>(halfYearPeriods[halfYearPeriods.length - 1]?.id ?? '')
const selectedHalfYearPeriod = computed<HalfYearPeriod | null>(() => {
  return halfYearPeriods.find((period) => period.id === selectedHalfYearPeriodId.value) ?? halfYearPeriods[halfYearPeriods.length - 1] ?? null
})

const visibleProfitRows = computed(() => {
  const period = selectedHalfYearPeriod.value
  if (!period) return []
  return period.monthKeys
    .map((key) => monthlyProfitMap.get(key))
    .filter((item): item is ProfitMonthData => Boolean(item))
})

const latestProfitRow = monthlyProfitData[monthlyProfitData.length - 1]
const previousProfitRow = monthlyProfitData[monthlyProfitData.length - 2]
const previousYearProfitRow = latestProfitRow ? monthlyProfitMap.get(shiftYearInMonthKey(latestProfitRow.key, -1)) : undefined

const kpiLastMonthLabel = latestProfitRow ? formatMonthLabel(latestProfitRow.key) : '-'
const kpiPreviousMonthLabel = previousProfitRow ? formatMonthLabel(previousProfitRow.key) : '-'
const kpiPreviousYearLabel = previousYearProfitRow ? formatMonthLabel(previousYearProfitRow.key) : '-'

const kpiLastMonthMargin = calcProfitMargin(latestProfitRow)
const kpiPreviousMonthMargin = calcProfitMargin(previousProfitRow)
const kpiPreviousYearMargin = calcProfitMargin(previousYearProfitRow)
const monthOverMonthDiff = kpiLastMonthMargin - kpiPreviousMonthMargin
const yearOverYearDiff = kpiLastMonthMargin - kpiPreviousYearMargin

const halfYearRows = computed(() => visibleProfitRows.value)

const halfYearTableRows = computed(() => {
  return halfYearRows.value.map((row) => ({
    ...row,
    margin: (row.profit / row.sales) * 100
  }))
})

const halfYearSalesTotal = computed(() => halfYearRows.value.reduce((sum, row) => sum + row.sales, 0))
const halfYearProfitTotal = computed(() => halfYearRows.value.reduce((sum, row) => sum + row.profit, 0))
const halfYearProfitRate = computed(() => {
  if (halfYearSalesTotal.value === 0) return 0
  return (halfYearProfitTotal.value / halfYearSalesTotal.value) * 100
})

const halfYearRangeLabel = computed(() => {
  const selectedPeriod = selectedHalfYearPeriod.value
  if (!selectedPeriod) return '半期データ'
  return `${formatMonthLabel(selectedPeriod.startKey)}〜${formatMonthLabel(selectedPeriod.endKey)}（${selectedPeriod.label}）`
})

const bonusTargetRate = 25
const bonusScaleMax = 40
const bonusTargetPosition = (bonusTargetRate / bonusScaleMax) * 100

const trackerFillWidth = computed(() => {
  return Math.max(0, Math.min((halfYearProfitRate.value / bonusScaleMax) * 100, 100))
})

const trackerColor = computed(() => {
  if (halfYearProfitRate.value >= 25) return '#16a34a'
  if (halfYearProfitRate.value >= 20) return '#f59e0b'
  return '#ef4444'
})

const trackerBadgeClass = computed(() => {
  return halfYearProfitRate.value >= 25 ? 'tracker-badge-success' : 'tracker-badge-warning'
})

const trackerBadgeLabel = computed(() => {
  if (halfYearProfitRate.value >= 25) return '🎉 達成中！'
  const diff = Math.max(0, 25 - halfYearProfitRate.value)
  return `⚠️ あと${diff.toFixed(1)}%で達成`
})

const monthLabelForTable = (key: string) => {
  return formatMonthShortLabel(key)
}

const renderProfitTrendChart = () => {
  if (!profitTrendChart) return

  const xAxisLabels = visibleProfitRows.value.map((row) => formatMonthLabel(row.key))
  const salesSeries = visibleProfitRows.value.map((row) => row.sales)
  const profitSeries = visibleProfitRows.value.map((row) => row.profit)
  const marginSeries = visibleProfitRows.value.map((row) => (row.profit / row.sales) * 100)
  const previousYearMarginSeries = visibleProfitRows.value.map((row) => row.previousYearMargin)

  const amountSeries = [...salesSeries, ...profitSeries]
  const amountMinValue = Math.min(0, ...amountSeries)
  const amountMaxValue = Math.max(0, ...amountSeries)
  const amountSpan = Math.max(1, amountMaxValue - amountMinValue)
  const amountPadding = Math.max(150000, Math.round(amountSpan * 0.08))
  const amountAxisMin = amountMinValue < 0
    ? Math.floor((amountMinValue - amountPadding) / 100000) * 100000
    : 0
  const amountAxisMax = Math.ceil((amountMaxValue + amountPadding) / 100000) * 100000

  profitTrendChart.setOption({
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'cross' },
      formatter: (params: Array<{ seriesName: string; value: number; marker: string; axisValueLabel?: string }>) => {
        if (params.length === 0) return ''
        const lines = [params[0].axisValueLabel ?? '']
        params.forEach((item) => {
          const isRateSeries = item.seriesName.includes('利益率')
          const valueLabel = isRateSeries ? `${Number(item.value).toFixed(1)}%` : formatYen(Number(item.value))
          lines.push(`${item.marker}${item.seriesName}: ${valueLabel}`)
        })
        return lines.join('<br/>')
      }
    },
    legend: {
      top: 0,
      textStyle: {
        color: chartTextColor
      }
    },
    grid: {
      left: 78,
      right: 70,
      top: 56,
      bottom: 42
    },
    xAxis: {
      type: 'category',
      data: xAxisLabels,
      axisLine: { lineStyle: { color: chartAxisColor } },
      axisLabel: { color: chartTextColor }
    },
    yAxis: [
      {
        type: 'value',
        name: '金額（¥）',
        min: amountAxisMin,
        max: amountAxisMax,
        axisLabel: {
          color: chartTextColor,
          formatter: (value: number) => `${Math.round(value / 10000)}万`
        },
        splitLine: { lineStyle: { color: chartSplitLineColor } }
      },
      {
        type: 'value',
        name: '利益率（%）',
        min: 0,
        max: 40,
        axisLabel: {
          color: chartTextColor,
          formatter: (value: number) => `${value}%`
        },
        splitLine: { show: false }
      }
    ],
    series: [
      {
        name: '月次売上',
        type: 'bar',
        yAxisIndex: 0,
        barGap: '15%',
        itemStyle: { color: 'rgba(96, 165, 250, 0.35)' },
        data: salesSeries
      },
      {
        name: '月次営業利益',
        type: 'bar',
        yAxisIndex: 0,
        itemStyle: { color: '#4361ee' },
        data: profitSeries
      },
      {
        name: '月次営業利益率',
        type: 'line',
        yAxisIndex: 1,
        smooth: false,
        symbol: 'circle',
        symbolSize: 8,
        lineStyle: { width: 4, color: '#4cc9f0' },
        itemStyle: { color: '#4cc9f0' },
        data: marginSeries,
        markLine: {
          symbol: 'none',
          label: {
            color: '#b91c1c',
            formatter: 'ボーナスライン 25%'
          },
          lineStyle: {
            color: '#ef4444',
            type: 'dashed',
            width: 2
          },
          data: [{ yAxis: 25 }]
        }
      },
      {
        name: '前年同月利益率',
        type: 'line',
        yAxisIndex: 1,
        smooth: false,
        symbol: 'none',
        lineStyle: {
          width: 2,
          type: 'dashed',
          color: chartAxisColor
        },
        data: previousYearMarginSeries
      }
    ]
  })
}

const resizeCharts = () => {
  memberStackedChart?.resize()
  memberDonutChart?.resize()
  profitTrendChart?.resize()
}
const onWindowPointerDown = (event: PointerEvent) => {
  if (!workHoursScaleMenuOpen.value) return
  const target = event.target as Node | null
  if (target && workHoursScaleMenuWrapRef.value?.contains(target)) return
  workHoursScaleMenuOpen.value = false
}
const onWindowKeydown = (event: KeyboardEvent) => {
  if (event.key !== 'Escape') return
  workHoursScaleMenuOpen.value = false
}

watch(
  [activeTab, memberChartVisibleMonthKeys, visibleMonthKeys],
  async ([tab]) => {
    await nextTick()

    if (tab === 'memberChart') {
      initMemberCharts()
      renderMemberCharts()
      resizeCharts()
    }

    if (tab === 'profitTracker') {
      initProfitChart()
      renderProfitTrendChart()
      resizeCharts()
    }
  },
  { immediate: true }
)

watch([selectedDonutMonth, memberDonutSortMode], () => {
  if (activeTab.value === 'memberChart') {
    initMemberCharts()
    renderMemberCharts()
    resizeCharts()
  }
})

watch(selectedHalfYearPeriodId, () => {
  if (activeTab.value !== 'profitTracker') return
  initProfitChart()
  renderProfitTrendChart()
  resizeCharts()
})

onMounted(() => {
  window.addEventListener('resize', resizeCharts)
  window.addEventListener('pointerdown', onWindowPointerDown)
  window.addEventListener('keydown', onWindowKeydown)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', resizeCharts)
  window.removeEventListener('pointerdown', onWindowPointerDown)
  window.removeEventListener('keydown', onWindowKeydown)
  memberStackedChart?.dispose()
  memberDonutChart?.dispose()
  profitTrendChart?.dispose()
  memberStackedChart = null
  memberDonutChart = null
  profitTrendChart = null
})
</script>

<style scoped>
.dashboard-page {
  min-height: calc(100vh - 96px);
  padding: 20px;
  background:
    radial-gradient(circle at 0% 0%, rgba(67, 97, 238, 0.08), transparent 45%),
    radial-gradient(circle at 100% 100%, rgba(76, 201, 240, 0.08), transparent 48%),
    #ffffff;
}

.dashboard-shell {
  max-width: 1500px;
  margin: 0 auto;
  border: 1px solid #dbe3f3;
  border-radius: 16px;
  padding: 20px;
  background: #ffffff;
  box-shadow: 0 14px 30px rgba(15, 23, 42, 0.08);
}

.dashboard-header {
  display: flex;
  justify-content: flex-start;
  gap: 16px;
  margin-bottom: 18px;
}

.dashboard-title {
  margin: 0;
  font-size: 30px;
  color: #0f172a;
  letter-spacing: 0.01em;
}

.dashboard-subtitle {
  margin: 6px 0 0;
  font-size: 13px;
  color: #64748b;
}

.period-select {
  border: 1px solid #c8d5fb;
  border-radius: 8px;
  padding: 7px 10px;
  color: #1e293b;
  background: #ffffff;
  font-size: 12px;
  font-weight: 600;
}

.tab-nav {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 16px;
}

.tab-btn {
  border: 1px solid #d6dff4;
  border-radius: 10px;
  padding: 10px 14px;
  background: #f8faff;
  color: #475569;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
}

.tab-btn-active {
  border-color: #4361ee;
  background: #4361ee;
  color: #ffffff;
}

.tab-panel {
  border: 1px solid #dbe3f3;
  border-radius: 14px;
  padding: 14px;
  background: #ffffff;
}

.panel-header {
  margin-bottom: 12px;
}

.panel-header-split {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.panel-header h2 {
  margin: 0;
  color: #1e293b;
  font-size: 18px;
}

.member-sales-header-controls {
  display: inline-flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  flex-wrap: wrap;
}

.member-sales-filter-group {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.member-sales-filter-buttons {
  display: inline-flex;
  align-items: center;
  justify-content: flex-end;
  gap: 6px;
  flex-wrap: wrap;
}

.member-sales-scale-control {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #475569;
  font-size: 12px;
  font-weight: 700;
}

.member-sales-scale-buttons {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.member-sales-scale-btn {
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  background: #ffffff;
  color: #334155;
  font-size: 12px;
  font-weight: 700;
  padding: 5px 9px;
  line-height: 1.2;
  cursor: pointer;
}

.member-sales-scale-btn:hover {
  background: #f1f5f9;
}

.member-sales-scale-btn-active {
  border-color: #1d4ed8;
  background: #dbeafe;
  color: #1e3a8a;
}

.work-hours-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 10px;
}

.work-hours-filter-box {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.work-hours-filter-group {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.work-hours-filter-label {
  font-size: 12px;
  color: #475569;
  font-weight: 700;
}

.work-hours-filter-buttons {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.work-hours-filter-btn {
  border: 1px solid #cbd5e1;
  background: #ffffff;
  color: #475569;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
  padding: 4px 10px;
  cursor: pointer;
}

.work-hours-filter-btn-active {
  border-color: #334155;
  background: #334155;
  color: #ffffff;
}

.work-hours-member-filter-btn-active {
  border-color: #1d4ed8;
  background: #dbeafe;
  color: #1e3a8a;
}

.work-hours-scale-control {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #475569;
  font-size: 12px;
  font-weight: 700;
}

.work-hours-scale-trigger {
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  background: #ffffff;
  color: #0f172a;
  padding: 6px 10px;
  font-size: 12px;
  font-weight: 700;
  min-width: 72px;
  text-align: right;
  cursor: pointer;
}

.work-hours-scale-menu {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  z-index: 20;
  min-width: 80px;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  background: #ffffff;
  box-shadow: 0 10px 18px rgba(15, 23, 42, 0.12);
  padding: 6px;
}

.work-hours-scale-option {
  width: 100%;
  border: 0;
  background: transparent;
  color: #475569;
  border-radius: 6px;
  padding: 6px 8px;
  text-align: right;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
}

.work-hours-scale-option:hover {
  background: #f1f5f9;
}

.work-hours-scale-option-active {
  background: #e2e8f0;
  color: #0f172a;
}

.grid-shell {
  width: 100%;
  border-radius: 10px;
  overflow: hidden;
}

.work-hours-stage {
  overflow: auto;
  border-radius: 10px;
}

.work-hours-zoom {
  transform-origin: top left;
}

.member-sales-stage {
  height: 680px;
  overflow: auto;
  border-radius: 10px;
}

.member-sales-zoom {
  transform-origin: top left;
}

.grid-shell-member-sales {
  height: 680px;
}

.grid-shell-hours {
  height: 760px;
}

.grid-shell-md {
  height: 350px;
}

.chart-layout {
  display: grid;
  grid-template-columns: 1fr;
  gap: 14px;
}

.chart-card {
  border: 1px solid #dbe3f3;
  border-radius: 12px;
  padding: 14px;
  background: #ffffff;
}

.chart-card h3 {
  margin: 0 0 10px;
  color: #1e293b;
  font-size: 15px;
}

.chart-card-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 8px;
}

.chart-card-head-wrap {
  flex-wrap: wrap;
}

.member-chart-controls {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.member-chart-custom-range {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.member-chart-range-separator {
  color: #64748b;
  font-size: 12px;
  font-weight: 700;
}

.donut-select {
  min-width: 140px;
}

.chart-canvas {
  width: 100%;
}

.chart-canvas-large {
  height: 380px;
}

.chart-canvas-small {
  height: 380px;
}

.chart-card-full {
  margin-top: 14px;
}

.kpi-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.kpi-card {
  border: 1px solid #dbe3f3;
  border-radius: 12px;
  padding: 14px;
  background: #f8faff;
}

.kpi-label {
  margin: 0;
  color: #4361ee;
  font-size: 12px;
  font-weight: 700;
}

.kpi-value {
  margin: 8px 0 4px;
  color: #0f172a;
  font-size: 30px;
  font-weight: 800;
  letter-spacing: 0.01em;
}

.kpi-note {
  margin: 0;
  color: #64748b;
  font-size: 12px;
}

.kpi-positive {
  color: #34d399;
}

.kpi-negative {
  color: #f87171;
}

.tracker-card {
  margin-top: 14px;
  border: 1px solid #dbe3f3;
  border-radius: 12px;
  padding: 14px;
  background: #f8faff;
}

.tracker-head {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  align-items: center;
}

.tracker-head h3 {
  margin: 0;
  color: #1e293b;
  font-size: 16px;
}

.tracker-period-controls {
  margin-top: 10px;
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.tracker-period-btn {
  border: 1px solid #cbd5e1;
  background: #ffffff;
  color: #475569;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
  padding: 5px 10px;
  line-height: 1.2;
  cursor: pointer;
}

.tracker-period-btn:hover {
  background: #f1f5f9;
}

.tracker-period-btn-active {
  border-color: #1d4ed8;
  background: #dbeafe;
  color: #1e3a8a;
}

.tracker-badge {
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 12px;
  font-weight: 700;
}

.tracker-badge-success {
  color: #064e3b;
  background: #6ee7b7;
}

.tracker-badge-warning {
  color: #78350f;
  background: #fcd34d;
}

.tracker-meter-wrap {
  margin-top: 12px;
}

.tracker-meter {
  position: relative;
  width: 100%;
  height: 22px;
  border-radius: 999px;
  background: rgba(148, 163, 184, 0.24);
  overflow: hidden;
}

.tracker-fill {
  display: block;
  height: 100%;
  border-radius: 999px;
  transition: width 0.25s ease;
}

.tracker-target-line {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 0;
  border-left: 2px dashed #ef4444;
  z-index: 1;
}

.tracker-scale {
  margin-top: 6px;
  display: flex;
  justify-content: space-between;
  color: #64748b;
  font-size: 11px;
}

.tracker-summary {
  margin-top: 12px;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.tracker-summary p {
  margin: 0;
  color: #475569;
  font-size: 13px;
}

.tracker-summary strong {
  color: #0f172a;
}

.tracker-table-wrap {
  margin-top: 12px;
  overflow-x: auto;
}

.tracker-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 560px;
}

.tracker-table th,
.tracker-table td {
  border: 1px solid rgba(148, 163, 184, 0.26);
  padding: 8px;
  text-align: right;
  color: #1e293b;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}

.tracker-table th:first-child,
.tracker-table td:first-child {
  text-align: left;
}

.tracker-table thead th {
  background: rgba(67, 97, 238, 0.12);
}

.tracker-table-total td {
  background: rgba(67, 97, 238, 0.08);
  font-weight: 700;
}

:deep(.ag-header) {
  border-bottom: 1px solid #cfd8eb;
}

:deep(.ag-header-cell),
:deep(.ag-header-group-cell) {
  font-weight: 700;
}

:deep(.ag-header-cell-text),
:deep(.ag-header-group-text) {
  color: #1e293b;
}

:deep(.ag-cell.cell-group-label),
:deep(.ag-cell.cell-member-label),
:deep(.ag-cell.cell-subtotal-label),
:deep(.ag-cell.cell-item-label) {
  text-align: left;
}

:deep(.ag-cell.cell-group-label) {
  color: #0f172a;
  font-weight: 700;
}

:deep(.ag-cell.cell-member-label) {
  color: #334155;
  padding-left: 18px;
}

:deep(.ag-cell.cell-subtotal-label) {
  color: #0f172a;
  font-weight: 700;
  padding-left: 18px;
}

:deep(.ag-row.row-group-header .ag-cell) {
  background: rgba(148, 163, 184, 0.16);
  font-weight: 700;
}

.work-hours-grid :deep(.ag-cell),
.work-hours-grid :deep(.ag-header-cell),
.work-hours-grid :deep(.ag-header-group-cell) {
  padding-left: 6px;
  padding-right: 6px;
}

:deep(.ag-row.row-subtotal .ag-cell),
:deep(.ag-cell.cell-subtotal),
:deep(.ag-cell.cell-subtotal-label) {
  background: rgba(71, 85, 105, 0.14);
  font-weight: 700;
}

:deep(.ag-row.row-operating-profit .ag-cell) {
  background: rgba(76, 201, 240, 0.14);
}

:deep(.ag-cell.cell-negative) {
  color: #f87171;
}

:deep(.sales-cell-wrap) {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 6px;
}

:deep(.sales-memo-icon) {
  font-size: 13px;
  line-height: 1;
  cursor: help;
}

@media (max-width: 1200px) {
  .dashboard-page {
    padding: 12px;
  }

  .dashboard-header {
    flex-direction: column;
  }

  .work-hours-controls {
    flex-direction: column;
    align-items: flex-start;
  }

  .work-hours-scale-control {
    width: 100%;
  }

  .member-sales-scale-control {
    width: 100%;
    justify-content: flex-end;
  }

  .member-sales-header-controls,
  .member-sales-filter-group,
  .member-sales-filter-buttons {
    width: 100%;
    justify-content: flex-end;
  }

  .chart-layout {
    grid-template-columns: 1fr;
  }

  .kpi-grid,
  .tracker-summary {
    grid-template-columns: 1fr;
  }

  .member-sales-stage,
  .grid-shell-member-sales {
    height: 560px;
  }

  .grid-shell-hours {
    height: 620px;
  }

  .chart-canvas-large,
  .chart-canvas-small {
    height: 320px;
  }
}
</style>
