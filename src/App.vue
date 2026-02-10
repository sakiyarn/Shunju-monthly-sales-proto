<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { AgGridVue } from 'ag-grid-vue3'
import type {
  CellClickedEvent,
  CellContextMenuEvent,
  CellMouseOutEvent,
  CellMouseOverEvent,
  ColDef,
  ColGroupDef,
  ICellRendererParams,
  RowClassParams,
  ValueFormatterParams
} from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-alpine.css'

type FormatType = 'currency' | 'number' | 'percent' | 'blank'
type RowGroup = 'summary' | 'memberPrice' | 'cost' | 'hours' | 'spacer'
type ProjectName = '案件A' | '案件B' | '案件C' | '案件D' | '案件E'
type YearLabel = '2024' | '2025' | '2026' | '2027'

interface MonthDef {
  key: string
  year: YearLabel
  monthLabel: string
  quarterLabel: string
}

interface RowItem {
  id: string
  itemName: string
  level: number
  format: FormatType
  group: RowGroup
  isGroupHeader: boolean
  isSpacer: boolean
  [key: string]: string | number | boolean | null
}

interface MemberSeries {
  senninshoA: number[]
  gunnishoA: number[]
  sanbyakunishoA: number[]
  hyakuninshoA: number[]
  jucchoA: number[]
  presidentA: number[]
}

interface ProjectInput {
  businessDays: number[]
  presidentSales: number[]
  memberSales?: number[]
  hoursByMember: MemberSeries
  memberUnitPrice: MemberSeries
  avgUnitPrice?: number[]
}

interface CommentOverlayState {
  visible: boolean
  x: number
  y: number
  title: string
  body: string
  key: string
}

const scaleOptions = [100, 90, 80, 70]
const viewScale = ref(100)
const projects: ProjectName[] = ['案件A', '案件B', '案件C', '案件D', '案件E']
const activeProject = ref<ProjectName>('案件A')
const yearOrder: YearLabel[] = ['2024', '2025', '2026', '2027']

const months: MonthDef[] = yearOrder.flatMap(year =>
  Array.from({ length: 12 }, (_, idx) => {
    const monthNum = idx + 1
    const month = String(monthNum).padStart(2, '0')
    return {
      key: `y${year}_${month}`,
      year,
      monthLabel: `${monthNum}月`,
      quarterLabel: year === '2025' && monthNum === 7 ? '4半期' : ''
    }
  })
)

const dataMonthKeys = [
  ...Array.from({ length: 12 }, (_, i) => `y2025_${String(i + 1).padStart(2, '0')}`),
  ...Array.from({ length: 3 }, (_, i) => `y2026_${String(i + 1).padStart(2, '0')}`)
]

const seriesLength = dataMonthKeys.length
const zeroSeries = () => Array.from({ length: seriesLength }, () => 0)
const emptyCommentOverlay = (): CommentOverlayState => ({
  visible: false,
  x: 0,
  y: 0,
  title: '',
  body: '',
  key: ''
})

const createMemberSeries = (partial: Partial<MemberSeries>): MemberSeries => ({
  senninshoA: partial.senninshoA ?? zeroSeries(),
  gunnishoA: partial.gunnishoA ?? zeroSeries(),
  sanbyakunishoA: partial.sanbyakunishoA ?? zeroSeries(),
  hyakuninshoA: partial.hyakuninshoA ?? zeroSeries(),
  jucchoA: partial.jucchoA ?? zeroSeries(),
  presidentA: partial.presidentA ?? zeroSeries()
})

const projectInputs: Record<ProjectName, ProjectInput> = {
  案件A: {
    businessDays: [19, 18, 20, 21, 20, 21, 22, 20, 20, 22, 18, 20, 20, 19, 20],
    presidentSales: [100000, 200000, 100000, 100000, 510000, 150000, 100000, 100000, 150000, 260000, 100000, 100000, 120000, 130000, 110000],
    avgUnitPrice: [5583, 5583, 5583, 5583, 5583, 5583, 5583, 5583, 5583, 5583, 6000, 6000, 6000, 6000, 6000],
    hoursByMember: {
      senninshoA: [88, 64, 72, 77, 81, 74, 85, 74, 40, 90, 59, 82, 76, 70, 88],
      gunnishoA: [105, 123, 127, 124, 147, 142, 104, 85, 46, 0, 0, 0, 95, 102, 110],
      sanbyakunishoA: [152, 147, 158, 124, 133, 134, 157, 126, 119, 150, 132, 148, 140, 136, 142],
      hyakuninshoA: [115, 113, 118, 136, 141, 137, 137, 148, 113, 133, 117, 140, 130, 128, 132],
      jucchoA: [84, 126, 158, 118, 168, 130, 141, 127, 115, 146, 110, 145, 136, 129, 138],
      presidentA: [10, 20, 10, 10, 51, 15, 10, 10, 15, 26, 10, 10, 18, 16, 12]
    },
    memberUnitPrice: {
      senninshoA: [5500, 5500, 5500, 5500, 5500, 5500, 5500, 5500, 5500, 5500, 6500, 6500, 6500, 6500, 6500],
      gunnishoA: [5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000],
      sanbyakunishoA: [5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5500, 5500, 5500, 5500, 5500],
      hyakuninshoA: [4000, 4000, 4000, 4000, 4000, 4000, 4000, 4000, 4000, 4000, 4500, 4500, 4500, 4500, 4500],
      jucchoA: [4000, 4000, 4000, 4000, 4000, 4000, 4000, 4000, 4000, 4000, 4500, 4500, 4500, 4500, 4500],
      presidentA: [10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000]
    }
  },
  案件B: {
    businessDays: [20, 20, 18, 19, 21, 20, 21, 20, 18, 20, 19, 20, 20, 19, 20],
    presidentSales: zeroSeries(),
    memberSales: [280000, 320000, 300000, 360000, 420000, 400000, 450000, 380000, 340000, 520000, 470000, 510000, 560000, 530000, 590000],
    hoursByMember: createMemberSeries({
      gunnishoA: [45, 49, 47, 53, 58, 55, 60, 52, 50, 66, 61, 64, 69, 66, 72],
      hyakuninshoA: [30, 33, 31, 36, 40, 38, 41, 35, 33, 45, 40, 43, 46, 44, 48]
    }),
    memberUnitPrice: createMemberSeries({
      gunnishoA: Array.from({ length: seriesLength }, () => 5200),
      hyakuninshoA: Array.from({ length: seriesLength }, () => 3900)
    })
  },
  案件C: {
    businessDays: [19, 20, 20, 18, 20, 19, 20, 21, 20, 19, 18, 20, 20, 20, 19],
    presidentSales: zeroSeries(),
    memberSales: [220000, 240000, 260000, 290000, 310000, 340000, 360000, 390000, 410000, 430000, 450000, 470000, 500000, 520000, 540000],
    hoursByMember: createMemberSeries({
      sanbyakunishoA: [38, 40, 42, 45, 47, 49, 50, 53, 55, 57, 59, 61, 64, 66, 68],
      jucchoA: [22, 24, 25, 28, 29, 31, 33, 35, 36, 38, 40, 42, 44, 45, 47]
    }),
    memberUnitPrice: createMemberSeries({
      sanbyakunishoA: Array.from({ length: seriesLength }, () => 5300),
      jucchoA: Array.from({ length: seriesLength }, () => 4100)
    })
  },
  案件D: {
    businessDays: [20, 19, 20, 20, 19, 21, 20, 19, 20, 20, 21, 20, 20, 19, 21],
    presidentSales: zeroSeries(),
    memberSales: [260000, 300000, 330000, 360000, 390000, 420000, 450000, 480000, 510000, 540000, 560000, 580000, 600000, 590000, 600000],
    hoursByMember: createMemberSeries({
      senninshoA: [34, 39, 42, 45, 49, 53, 56, 60, 64, 67, 69, 71, 73, 72, 74],
      presidentA: [18, 19, 20, 22, 23, 24, 26, 28, 29, 30, 31, 32, 33, 32, 33]
    }),
    memberUnitPrice: createMemberSeries({
      senninshoA: Array.from({ length: seriesLength }, () => 6000),
      presidentA: Array.from({ length: seriesLength }, () => 5000)
    })
  },
  案件E: {
    businessDays: [18, 19, 20, 19, 20, 20, 19, 20, 21, 20, 20, 19, 20, 20, 21],
    presidentSales: zeroSeries(),
    memberSales: [240000, 260000, 280000, 310000, 330000, 350000, 380000, 400000, 420000, 440000, 460000, 500000, 540000, 560000, 580000],
    hoursByMember: createMemberSeries({
      gunnishoA: [30, 33, 35, 38, 40, 42, 45, 47, 49, 52, 54, 57, 61, 63, 65],
      sanbyakunishoA: [24, 25, 27, 29, 31, 33, 35, 37, 38, 40, 42, 45, 48, 50, 53]
    }),
    memberUnitPrice: createMemberSeries({
      gunnishoA: Array.from({ length: seriesLength }, () => 4700),
      sanbyakunishoA: Array.from({ length: seriesLength }, () => 4300)
    })
  }
}

const cellComments: Record<string, string> = {
  'cost:販管費:y2025_09': [
    '樹理（経理） 17:33 12月24日',
    '',
    'kaigi on rails2025に関わる諸経費',
    '381,093円を参加者が担当する各Rails案件の',
    '稼働時間に応じて按分する。'
  ].join('\n'),
  'summary:売上高(税抜):y2025_11': [
    '経営企画 09:15 11月30日',
    '',
    '展示会案件の追加発注分を含む。',
    '11月請求は検収済み。'
  ].join('\n'),
  'hours:千人将A:y2025_10': [
    'PM 18:10 10月28日',
    '',
    '別案件応援のため当月の稼働は0h。',
    '11月から復帰予定。'
  ].join('\n')
}

const contextMenuState = ref({
  visible: false,
  x: 0,
  y: 0,
  row: null as RowItem | null,
  colId: ''
})
const hoverComment = ref<CommentOverlayState>(emptyCommentOverlay())
const pinnedComment = ref<CommentOverlayState>(emptyCommentOverlay())

const toMonthRecord = (values: number[]): Record<string, number | null> =>
  dataMonthKeys.reduce<Record<string, number | null>>((acc, key, index) => {
    acc[key] = values[index] ?? null
    return acc
  }, months.reduce<Record<string, number | null>>((acc, month) => {
    acc[month.key] = null
    return acc
  }, {}))

const createRow = (
  id: string,
  itemName: string,
  level: number,
  format: FormatType,
  values: number[],
  group: RowGroup,
  isGroupHeader = false,
  isSpacer = false
): RowItem => ({
  id,
  itemName,
  level,
  format,
  group,
  isGroupHeader,
  isSpacer,
  ...toMonthRecord(values)
})

const buildRowsForProject = (projectInput: ProjectInput): RowItem[] => {
  const totalHours = dataMonthKeys.map((_, index) =>
    projectInput.hoursByMember.senninshoA[index]
    + projectInput.hoursByMember.gunnishoA[index]
    + projectInput.hoursByMember.sanbyakunishoA[index]
    + projectInput.hoursByMember.hyakuninshoA[index]
    + projectInput.hoursByMember.jucchoA[index]
    + projectInput.hoursByMember.presidentA[index]
  )

  const memberSales = projectInput.memberSales
    ?? dataMonthKeys.map((_, index) => Math.round(totalHours[index] * (projectInput.avgUnitPrice?.[index] ?? 0)))
  const presidentSales = projectInput.presidentSales
  const netSales = dataMonthKeys.map((_, index) => memberSales[index] + presidentSales[index])
  const averageUnitPrice = projectInput.avgUnitPrice
    ?? dataMonthKeys.map((_, index) => (totalHours[index] > 0 ? Math.round(memberSales[index] / totalHours[index]) : 0))

  const laborCostPresident = dataMonthKeys.map((_, index) => Math.round(presidentSales[index] * 0.58))
  const laborCostMembers = dataMonthKeys.map((_, index) => Math.round(memberSales[index] * 0.61))
  const laborCostTotal = dataMonthKeys.map((_, index) => laborCostPresident[index] + laborCostMembers[index])
  const costRate = dataMonthKeys.map((_, index) => (netSales[index] > 0 ? laborCostTotal[index] / netSales[index] : 0))
  const grossProfit = dataMonthKeys.map((_, index) => netSales[index] - laborCostTotal[index])

  const totalSga = dataMonthKeys.map((_, index) => Math.round(netSales[index] * 0.16))
  const projectSga = dataMonthKeys.map((_, index) => Math.round(netSales[index] * 0.12))
  const sgaRate = dataMonthKeys.map((_, index) => (netSales[index] > 0 ? projectSga[index] / netSales[index] : 0))
  const projectOperatingProfit = dataMonthKeys.map((_, index) => grossProfit[index] - projectSga[index])
  const projectOperatingProfitRate = dataMonthKeys.map((_, index) => (netSales[index] > 0 ? projectOperatingProfit[index] / netSales[index] : 0))
  const operatingProfit = dataMonthKeys.map((_, index) => projectOperatingProfit[index] - totalSga[index])
  const operatingProfitRate = dataMonthKeys.map((_, index) => (netSales[index] > 0 ? operatingProfit[index] / netSales[index] : 0))
  const maxTheoreticalSales = dataMonthKeys.map((_, index) => Math.round(totalHours[index] * 6500))
  const collectionRate = dataMonthKeys.map((_, index) => (maxTheoreticalSales[index] > 0 ? netSales[index] / maxTheoreticalSales[index] : 0))

  return [
    createRow('summary:営業日数', '営業日数', 0, 'number', projectInput.businessDays, 'summary'),
    createRow('summary:売上高(税抜)', '売上高(税抜)', 0, 'currency', netSales, 'summary'),
    createRow('summary:代表A売上', '代表A売上', 0, 'currency', presidentSales, 'summary'),
    createRow('summary:メンバー売上', 'メンバー売上', 0, 'currency', memberSales, 'summary'),
    createRow('summary:平均単価', '平均単価', 0, 'currency', averageUnitPrice, 'summary'),
    createRow('summary:メンバー総稼働量(h)', 'メンバー総稼働量(h)', 0, 'number', totalHours, 'summary'),
    createRow('memberPrice:メンバー別単価', 'メンバー別単価', 0, 'blank', zeroSeries(), 'memberPrice', true),
    createRow('memberPrice:三千人将A', '三千人将A', 1, 'currency', projectInput.memberUnitPrice.senninshoA, 'memberPrice'),
    createRow('memberPrice:千人将A', '千人将A', 1, 'currency', projectInput.memberUnitPrice.gunnishoA, 'memberPrice'),
    createRow('memberPrice:三百人将A', '三百人将A', 1, 'currency', projectInput.memberUnitPrice.sanbyakunishoA, 'memberPrice'),
    createRow('memberPrice:百人将A', '百人将A', 1, 'currency', projectInput.memberUnitPrice.hyakuninshoA, 'memberPrice'),
    createRow('memberPrice:什長A', '什長A', 1, 'currency', projectInput.memberUnitPrice.jucchoA, 'memberPrice'),
    createRow('memberPrice:代表A', '代表A', 1, 'currency', projectInput.memberUnitPrice.presidentA, 'memberPrice'),
    createRow('cost:売上原価(人件費)', '売上原価(人件費)', 0, 'currency', laborCostTotal, 'cost', true),
    createRow('cost:代表A原価', '代表A原価', 1, 'currency', laborCostPresident, 'cost'),
    createRow('cost:メンバー原価', 'メンバー原価', 1, 'currency', laborCostMembers, 'cost'),
    createRow('cost:原価率', '原価率', 0, 'percent', costRate, 'cost'),
    createRow('cost:売上総利益(粗利)', '売上総利益(粗利)', 0, 'currency', grossProfit, 'cost'),
    createRow('cost:全体販管費', '全体販管費', 0, 'currency', totalSga, 'cost'),
    createRow('cost:販管費', '販管費', 0, 'currency', projectSga, 'cost'),
    createRow('cost:販管費比率', '販管費比率', 0, 'percent', sgaRate, 'cost'),
    createRow('cost:案件単体営業利益', '案件単体営業利益', 0, 'currency', projectOperatingProfit, 'cost'),
    createRow('cost:案件単体営業利益率', '案件単体営業利益率', 0, 'percent', projectOperatingProfitRate, 'cost'),
    createRow('cost:営業利益', '営業利益', 0, 'currency', operatingProfit, 'cost'),
    createRow('cost:営業利益率', '営業利益率', 0, 'percent', operatingProfitRate, 'cost'),
    createRow('cost:最大売上高(理論値)', '最大売上高(理論値)', 0, 'currency', maxTheoreticalSales, 'cost'),
    createRow('cost:回収率', '回収率', 0, 'percent', collectionRate, 'cost'),
    createRow('spacer:blank', ' ', 0, 'blank', zeroSeries(), 'spacer', false, true),
    createRow('hours:稼働時間数', '稼働時間数', 0, 'number', totalHours, 'hours', true),
    createRow('hours:三千人将A', '三千人将A', 1, 'number', projectInput.hoursByMember.senninshoA, 'hours'),
    createRow('hours:千人将A', '千人将A', 1, 'number', projectInput.hoursByMember.gunnishoA, 'hours'),
    createRow('hours:三百人将A', '三百人将A', 1, 'number', projectInput.hoursByMember.sanbyakunishoA, 'hours'),
    createRow('hours:百人将A', '百人将A', 1, 'number', projectInput.hoursByMember.hyakuninshoA, 'hours'),
    createRow('hours:什長A', '什長A', 1, 'number', projectInput.hoursByMember.jucchoA, 'hours'),
    createRow('hours:代表A', '代表A', 1, 'number', projectInput.hoursByMember.presidentA, 'hours')
  ]
}

const rows = computed(() => buildRowsForProject(projectInputs[activeProject.value]))

const getComment = (row: RowItem | undefined, field: string | undefined) => {
  if (activeProject.value !== '案件A') return ''
  if (!row || !field) return ''
  return cellComments[`${row.id}:${field}`] ?? ''
}

const splitComment = (comment: string) => {
  const lines = comment.split('\n')
  return {
    title: lines[0] ?? '',
    body: lines.slice(2).join('\n')
  }
}

const calcPopoverPosition = (anchor: DOMRect) => {
  const width = 390
  const height = 230
  const left = Math.min(anchor.right + 12, window.innerWidth - width - 12)
  const top = Math.min(anchor.top, window.innerHeight - height - 12)
  return { x: Math.max(8, left), y: Math.max(8, top) }
}

const closeHoverComment = () => {
  hoverComment.value = emptyCommentOverlay()
}

const closePinnedComment = () => {
  pinnedComment.value = emptyCommentOverlay()
}

const closeAllComments = () => {
  closeHoverComment()
  closePinnedComment()
}

const openCommentPopover = (mode: 'hover' | 'pinned', row: RowItem, colId: string, anchor: DOMRect) => {
  const comment = getComment(row, colId)
  if (!comment) return

  const key = `${row.id}:${colId}`
  const { title, body } = splitComment(comment)
  const { x, y } = calcPopoverPosition(anchor)
  const next: CommentOverlayState = { visible: true, x, y, title, body, key }

  if (mode === 'hover') {
    if (pinnedComment.value.visible && pinnedComment.value.key === key) return
    hoverComment.value = next
  } else {
    pinnedComment.value = next
    hoverComment.value = emptyCommentOverlay()
  }
}

const monthLabelByKey = months.reduce<Record<string, string>>((acc, month) => {
  acc[month.key] = `${month.year}年${month.monthLabel}`
  return acc
}, {})

const yen = new Intl.NumberFormat('ja-JP', {
  style: 'currency',
  currency: 'JPY',
  maximumFractionDigits: 0
})

const integer = new Intl.NumberFormat('ja-JP', {
  maximumFractionDigits: 0
})

const percent = new Intl.NumberFormat('ja-JP', {
  style: 'percent',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
})

const valueFormatter = (params: ValueFormatterParams<RowItem, number | null>) => {
  if (!params.data || params.data.format === 'blank') return ''
  if (params.value === null || params.value === undefined) return ''
  if (params.data.format === 'currency') return yen.format(params.value)
  if (params.data.format === 'percent') return percent.format(params.value)
  return integer.format(params.value)
}

const monthCellRenderer = (monthKey: string) => (params: ICellRendererParams<RowItem, number | null>) => {
  const wrapper = document.createElement('div')
  wrapper.className = 'metric-cell-wrap'

  const value = document.createElement('span')
  value.className = 'metric-cell-value'
  value.textContent = `${params.valueFormatted ?? ''}`
  wrapper.appendChild(value)

  if (getComment(params.data, monthKey)) {
    const pin = document.createElement('button')
    pin.type = 'button'
    pin.className = 'comment-pin-btn'
    pin.title = 'メモを固定表示'
    pin.textContent = '🗨'
    wrapper.appendChild(pin)
  }

  return wrapper
}

const monthColDef = (month: MonthDef): ColDef<RowItem> => ({
  field: month.key,
  headerName: month.monthLabel,
  width: 138,
  type: 'numericColumn',
  valueFormatter,
  cellRenderer: monthCellRenderer(month.key),
  cellClass: params => {
    const classes: string[] = []
    if (params.data?.format === 'currency') classes.push('cell-currency')
    if (params.data?.format === 'percent') classes.push('cell-percent')
    if (params.data?.format === 'number') classes.push('cell-number')
    if (getComment(params.data, month.key)) classes.push('cell-has-comment')
    return classes.join(' ')
  }
})

const yearColumn = (year: YearLabel): ColGroupDef<RowItem> => ({
  headerName: `${year}年`,
  children: months
    .filter(month => month.year === year)
    .map(month => ({
      headerName: month.quarterLabel,
      children: [monthColDef(month)]
    }))
})

const columnDefs = computed<Array<ColDef<RowItem> | ColGroupDef<RowItem>>>(() => [
  {
    field: 'itemName',
    headerName: '項目',
    pinned: 'left',
    lockPinned: true,
    width: 290,
    suppressMovable: true,
    cellClass: params => {
      if (params.data?.isSpacer) return 'row-label-spacer'
      return params.data?.level === 0 ? 'row-label-main' : 'row-label-child'
    },
    valueFormatter: params => {
      const value = params.value ?? ''
      return params.data?.level === 1 ? `  ${value}` : value
    }
  },
  ...yearOrder.map(yearColumn)
])

const defaultColDef: ColDef<RowItem> = {
  editable: false,
  sortable: false,
  filter: false,
  suppressHeaderMenuButton: true,
  resizable: true,
  cellStyle: {
    textAlign: 'right'
  }
}

const getRowClass = (params: RowClassParams<RowItem>) => {
  const data = params.data
  if (!data) return ''
  const classes = [`row-group-${data.group}`]
  if (data.isGroupHeader) classes.push('row-group-header')
  if (data.isSpacer) classes.push('row-spacer')
  return classes.join(' ')
}

const gridShellStyle = computed(() => {
  const ratio = viewScale.value / 100
  return {
    transform: `scale(${ratio})`,
    transformOrigin: 'top left',
    width: `${100 / ratio}%`,
    height: `${100 / ratio}%`
  }
})

const copyText = async (text: string) => {
  if (!text) return
  try {
    await navigator.clipboard.writeText(text)
  } catch {
    // no-op
  }
}

const resolveCellValueText = (row: RowItem | null, colId: string) => {
  if (!row || !colId) return ''
  const value = row[colId]
  if (typeof value !== 'number') return ''

  if (row.format === 'currency') return yen.format(value)
  if (row.format === 'percent') return percent.format(value)
  return integer.format(value)
}

const closeContextMenu = () => {
  contextMenuState.value.visible = false
}

const onCellContextMenu = (event: CellContextMenuEvent<RowItem>) => {
  event.event?.preventDefault()
  if (!event.data || !event.column) return
  closeHoverComment()

  const mouse = event.event as MouseEvent
  const menuWidth = 260
  const menuHeight = 264
  const x = Math.min(mouse.clientX, window.innerWidth - menuWidth - 12)
  const y = Math.min(mouse.clientY, window.innerHeight - menuHeight - 12)

  contextMenuState.value = {
    visible: true,
    x: Math.max(8, x),
    y: Math.max(8, y),
    row: event.data,
    colId: event.column.getColId()
  }
}

const onCellMouseOver = (event: CellMouseOverEvent<RowItem>) => {
  if (!event.data || !event.column || pinnedComment.value.visible) return
  const target = event.event?.target as HTMLElement | null
  const cell = target?.closest('.ag-cell') as HTMLElement | null
  if (!cell) return
  openCommentPopover('hover', event.data, event.column.getColId(), cell.getBoundingClientRect())
}

const onCellMouseOut = (_event: CellMouseOutEvent<RowItem>) => {
  closeHoverComment()
}

const onCellClicked = (event: CellClickedEvent<RowItem>) => {
  const target = event.event?.target as HTMLElement | null
  const pinBtn = target?.closest('.comment-pin-btn') as HTMLElement | null
  if (!pinBtn || !event.data || !event.column) return

  event.event?.preventDefault()
  event.event?.stopPropagation()

  const key = `${event.data.id}:${event.column.getColId()}`
  if (pinnedComment.value.visible && pinnedComment.value.key === key) {
    closePinnedComment()
    return
  }

  openCommentPopover('pinned', event.data, event.column.getColId(), pinBtn.getBoundingClientRect())
}

const onMenuAction = async (action: 'copy-value' | 'copy-row' | 'copy-col' | 'add-note') => {
  const { row, colId } = contextMenuState.value
  if (!row) return

  if (action === 'copy-value') {
    await copyText(resolveCellValueText(row, colId))
  } else if (action === 'copy-row') {
    await copyText(row.itemName)
  } else if (action === 'copy-col') {
    await copyText(monthLabelByKey[colId] ?? colId)
  } else if (action === 'add-note') {
    const key = `${row.id}:${colId}`
    const current = cellComments[key]
    const message = current
      ? `メモ（ダミー）\n\n${current}`
      : 'このセルにメモを追加する想定です（ダミー）。'
    window.alert(message)
  }

  closeContextMenu()
}

const onGlobalPointerDown = (event: PointerEvent) => {
  const target = event.target as HTMLElement | null
  if (!target?.closest('.context-menu')) {
    closeContextMenu()
  }

  if (!target?.closest('.comment-popover') && !target?.closest('.comment-pin-btn')) {
    closePinnedComment()
  }
}

const onGlobalKeydown = (event: KeyboardEvent) => {
  if (event.key !== 'Escape') return
  closeContextMenu()
  closeAllComments()
}

onMounted(() => {
  window.addEventListener('pointerdown', onGlobalPointerDown)
  window.addEventListener('keydown', onGlobalKeydown)
  window.addEventListener('scroll', closeContextMenu, true)
  window.addEventListener('scroll', closeAllComments, true)
})

onBeforeUnmount(() => {
  window.removeEventListener('pointerdown', onGlobalPointerDown)
  window.removeEventListener('keydown', onGlobalKeydown)
  window.removeEventListener('scroll', closeContextMenu, true)
  window.removeEventListener('scroll', closeAllComments, true)
})
</script>

<template>
  <main class="page">
    <header class="global-nav">
      <div class="brand">
        <span class="brand-mark">PL</span>
        <span class="brand-text">案件別収益（P/L）分析</span>
      </div>
      <nav class="menu-links">
        <button class="menu-link">ダッシュボード</button>
        <button class="menu-link menu-link-active">案件</button>
        <button class="menu-link">従業員</button>
        <button class="menu-link">レポート</button>
        <button class="menu-link">設定</button>
      </nav>
      <div class="menu-actions">
        <button class="icon-btn">通知</button>
        <button class="icon-btn">管理者</button>
      </div>
    </header>

    <section class="canvas">
      <div class="header-row">
        <h1>案件別月次売上サマリー（{{ activeProject }}）</h1>
        <label class="scale-control">
          <span>表示倍率</span>
          <select v-model.number="viewScale">
            <option v-for="option in scaleOptions" :key="option" :value="option">{{ option }}%</option>
          </select>
        </label>
      </div>

      <div class="project-switcher">
        <span class="switcher-label">案件切替</span>
        <button
          v-for="project in projects"
          :key="project"
          class="project-btn"
          :class="{ 'project-btn-active': project === activeProject }"
          @click="activeProject = project"
        >
          {{ project }}
        </button>
      </div>

      <div class="grid-stage">
        <div class="grid-shell" :style="gridShellStyle">
          <div class="ag-theme-alpine grid-wrap">
            <AgGridVue
              class="grid"
              :columnDefs="columnDefs"
              :rowData="rows"
              :defaultColDef="defaultColDef"
              :getRowClass="getRowClass"
              :rowHeight="36"
              :headerHeight="34"
              :groupHeaderHeight="34"
              @cell-mouse-over="onCellMouseOver"
              @cell-mouse-out="onCellMouseOut"
              @cell-clicked="onCellClicked"
              @cell-context-menu="onCellContextMenu"
            />
          </div>
        </div>
      </div>
    </section>

    <div
      v-if="contextMenuState.visible"
      class="context-menu"
      :style="{ left: `${contextMenuState.x}px`, top: `${contextMenuState.y}px` }"
      @contextmenu.prevent
    >
      <button class="context-item" @click="onMenuAction('copy-value')">コピー</button>
      <button class="context-item" @click="onMenuAction('copy-row')">行名をコピー</button>
      <button class="context-item" @click="onMenuAction('copy-col')">列見出しをコピー</button>
      <div class="context-divider" />
      <button class="context-item" @click="onMenuAction('add-note')">メモを挿入（ダミー）</button>
    </div>

    <div
      v-if="hoverComment.visible"
      class="comment-popover"
      :style="{ left: `${hoverComment.x}px`, top: `${hoverComment.y}px` }"
    >
      <div class="comment-title">{{ hoverComment.title }}</div>
      <div class="comment-body">{{ hoverComment.body }}</div>
    </div>

    <div
      v-if="pinnedComment.visible"
      class="comment-popover comment-popover-pinned"
      :style="{ left: `${pinnedComment.x}px`, top: `${pinnedComment.y}px` }"
    >
      <div class="comment-head">
        <div class="comment-title">{{ pinnedComment.title }}</div>
        <button class="comment-close" @click="closePinnedComment">閉じる</button>
      </div>
      <div class="comment-body">{{ pinnedComment.body }}</div>
    </div>
  </main>
</template>

<style scoped>
.page {
  min-height: 100vh;
  padding: 20px;
  background: #f2f3f5;
}

.global-nav {
  max-width: 1500px;
  margin: 0 auto 12px;
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
  border: none;
  background: transparent;
  color: #4b515d;
  font-size: 15px;
  font-weight: 700;
  padding: 10px 14px;
  border-radius: 8px;
  cursor: pointer;
}

.menu-link-active {
  color: #2565c7;
  background: #eaf1ff;
}

.menu-actions {
  display: flex;
  gap: 8px;
}

.icon-btn {
  border: 1px solid #d0d5dd;
  background: #fff;
  color: #344054;
  font-size: 12px;
  font-weight: 700;
  border-radius: 8px;
  padding: 8px 10px;
  cursor: pointer;
}

.canvas {
  max-width: 1500px;
  margin: 0 auto;
  padding: 18px 18px 16px;
  background: #ffffff;
  border: 1px solid #d6d8dd;
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(28, 37, 54, 0.08);
}

.header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 12px;
}

h1 {
  margin: 0;
  color: #111;
  font-size: 46px;
  letter-spacing: 0.01em;
  font-weight: 700;
}

.scale-control {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #3a3a3a;
  font-size: 14px;
  font-weight: 600;
}

.scale-control select {
  appearance: none;
  border: 1px solid #c4c8d0;
  background: #fff;
  color: #111;
  border-radius: 8px;
  padding: 8px 30px 8px 10px;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
}

.project-switcher {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
  flex-wrap: wrap;
}

.switcher-label {
  font-size: 13px;
  font-weight: 700;
  color: #535862;
  margin-right: 4px;
}

.project-btn {
  border: 1px solid #c4c8d0;
  background: #fff;
  color: #344054;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 700;
  padding: 7px 14px;
  cursor: pointer;
}

.project-btn-active {
  border-color: #3f7dd4;
  background: #3f7dd4;
  color: #fff;
}

.grid-stage {
  height: calc(100vh - 210px);
  min-height: 620px;
  overflow: auto;
  border-radius: 6px;
}

.grid-shell {
  width: 100%;
  height: 100%;
}

.grid-wrap {
  width: 100%;
  height: 100%;
  min-height: 620px;
  border: 1px solid #b8b8b8;
  border-radius: 4px;
  overflow: hidden;
  background: #fff;
}

.grid {
  width: 100%;
  height: 100%;
}

:deep(.ag-root-wrapper) {
  border: none;
}

:deep(.ag-header) {
  background: #666;
  border-bottom: 1px solid #5b5b5b;
}

:deep(.ag-header-cell),
:deep(.ag-header-group-cell) {
  background: #666;
  border-color: #5b5b5b;
}

:deep(.ag-header-cell-label),
:deep(.ag-header-group-cell-label) {
  color: #ffef00;
  font-weight: 700;
}

:deep(.ag-cell) {
  border-color: #d9d9d9;
  color: #111;
  font-variant-numeric: tabular-nums;
  background: #fff;
}

:deep(.ag-cell.row-label-main),
:deep(.ag-cell.row-label-child) {
  background: #666;
  color: #ffef00;
  text-align: left;
  font-weight: 700;
}

:deep(.ag-cell.row-label-child) {
  font-weight: 600;
  background: #707070;
}

:deep(.ag-cell.row-label-spacer) {
  background: #666;
}

:deep(.ag-row.row-group-header .ag-cell:not(.row-label-main):not(.row-label-child):not(.row-label-spacer)) {
  background: #f0f5ff;
  font-weight: 700;
}

:deep(.ag-row.row-group-memberPrice .ag-cell.row-label-main),
:deep(.ag-row.row-group-memberPrice .ag-cell.row-label-child) {
  background: #5f6f8a;
}

:deep(.ag-row.row-group-cost .ag-cell.row-label-main),
:deep(.ag-row.row-group-cost .ag-cell.row-label-child) {
  background: #6d6b58;
}

:deep(.ag-row.row-group-hours .ag-cell.row-label-main),
:deep(.ag-row.row-group-hours .ag-cell.row-label-child) {
  background: #5f7161;
}

:deep(.ag-row.row-group-memberPrice.row-group-header .ag-cell),
:deep(.ag-row.row-group-cost.row-group-header .ag-cell),
:deep(.ag-row.row-group-hours.row-group-header .ag-cell) {
  border-top-width: 2px;
  border-top-color: #9ba7c1;
}

:deep(.ag-row.row-spacer .ag-cell) {
  height: 20px;
  background: #f5f5f5;
  border-top-color: #ececec;
  border-bottom-color: #ececec;
}

:deep(.ag-pinned-left-cols-container) {
  border-right: 2px solid #8f8f8f;
}

:deep(.cell-currency),
:deep(.cell-number),
:deep(.cell-percent) {
  font-weight: 600;
}

:deep(.metric-cell-wrap) {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 4px;
}

:deep(.metric-cell-value) {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

:deep(.comment-pin-btn) {
  border: none;
  background: transparent;
  color: #4b5563;
  cursor: pointer;
  font-size: 12px;
  line-height: 1;
  padding: 0;
  opacity: 0.75;
}

:deep(.comment-pin-btn:hover) {
  opacity: 1;
}

:deep(.ag-cell.cell-has-comment) {
  position: relative;
}

:deep(.ag-cell.cell-has-comment::after) {
  content: '';
  position: absolute;
  top: 1px;
  right: 1px;
  width: 0;
  height: 0;
  border-top: 10px solid #f4c430;
  border-left: 10px solid transparent;
}

.context-menu {
  position: fixed;
  z-index: 2000;
  min-width: 250px;
  background: #f1f1f1;
  border: 1px solid #cfcfcf;
  border-radius: 10px;
  box-shadow: 0 18px 40px rgba(0, 0, 0, 0.22);
  padding: 8px;
}

.context-item {
  width: 100%;
  text-align: left;
  border: none;
  background: transparent;
  color: #1a1a1a;
  font-size: 16px;
  font-weight: 500;
  padding: 10px 12px;
  border-radius: 8px;
  cursor: pointer;
}

.context-item:hover {
  background: #e5e7eb;
}

.context-divider {
  height: 1px;
  background: #d4d4d4;
  margin: 6px 2px;
}

.comment-popover {
  position: fixed;
  z-index: 2100;
  width: 380px;
  max-width: calc(100vw - 20px);
  padding: 14px 16px;
  border: 1px solid #c9d0da;
  border-radius: 12px;
  background: #eef2f7;
  color: #2b3440;
  box-shadow: 0 10px 24px rgba(17, 24, 39, 0.22);
  line-height: 1.5;
  white-space: pre-line;
  font-size: 16px;
}

.comment-popover-pinned {
  border-color: #9fb3d8;
  box-shadow: 0 14px 30px rgba(17, 24, 39, 0.28);
}

.comment-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.comment-title {
  font-size: 0.95em;
  font-weight: 700;
  color: #596273;
  margin-bottom: 8px;
}

.comment-body {
  font-size: 1em;
  color: #303945;
}

.comment-close {
  border: 1px solid #c2cbd8;
  background: #fff;
  color: #4b5563;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 700;
  padding: 4px 8px;
  cursor: pointer;
}

@media (max-width: 1200px) {
  .page {
    padding: 12px;
  }

  .global-nav {
    flex-wrap: wrap;
  }

  .brand-text {
    font-size: 24px;
  }

  .canvas {
    padding: 12px;
  }

  h1 {
    font-size: 30px;
  }

  .grid-stage {
    height: calc(100vh - 160px);
    min-height: 560px;
  }

  .grid-wrap {
    min-height: 560px;
  }
}
</style>
