import { createRouter, createWebHistory } from 'vue-router'
import ProjectAnalysisView from './views/ProjectAnalysisView.vue'
import MasterDataView from './views/MasterDataView.vue'
import DashboardView from './views/DashboardView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: ProjectAnalysisView },
    { path: '/dashboard', component: DashboardView },
    { path: '/master-data', component: MasterDataView }
  ]
})

export default router
