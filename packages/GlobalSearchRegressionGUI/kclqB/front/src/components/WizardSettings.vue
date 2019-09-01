<template>
  <div class="main">
    <h2>Settings</h2>
    <md-card>
      <md-card-header>
        <div class="md-title">Ordering criteria and additional tests</div>
      </md-card-header>
      <hr>
      <md-card-content>
        <div class="row">
          <div class="col">
            <div class="md-layout-item">
              <md-field>
                <label for="outsample" title="Number of out-of-sample observations">Out-of-sample observations</label>
                <md-input v-model="outsample" type="number" min="0" :max="outsampleMax" placeholder="Out-of-sample observations"></md-input>
              </md-field>
            </div>
          </div>
          <div class="col">
            <div class="md-layout-item">
              <md-field class="required-input">
                <label for="criteria" title="Ordering criteria">Ordering criteria</label>
                <md-select v-model="criteria" placeholder="Ordering criteria" multiple>
                  <md-option v-for="(criteria, index) in $constants.CRITERIA" :key="index" :value="index" :disabled="index==='rmseout' && parseInt(outsample)===0" >{{ criteria }}</md-option>
                </md-select>
              </md-field>
              <span class="md-caption required-label">Required</span>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col">
            <md-checkbox class="residualtest" v-model="residualtest" :checked="residualtest" title="Estimate residuals tests">Estimate residuals tests</md-checkbox>
          </div>
        </div>
        <div class="row">
          <div class="col">
            <md-checkbox class="ttest" v-model="ttest" :checked="ttest" title="Estimate t-test">Estimate t-test</md-checkbox>
          </div>
        </div>
      </md-card-content>
    </md-card>
    <md-card>
      <md-card-header>
        <div class="md-title">Processing options</div>
      </md-card-header>
      <hr>
      <md-card-content>
        <div class="row">
          <div class="col">
            <div class="md-layout-item">
              <md-field>
                <label for="paraprocs" title="Number of parallel workers">Number of parallel workers</label>
                <md-input v-model="paraprocs" type="number" min="1" :max="nworkers" placeholder="Number of parallel workers"></md-input>
              </md-field>
            </div>
          </div>
          <div class="col">
            <div class="md-layout-item">
              <md-field>
                <label for="method" title="Calculation precision (Float32/Float64)">Calculation precision</label>
                <md-select v-model="method" placeholder="Calculation precision">
                  <md-option v-for="(method, index) in $constants.METHODS" :key="index" :value="index">{{ method }}</md-option>
                </md-select>
              </md-field>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col">
            <md-checkbox class="modelavg" v-model="modelavg" :checked="modelavg" title="Display weighted model averaging results">Display model averaging results</md-checkbox>
          </div>
        </div>
      </md-card-content>
    </md-card>
    <md-card>
      <md-card-header>
        <div class="md-title">Output options</div>
      </md-card-header>
      <hr>
      <md-card-content>
        <div class="row">
          <div class="col">
            <md-checkbox class="orderresults" v-model="orderresults" :checked="orderresults" title="Sort full result database by selected criteria">Sort all models</md-checkbox>
          </div>
        </div>
        <div class="row">
          <div class="col">
            <md-checkbox class="exportcsv" v-model="exportcsv" :checked="exportcsv" title="Export to CSV">Export to CSV</md-checkbox>
          </div>
          <div class="col">
            <div class="md-layout-item">
              <md-field class="required-input">
                <label for="csv" title="Define output CSV filename">Output filename</label>
                <md-input v-model="csv" type="text" placeholder="Output filename" :disabled="!exportcsv" :hidden="!exportcsv"></md-input>
              </md-field>
              <span class="md-caption required-label" :hidden="!exportcsv">Required</span>
            </div>
          </div>
        </div>
      </md-card-content>
    </md-card>
  </div>
</template>

<script>
import {mapState, mapGetters} from 'vuex'
import utils from '../utils'

export default {
  components: { },
  name: 'Settings',
  data () {
    return {}
  },
  watch: {
    criteria: function () {
      this.validate()
    },
    exportcsv: function () {
      this.validate()
    },
    csv: function () {
      this.validate()
    }
  },
  methods: {
    validate () {
      var validCsv = true
      if (this.exportcsv && !this.getGSRegOptionsCsv) {
        validCsv = false
      }
      var validLength = this.getGSRegOptionsCriteria.length > 0
      this.$store.commit('updateCompleteStep', { step: this.$store.state.currentStep, complete: validCsv && validLength })
    },
    updateSetStep () {
      this.$store.commit('updateSetStep', { step: this.$store.state.currentStep, set: true })
    }
  },
  computed: {
    ...mapState(['datanames']),
    ...mapGetters(['getInputDataNobs', 'getServerNworkers', 'getGSRegOptionsExpvars', 'getGSRegOptionsIntercept', 'getGSRegOptionsResidualtest', 'getGSRegOptionsResidualtest', 'getGSRegOptionsTtest', 'getGSRegOptionsOrderresults', 'getGSRegOptionsModelavg', 'getGSRegOptionsOutsample', 'getGSRegOptionsCsv', 'getGSRegOptionsMethod', 'getGSRegOptionsCriteria']),
    outsampleMax () {
      return utils.outsampleMax(this.getInputDataNobs, this.$constants.INSAMPLE_MIN_SIZE, this.getGSRegOptionsExpvars, this.getGSRegOptionsIntercept)
    },
    navHidden: {
      get () {
        return this.$store.state.navHidden
      }
    },
    nworkers: {
      get () {
        return this.getServerNworkers
      }
    },
    residualtest: {
      get () {
        return this.getGSRegOptionsResidualtest
      },
      set (value) {
        this.$store.commit('setGSRegOptionsResidualtest', value)
        this.updateSetStep()
      }
    },
    ttest: {
      get () {
        return this.getGSRegOptionsTtest
      },
      set (value) {
        this.$store.commit('setGSRegOptionsTtest', value)
        this.updateSetStep()
      }
    },
    orderresults: {
      get () {
        return this.getGSRegOptionsOrderresults
      },
      set (value) {
        this.$store.commit('setGSRegOptionsOrderresults', value)
        this.updateSetStep()
      }
    },
    modelavg: {
      get () {
        return this.getGSRegOptionsModelavg
      },
      set (value) {
        this.$store.commit('setGSRegOptionsModelavg', value)
        this.updateSetStep()
      }
    },
    outsample: {
      get () {
        return this.getGSRegOptionsOutsample
      },
      set (value) {
        this.$store.commit('setGSRegOptionsOutsample', value)
        this.$store.commit('filterCriteria', value)
        this.updateSetStep()
      }
    },
    csv: {
      get () {
        return this.getGSRegOptionsCsv
      },
      set (value) {
        this.$store.commit('setGSRegOptionsCsv', value)
        this.updateSetStep()
      }
    },
    method: {
      get () {
        return this.getGSRegOptionsMethod
      },
      set (value) {
        this.$store.commit('setGSRegOptionsMethod', value)
        this.updateSetStep()
      }
    },
    criteria: {
      get () {
        return this.getGSRegOptionsCriteria
      },
      set (value) {
        this.$store.commit('setGSRegOptionsCriteria', value)
        this.updateSetStep()
      }
    },
    exportcsv: {
      get () {
        return this.$store.state.exportcsv
      },
      set (value) {
        this.$store.commit('setExportcsv', value)
        this.updateSetStep()
      }
    },
    paraprocs: {
      get () {
        return this.$store.state.paraprocs
      },
      set (value) {
        this.$store.commit('setParaprocs', value)
        this.updateSetStep()
      }
    }
  }
}
</script>

<style>
.intercept {
  margin-top: 27px;
  margin-bottom: 5px;
}

.md-checkbox.md-theme-default.md-checked .md-ripple {
  color: #60ad51;
}
.md-checkbox.md-theme-default.md-checked .md-checkbox-container {
  background: #60ad51;
  border-color: #60ad51;
}

.md-card-header {
  padding-top: 0;
  padding-bottom: 0;
}

h2 {
  margin-bottom: 20px;
}

.md-title {
  font-size: 18px!important;
}

hr {
  margin-bottom: 0;
}

</style>

