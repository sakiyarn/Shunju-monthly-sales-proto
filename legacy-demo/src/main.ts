import { createApp } from 'vue'
import { AllCommunityModule, ModuleRegistry, provideGlobalGridOptions } from 'ag-grid-community'
import App from './App.vue'
import router from './router'
import './style.css'

ModuleRegistry.registerModules([AllCommunityModule])
provideGlobalGridOptions({ theme: 'legacy' })

createApp(App).use(router).mount('#app')
