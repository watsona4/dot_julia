<template>
  <div class="main">
    <h2>Select variables</h2>
    <div class="row">
      <div class="col">
        <md-field class="required-input">
          <label for="dependent" title="Select dependent variables">Dependent variables</label>
          <md-select v-model="dependent" placeholder="Dependent variables" required>
            <md-option v-for="(dataname, index) in datanames" :key="index" :value="dataname">{{ dataname }}</md-option>
          </md-select>
        </md-field>
        <span class="md-caption required-label">Required</span>
      </div>
      <div class="col">
        <div class="md-layout-item">
          <md-field class="required-input">
            <label for="explanatory" title="Select explanatory variables">Explanatory variables</label>
            <md-select v-model="explanatory" placeholder="Explanatory variables" multiple required>
              <md-option v-for="(dataname, index) in datanames" :key="index" :value="dataname" :disabled="dependent==dataname">{{ dataname }}</md-option>
            </md-select>
          </md-field>
          <span class="md-caption required-label fa-pull-right">
            <a href="#" @click="selectAll">Select all</a>
          </span>
          <span class="md-caption required-label">Required</span>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col">
        <md-checkbox class="intercept" v-model="intercept" :checked="intercept" title="Include intercept">Include intercept</md-checkbox>
      </div>
      <div class="col">
        <div class="md-layout-item">
          <md-field>
            <label for="time" title="Select time variable">Time variable</label>
            <md-select v-model="time" placeholder="Time variable">
              <md-option v-for="(dataname, index) in datanames" :key="index" :value="dataname" :disabled="dependent==dataname">{{ dataname }}</md-option>
            </md-select>
          </md-field>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import {mapState, mapGetters} from 'vuex'
import utils from '../utils'

export default {
  components: { },
  name: 'SelectVariables',
  data () {
    return {}
  },
  watch: {
    dependent: function (depvar) {
      this.$store.commit('filterExpvars', depvar)
      this.$store.commit('filterTime', depvar)
      this.validate()
    },
    explanatory: function (expvars) {
      this.validate()
      this.updateOutsample()
    },
    intercept: function (intercept) {
      this.updateOutsample()
    }
  },
  methods: {
    validate () {
      this.$store.commit('updateCompleteStep', { step: this.$store.state.currentStep, complete: this.getGSRegOptionsDepvar !== null && this.getGSRegOptionsExpvars.length > 1 })
    },
    selectAll () {
      this.$store.commit('selectAllExplanatory')
    },
    updateOutsample () {
      var outsampleMax = utils.outsampleMax(this.getInputDataNobs, this.$constants.INSAMPLE_MIN_SIZE, this.getGSRegOptionsExpvars, this.getGSRegOptionsIntercept)
      if (outsampleMax < this.getGSRegOptionsOutsample) {
        this.$store.commit('setGSRegOptionsOutsample', outsampleMax)
      }
    },
    updateSetStep () {
      this.$store.commit('updateSetStep', { step: this.$store.state.currentStep, set: true })
    }
  },
  computed: {
    ...mapState(['datanames']),
    ...mapGetters(['getInputDataDatanames', 'getInputDataNobs', 'getGSRegOptionsDepvar', 'getGSRegOptionsExpvars', 'getGSRegOptionsIntercept', 'getGSRegOptionsTime']),
    datanames: {
      get () {
        return this.getInputDataDatanames
      }
    },
    dependent: {
      get () {
        return this.getGSRegOptionsDepvar
      },
      set (value) {
        this.$store.commit('setGSRegOptionsDepvar', value)
        this.updateSetStep()
      }
    },
    explanatory: {
      get () {
        return this.getGSRegOptionsExpvars
      },
      set (value) {
        this.$store.commit('setGSRegOptionsExpvars', value)
        this.updateSetStep()
      }
    },
    intercept: {
      get () {
        return this.getGSRegOptionsIntercept
      },
      set (value) {
        this.$store.commit('setGSRegOptionsIntercept', value)
        this.updateSetStep()
      }
    },
    time: {
      get () {
        return this.getGSRegOptionsTime
      },
      set (value) {
        this.$store.commit('setGSRegOptionsTime', value)
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
</style>
