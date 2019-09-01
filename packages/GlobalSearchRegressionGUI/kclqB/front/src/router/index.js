import Vue from 'vue'
import Router from 'vue-router'
import Wizard from '@/components/Wizard'

Vue.use(Router)

export default new Router({
  mode: 'history',
  routes: [
    {
      path: '/',
      name: 'wizard',
      component: Wizard
    }
  ]
})
