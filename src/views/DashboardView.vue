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
        <button
          v-for="tab in tabs"
          :key="tab.id"
          class="tab-btn"
          :class="{ 'tab-btn-active': activeTab === tab.id }"
          type="button"
          @click="activeTab = tab.id"
        >
          {{ tab.label }}
        </button>
      </nav>

      <section v-if="activeTab === 'workHours'" class="tab-panel">
        <div class="work-hours-controls">
          <div class="work-hours-filter-box">
            <div class="work-hours-filter-group">
              <span class="work-hours-filter-label">案件</span>
              <div class="work-hours-filter-buttons">
                <button
                  v-for="projectName in projects"
                  :key="`work-filter-${projectName}`"
                  class="work-hours-filter-btn"
                  :class="{ 'work-hours-filter-btn-active': isWorkHoursProjectVisible(projectName) }"
                  type="button"
                  @click="toggleWorkHoursProject(projectName)"
                >
                  {{ projectName }}
                </button>
              </div>
            </div>

            <div class="work-hours-filter-group">
              <span class="work-hours-filter-label">メンバー</span>
              <div class="work-hours-filter-buttons">
                <button
                  v-for="memberName in members"
                  :key="`work-member-filter-${memberName}`"
                  class="work-hours-filter-btn work-hours-member-filter-btn"
                  :class="{ 'work-hours-member-filter-btn-active': selectedWorkHoursMember === memberName }"
                  type="button"
                  @click="toggleWorkHoursMember(memberName)"
                >
                  {{ memberName }}
                </button>
              </div>
            </div>
          </div>
          <div ref="workHoursScaleMenuWrapRef" class="work-hours-scale-control">
            <span>表示倍率</span>
            <button
              class="work-hours-scale-trigger"
              type="button"
              aria-label="表示倍率選択"
              @click="workHoursScaleMenuOpen = !workHoursScaleMenuOpen"
            >
              {{ workHoursScale }}%
            </button>
            <div v-if="workHoursScaleMenuOpen" class="work-hours-scale-menu">
              <button
                v-for="scale in workHoursScaleOptions"
                :key="`scale-${scale}`"
                class="work-hours-scale-option"
                :class="{ 'work-hours-scale-option-active': workHoursScale === scale }"
                type="button"
                @click="setWorkHoursScale(scale)"
              >
                {{ scale }}%
              </button>
            </div>
          </div>
        </div>
        <div class="work-hours-stage">
          <div class="work-hours-zoom" :style="workHoursScaleStyle">
            <div class="ag-theme-quartz grid-shell grid-shell-hours">
              <AgGridVue
                class="h-full w-full work-hours-grid"
                :columnDefs="workHoursColumnDefs"
                :rowData="filteredWorkHoursRows"
                :defaultColDef="readOnlyColDef"
                :animateRows="false"
                :rowHeight="34"
                :headerHeight="34"
                :groupHeaderHeight="34"
                :getRowClass="getWorkHoursRowClass"
              />
            </div>
          </div>
        </div>
      </section>

      <section v-else-if="activeTab === 'budget'" class="tab-panel">
        <div class="panel-header">
          <h2>予算収支表</h2>
        </div>
        <div class="ag-theme-quartz grid-shell grid-shell-md">
          <AgGridVue
            class="h-full w-full"
            :columnDefs="budgetColumnDefs"
            :rowData="budgetRows"
            :defaultColDef="readOnlyColDef"
            :animateRows="false"
            :getRowClass="getBudgetRowClass"
          />
        </div>
      </section>

      <section v-else-if="activeTab === 'memberSales'" class="tab-panel">
        <div class="panel-header">
          <h2>メンバー別売上内訳</h2>
        </div>
        <div class="ag-theme-quartz grid-shell grid-shell-lg">
          <AgGridVue
            class="h-full w-full"
            :columnDefs="memberSalesColumnDefs"
            :rowData="memberSalesRows"
            :defaultColDef="readOnlyColDef"
            :animateRows="false"
            :getRowClass="getMemberSalesRowClass"
          />
        </div>
      </section>

      <section v-else-if="activeTab === 'memberChart'" class="tab-panel">
        <div class="panel-header">
          <h2>メンバー別売上グラフ</h2>
        </div>
        <div class="chart-layout">
          <article class="chart-card chart-card-large">
            <h3>月次売上推移（積み上げ）</h3>
            <div ref="memberStackedChartEl" class="chart-canvas chart-canvas-large" />
          </article>

          <article class="chart-card chart-card-small">
            <div class="chart-card-head">
              <h3>選択月の売上構成比</h3>
              <select v-model="selectedDonutMonth" class="period-select donut-select" aria-label="ドーナツ対象月選択">
                <option v-for="month in visibleMonths" :key="`donut-${month.key}`" :value="month.key">{{ month.label }}</option>
              </select>
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

type DashboardTabId = 'workHours' | 'budget' | 'memberSales' | 'memberChart' | 'profitTracker'
type WorkHoursRowType = 'projectHeader' | 'member' | 'subtotal'
type MemberSalesRowType = 'memberHeader' | 'project' | 'subtotal'

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

interface ProfitMonthData {
  key: string
  sales: number
  profit: number
  previousYearMargin: number
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

const projects = ['案件001', '案件002', '案件003']
const members = ['三千人将A', '千人将A', '三百人将A', '百人将A', '什長A', '什長B', '什長C', '什長D']
const executives = ['代表A', '代表B']
const allPeople = [...members, ...executives]

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
const setWorkHoursScale = (scale: number) => {
  workHoursScale.value = scale
  workHoursScaleMenuOpen.value = false
}
const workHoursScaleStyle = computed(() => {
  const ratio = workHoursScale.value / 100
  return {
    transform: `scale(${ratio})`,
    transformOrigin: 'top left'
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

const salesAdjustmentKey = '三千人将A|案件001|2026-01'
const salesAdjustments = new Map<string, { adjustment: number; memo: string }>([
  [salesAdjustmentKey, { adjustment: -55000, memo: '12月分 請求時間誤り修正' }]
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

const createMemberSalesCellRenderer = (params: ICellRendererParams<MemberSalesRow, number | null>) => {
  if (params.value === null || params.value === undefined) return ''

  const wrapper = document.createElement('div')
  wrapper.className = 'sales-cell-wrap'

  const amount = document.createElement('span')
  amount.textContent = formatYen(Number(params.value))
  wrapper.appendChild(amount)

  const monthKey = params.colDef?.field
  if (!monthKey || params.data?.rowType !== 'project') return wrapper

  const detail = getSalesCellDetail(params.data.memberName, params.data.displayName, monthKey)
  if (!detail || detail.adjustment === 0 || !detail.memo) return wrapper

  const memoIcon = document.createElement('span')
  memoIcon.className = 'sales-memo-icon'
  memoIcon.textContent = '📝'
  memoIcon.title = `${detail.memo} ${formatSignedYen(detail.adjustment)}`
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
    const values = visibleMonths.value.map((month) => {
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

watch(visibleMonthKeys, (monthKeys) => {
  if (monthKeys.length === 0) return
  if (!monthKeys.includes(selectedDonutMonth.value)) {
    selectedDonutMonth.value = monthKeys[monthKeys.length - 1]
  }
})

const memberColorPalette = ['#4361ee', '#4cc9f0', '#f72585', '#3a0ca3', '#4895ef', '#b5179e', '#2ec4b6', '#ff9f1c', '#6a4c93', '#80ed99']
const chartTextColor = '#334155'
const chartAxisColor = '#94a3b8'
const chartSplitLineColor = 'rgba(148, 163, 184, 0.28)'

const memberStackedChartEl = ref<HTMLDivElement | null>(null)
const memberDonutChartEl = ref<HTMLDivElement | null>(null)
const profitTrendChartEl = ref<HTMLDivElement | null>(null)

let memberStackedChart: echarts.ECharts | null = null
let memberDonutChart: echarts.ECharts | null = null
let profitTrendChart: echarts.ECharts | null = null

const initMemberCharts = () => {
  if (memberStackedChartEl.value && !memberStackedChart) {
    memberStackedChart = echarts.init(memberStackedChartEl.value)
  }
  if (memberDonutChartEl.value && !memberDonutChart) {
    memberDonutChart = echarts.init(memberDonutChartEl.value)
  }
}

const initProfitChart = () => {
  if (profitTrendChartEl.value && !profitTrendChart) {
    profitTrendChart = echarts.init(profitTrendChartEl.value)
  }
}

const renderMemberCharts = () => {
  if (!memberStackedChart || !memberDonutChart) return

  const monthLabels = visibleMonths.value.map((month) => month.label)
  const memberSeries = allPeople.map((person, index) => ({
    name: person,
    type: 'bar' as const,
    stack: 'sales',
    emphasis: { focus: 'series' as const },
    itemStyle: { color: memberColorPalette[index % memberColorPalette.length] },
    data: memberMonthSalesTotals.value.get(person) ?? []
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
  })

  const donutMonth = selectedDonutMonth.value
  const donutData = allPeople.map((person, index) => {
    const monthValues = memberMonthSalesTotals.value.get(person) ?? []
    const monthIndex = visibleMonthKeys.value.indexOf(donutMonth)
    return {
      name: person,
      value: monthIndex >= 0 ? monthValues[monthIndex] : 0,
      itemStyle: { color: memberColorPalette[index % memberColorPalette.length] }
    }
  })

  const total = donutData.reduce((sum, item) => sum + Number(item.value), 0)

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
      top: '44%',
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
        center: ['50%', '42%'],
        avoidLabelOverlap: true,
        label: {
          color: chartTextColor,
          formatter: '{d}%'
        },
        labelLine: {
          lineStyle: {
            color: chartAxisColor
          }
        },
        data: donutData
      }
    ]
  })
}

const monthlyProfitData: ProfitMonthData[] = [
  { key: '2025-08', sales: 2662000, profit: 312000, previousYearMargin: 18.5 },
  { key: '2025-09', sales: 2107000, profit: 237000, previousYearMargin: 15.2 },
  { key: '2025-10', sales: 2621000, profit: 311000, previousYearMargin: 20.1 },
  { key: '2025-11', sales: 2231000, profit: 121000, previousYearMargin: 12.8 },
  { key: '2025-12', sales: 2729500, profit: 624500, previousYearMargin: 22.0 },
  { key: '2026-01', sales: 2400000, profit: 650000, previousYearMargin: 22.9 },
  { key: '2026-02', sales: 2550000, profit: 575000, previousYearMargin: 19.5 }
]

const monthlyProfitMap = new Map(monthlyProfitData.map((item) => [item.key, item]))

const visibleProfitRows = computed(() => {
  return visibleMonths.value
    .map((month) => monthlyProfitMap.get(month.key))
    .filter((item): item is ProfitMonthData => Boolean(item))
})

const kpiLastMonthLabel = '2026年1月'
const kpiPreviousMonthLabel = '2025年12月'
const kpiPreviousYearLabel = '2025年1月'

const kpiLastMonthMargin = (650000 / 2400000) * 100
const kpiPreviousMonthMargin = (624500 / 2729500) * 100
const kpiPreviousYearMargin = (480000 / 2100000) * 100
const monthOverMonthDiff = kpiLastMonthMargin - kpiPreviousMonthMargin
const yearOverYearDiff = kpiLastMonthMargin - kpiPreviousYearMargin

const halfYearKeys = ['2025-08', '2025-09', '2025-10', '2025-11', '2025-12', '2026-01']

const halfYearRows = computed(() => {
  const baseRows = halfYearKeys
    .map((key) => monthlyProfitMap.get(key))
    .filter((item): item is ProfitMonthData => Boolean(item))

  const visibleSet = new Set(visibleMonthKeys.value)
  const filtered = baseRows.filter((row) => visibleSet.has(row.key))

  return filtered.length > 0 ? filtered : baseRows
})

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
  const first = halfYearRows.value[0]
  const last = halfYearRows.value[halfYearRows.value.length - 1]

  if (!first || !last) return '2025年8月〜2026年1月（上半期）'

  const firstLabel = monthLookup.get(first.key)?.label ?? first.key
  const lastLabel = monthLookup.get(last.key)?.label ?? last.key
  const suffix = halfYearRows.value.length === halfYearKeys.length ? '（上半期）' : '（表示中）'
  return `${firstLabel}〜${lastLabel}${suffix}`
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
  const month = monthLookup.get(key)
  return month ? month.shortLabel : key
}

const renderProfitTrendChart = () => {
  if (!profitTrendChart) return

  const xAxisLabels = visibleProfitRows.value.map((row) => monthLookup.get(row.key)?.label ?? row.key)
  const salesSeries = visibleProfitRows.value.map((row) => row.sales)
  const profitSeries = visibleProfitRows.value.map((row) => row.profit)
  const marginSeries = visibleProfitRows.value.map((row) => (row.profit / row.sales) * 100)
  const previousYearMarginSeries = visibleProfitRows.value.map((row) => row.previousYearMargin)

  const febBoundaryLabel = monthLookup.get('2026-02')?.label ?? '2026年2月'
  const hasFebBoundary = xAxisLabels.includes(febBoundaryLabel)

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
        data: previousYearMarginSeries,
        markLine: hasFebBoundary
          ? {
              symbol: 'none',
              lineStyle: {
                color: chartAxisColor,
                type: 'dashed',
                width: 2
              },
              label: {
                color: '#64748b',
                formatter: '半期境界'
              },
              data: [{ xAxis: febBoundaryLabel }]
            }
          : undefined
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
  [activeTab, visibleMonthKeys],
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

watch(selectedDonutMonth, () => {
  if (activeTab.value === 'memberChart') {
    renderMemberCharts()
  }
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

.panel-header h2 {
  margin: 0;
  color: #1e293b;
  font-size: 18px;
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

.grid-shell-lg {
  height: 560px;
}

.work-hours-stage {
  overflow: auto;
  border-radius: 10px;
}

.work-hours-zoom {
  transform-origin: top left;
}

.grid-shell-hours {
  height: 760px;
}

.grid-shell-md {
  height: 350px;
}

.chart-layout {
  display: grid;
  grid-template-columns: 2fr 1fr;
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

  .chart-layout {
    grid-template-columns: 1fr;
  }

  .kpi-grid,
  .tracker-summary {
    grid-template-columns: 1fr;
  }

  .grid-shell-lg {
    height: 480px;
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
