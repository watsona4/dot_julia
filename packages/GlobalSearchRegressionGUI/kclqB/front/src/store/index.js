import Vuex from 'vuex'
import Vue from 'vue'
import utils from '../utils'

Vue.use(Vuex)
const state = {
  navHidden: false,
  currentStep: null,
  userToken: utils.userToken(),
  completeSteps: utils.createStepStatus(),
  setSteps: utils.createStepStatus(),
  paraprocs: 1,
  exportcsv: false,
  inputData: {
    datanames: [],
    nobs: null
  },
  server: {
    nworkers: null,
    ncores: null,
    operationId: null,
    resultId: null,
    juliaVersion: null,
    gsregVersion: null,
    jobQueue: {
      length: null
    }
  },
  depvar: null,
  expvars: [],
  csv: null,
  gsregOptions: {
    intercept: null,
    time: null,
    residualtest: null,
    ttest: null,
    orderresults: null,
    modelavg: null,
    outsample: 0,
    method: 'fast',
    criteria: []
  },
  bestResult: null,
  avgResults: null
}
const getters = {
  getInputDataDatanames (state) {
    return state.inputData.datanames
  },
  getInputDataNobs (state) {
    return state.inputData.nobs
  },
  getServerNworkers (state) {
    return state.server.nworkers
  },
  getServerNcores (state) {
    return state.server.ncores
  },
  getServerOperationId (state) {
    return state.server.operationId
  },
  getServerResultId (state) {
    return state.server.resultId
  },
  getGSRegOptionsDepvar (state) {
    return state.depvar
  },
  getGSRegOptionsExpvars (state) {
    return state.expvars
  },
  getGSRegOptionsIntercept (state) {
    return state.gsregOptions.intercept
  },
  getGSRegOptionsTime (state) {
    return state.gsregOptions.time
  },
  getGSRegOptionsResidualtest (state) {
    return state.gsregOptions.residualtest
  },
  getGSRegOptionsTtest (state) {
    return state.gsregOptions.ttest
  },
  getGSRegOptionsOrderresults (state) {
    return state.gsregOptions.orderresults
  },
  getGSRegOptionsModelavg (state) {
    return state.gsregOptions.modelavg
  },
  getGSRegOptionsOutsample (state) {
    return state.gsregOptions.outsample
  },
  getGSRegOptionsCsv (state) {
    return state.csv
  },
  getGSRegOptionsMethod (state) {
    return state.gsregOptions.method
  },
  getGSRegOptionsCriteria (state) {
    return state.gsregOptions.criteria
  }
}

const actions = {
  setGSRegOptionsDepvar ({commit, state}, depvar) {
    commit('setGSRegOptionsDepvar', depvar)
  },
  setGSRegOptionsExpvars ({commit, state}, expvars) {
    commit('setGSRegOptionsExpvars', expvars)
  },
  setStep ({commit, state}, step) {
    commit('setCurrentStep', step)
  },
  prevStep ({commit, state}) {
    commit('setCurrentStep', state.currentStep - 1)
  },
  nextStep ({commit, state}) {
    commit('setCurrentStep', state.currentStep + 1)
  },
  updateCompleteStep ({commit, payload}) {
    commit('updateCompleteStep', payload)
  },
  selectAllExplanatory ({commit}) {
    commit('selectAllExplanatory')
  },
  updateSetStep ({commit, payload}) {
    commit('updateSetStep', payload)
  }
}
const mutations = {
  restartOperation (state, payload) {
    // TODO: Delegate to utils
    var i
    for (i = 0; i < state.completeSteps.length; i++) {
      state.completeSteps[i] = false
    }
    for (i = 0; i < state.setSteps.length; i++) {
      state.setSteps[i] = false
    }
    state.inputData.datanames = []
    state.inputData.nobs = null
    state.server.operationId = null
    state.paraprocs = 1
    state.exportcsv = false
    state.depvar = null
    state.expvars = []
    // TODO: reset csv checkbox
    state.gsregOptions.intercept = false
    state.gsregOptions.time = null
    state.gsregOptions.residualtest = null
    state.gsregOptions.ttest = null
    state.gsregOptions.orderresults = null
    state.gsregOptions.modelavg = null
    state.gsregOptions.outsample = 0
    state.csv = null
    state.gsregOptions.method = 'fast'
    state.gsregOptions.criteria = []
    state.bestResult = null
    state.avgResults = null
  },
  setInputDataDatanames (state, datanames) {
    state.inputData.datanames = datanames
  },
  selectAllExplanatory (state) {
    state.expvars = state.inputData.datanames.filter(value => value !== state.depvar)
  },
  setInputDataNobs (state, nobs) {
    state.inputData.nobs = nobs
  },
  setServerNworkers (state, nworkers) {
    state.server.nworkers = nworkers
  },
  setServerNcores (state, ncores) {
    state.server.ncores = ncores
  },
  setServerJuliaVersion (state, juliaVersion) {
    state.server.juliaVersion = juliaVersion
  },
  setServerGsregVersion (state, gsregVersion) {
    state.server.gsregVersion = gsregVersion
  },
  setServerJobQueueLength (state, length) {
    state.server.jobQueue.length = length
  },
  setServerOperationId (state, operationId) {
    state.server.operationId = operationId
  },
  setServerResultId (state, resultId) {
    state.server.resultId = resultId
  },
  setGSRegOptionsDepvar (state, depvar) {
    state.depvar = depvar
  },
  setGSRegOptionsExpvars (state, expvars) {
    state.expvars = expvars
  },
  setGSRegOptionsCsv (state, csv) {
    state.csv = csv
  },
  setGSRegOptionsIntercept (state, intercept) {
    state.gsregOptions.intercept = intercept
  },
  setGSRegOptionsTime (state, time) {
    state.gsregOptions.time = time
  },
  setGSRegOptionsResidualtest (state, residualtest) {
    state.gsregOptions.residualtest = residualtest
  },
  setGSRegOptionsTtest (state, ttest) {
    state.gsregOptions.ttest = ttest
  },
  setGSRegOptionsOrderresults (state, orderresults) {
    state.gsregOptions.orderresults = orderresults
  },
  setGSRegOptionsModelavg (state, modelavg) {
    state.gsregOptions.modelavg = modelavg
  },
  setGSRegOptionsOutsample (state, outsample) {
    state.gsregOptions.outsample = parseInt(outsample)
  },
  setGSRegOptionsMethod (state, method) {
    state.gsregOptions.method = method
  },
  setGSRegOptionsCriteria (state, criteria) {
    state.gsregOptions.criteria = criteria
  },
  setNavHidden (state, navHidden) {
    state.navHidden = navHidden
  },
  setNavBlocked (state, navBlocked) {
    state.navBlocked = navBlocked
  },
  setCurrentStep (state, step) {
    state.currentStep = step
  },
  filterExpvars (state, depvar) {
    state.expvars = state.expvars.filter(e => e !== depvar)
  },
  filterTime (state, depvar) {
    state.gsregOptions.time = (state.gsregOptions.time !== depvar) ? state.gsregOptions.time : null
  },
  filterCriteria (state, outsample) {
    if (parseInt(outsample) === 0) {
      state.gsregOptions.criteria = state.gsregOptions.criteria.filter(e => e !== 'rmseout')
    }
  },
  updateCompleteStep (state, payload) {
    state.completeSteps[payload.step] = payload.complete
    var currentStep = state.currentStep
    state.currentStep = -1
    state.currentStep = currentStep
  },
  updateSetStep (state, payload) {
    state.setSteps[payload.step] = payload.set
    var currentStep = state.currentStep
    state.currentStep = -1
    state.currentStep = currentStep
  },
  setParaprocs (state, paraprocs) {
    state.paraprocs = parseInt(paraprocs)
  },
  setExportcsv (state, exportcsv) {
    state.exportcsv = exportcsv
  },
  setBestResult (state, bestResult) {
    state.bestResult = bestResult
  },
  setAvgResults (state, avgResults) {
    state.avgResults = avgResults
  }
}

export default new Vuex.Store({
  state,
  getters,
  actions,
  mutations,
  strict: false
})
