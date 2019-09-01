import constants from '../constants'

const uuidv4 = require('uuid/v4')
export default {
  userToken () {
    return localStorage.getItem('user-token') || localStorage.setItem('user-token', uuidv4())
  },
  createStepStatus () {
    return new Array(constants.STEPS.length).fill(false)
  },
  outsampleMax (nobs, insampleMinSize, expvars, intercept) {
    var max = nobs - insampleMinSize - expvars.length - ((intercept) ? 1 : 0)
    return (max >= 0) ? max : 0
  },
  createInputDataState () {
    return {
      nworkers: null,
      operationId: null
    }
  },
  createServerState () {
    return {
      datanames: [],
      nobs: null
    }
  },
  createGSRegOptionsState () {
    return {
      depvar: null,
      expvars: [],
      intercept: false,
      time: null,
      residualtest: null,
      ttest: null,
      orderresults: null,
      modelavg: null,
      outsample: 0,
      csv: null,
      method: 'fast',
      paraprocs: 1,
      criteria: []
    }
  }
}
