// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue'
import App from './App'
import router from './router'
import store from './store'
import constants from './constants'
import utils from './utils'

import VueNativeSock from 'vue-native-websocket'
import VueResource from 'vue-resource'

import BootstrapVue from 'bootstrap-vue'
import { library } from '@fortawesome/fontawesome-svg-core'
import { faDatabase, faFlask, faCog, faSpinner, faDownload, faClipboardList, faFile, faUpload, faChevronLeft, faChevronRight, faExclamationTriangle } from '@fortawesome/free-solid-svg-icons'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import VueMaterial from 'vue-material'
import 'vue-material/dist/vue-material.min.css'
import 'vue-material/dist/theme/default.css'

Vue.config.productionTip = false
Vue.prototype.$constants = constants
Vue.use(VueNativeSock, constants.WS.url, { format: 'json' })

library.add(faDatabase, faDownload, faFlask, faCog, faSpinner, faClipboardList, faFile, faUpload, faChevronLeft, faChevronRight, faExclamationTriangle)
Vue.component('font-awesome-icon', FontAwesomeIcon)

Vue.use(VueResource)
Vue.use(VueMaterial)

Vue.http.interceptors.push(function (request) {
  request.headers.set('X-User-Token', utils.userToken())
})

/* eslint-disable no-new */
new Vue({
  el: '#app',
  router,
  store,
  template: '<App/>',
  components: { App, BootstrapVue, VueMaterial }
})
