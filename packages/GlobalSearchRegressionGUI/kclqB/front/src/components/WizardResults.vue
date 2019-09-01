<template>
  <div class="main">
    <div class="text-right">
      <md-button class="md-raised md-primary" :href="$constants.API.host + $constants.API.paths.results + '/' + server.resultId">
        <font-awesome-icon icon="download" />
        Download CSV
      </md-button>
    </div>
    <nav class="results-menu">
      <ul>
        <li><md-button :class="activeTabClass(0)" @click.native="setActiveTab(0)">Best model</md-button></li>
        <li v-if="gsregOptions.modelavg"><md-button :class="activeTabClass(1)" @click.native="setActiveTab(1)">Model averaging</md-button></li>
      </ul>
    </nav>
    <div class="results-tabs">
      <div class="results-tab" v-if="activeTab === 0">
        <md-table md-card>

          <md-table-row>
            <md-table-cell colspan="3"></md-table-cell>
            <md-table-cell colspan="3" class="dependent-variable"><b>Dependent variable: </b>{{ depvar }}</md-table-cell>
          </md-table-row>

          <md-table-row class="best-results-title">
            <md-table-cell colspan="3"><b>Selected covariates</b></md-table-cell>
            <md-table-cell><b>Coef.</b></md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest"><b>Std.</b></md-table-cell><md-table-cell v-else></md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest"><b>t-test</b></md-table-cell><md-table-cell v-else></md-table-cell>
          </md-table-row>

          <md-table-row v-for="(expvar, index) in expvars" :key="index" v-if="bestResult[expvar+'_b']">
            <md-table-cell colspan="3"><b>{{ expvar }}</b></md-table-cell>
            <md-table-cell>{{ bestResult[expvar+'_b'] }}</md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest">{{ bestResult[expvar+'_bstd'] }}</md-table-cell><md-table-cell v-else></md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest">{{ bestResult[expvar+'_t'] }}</md-table-cell><md-table-cell v-else></md-table-cell>
          </md-table-row>

          <md-table-row v-if="gsregOptions.intercept">
            <md-table-cell colspan="3"><b>_cons</b></md-table-cell>
            <md-table-cell>{{ bestResult['_cons_b'] }}</md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest">{{ bestResult['_cons_bstd'] }}</md-table-cell><md-table-cell v-else></md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest">{{ bestResult['_cons_t'] }}</md-table-cell><md-table-cell v-else></md-table-cell>
          </md-table-row>

          <md-table-row class="observations">
            <md-table-cell colspan="3"><b>Observations</b></md-table-cell>
            <md-table-cell colspan="3">{{ bestResult['nobs'] }}</md-table-cell>
          </md-table-row>

          <md-table-row >
            <md-table-cell colspan="3"><b>{{ $constants.CRITERIA['r2adj'] }}</b></md-table-cell>
            <md-table-cell colspan="3">{{ bestResult['r2adj'] }}</md-table-cell>
          </md-table-row>

          <md-table-row >
            <md-table-cell colspan="3"><b>F-statistic</b></md-table-cell>
            <md-table-cell colspan="3">{{ bestResult['F'] }}</md-table-cell>
          </md-table-row>

          <md-table-row >
            <md-table-cell colspan="3"><b>Combined criteria</b></md-table-cell>
            <md-table-cell colspan="3">{{ bestResult['order'] }}</md-table-cell>
          </md-table-row>

          <md-table-row v-for="(criteria) in gsregOptions.criteria" :key="criteria" v-if="criteria!='r2adj'" >
            <md-table-cell colspan="3"><b>{{ $constants.CRITERIA[criteria] }}</b></md-table-cell>
            <md-table-cell colspan="3">{{ bestResult[criteria] }}</md-table-cell>
          </md-table-row>
        </md-table>
      </div>
      <div class="results-tab" v-if="activeTab === 1 && gsregOptions.modelavg">
        <md-table md-card>
          <md-table-row>
            <md-table-cell colspan="3"></md-table-cell>
            <md-table-cell colspan="3" class="dependent-variable"><b>Dependent variable: </b>{{ depvar }}</md-table-cell>
          </md-table-row>

          <md-table-row class="best-results-title">
            <md-table-cell colspan="3"><b>Selected covariates</b></md-table-cell>
            <md-table-cell><b>Coef.</b></md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest"><b>Std.</b></md-table-cell><md-table-cell v-else></md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest"><b>t-test</b></md-table-cell><md-table-cell v-else></md-table-cell>
          </md-table-row>

          <md-table-row v-for="(expvar, index) in expvars" :key="index" v-if="avgResults[expvar+'_b']">
            <md-table-cell colspan="3"><b>{{ expvar }}</b></md-table-cell>
            <md-table-cell>{{ avgResults[expvar+'_b'] }}</md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest">{{ avgResults[expvar+'_bstd'] }}</md-table-cell><md-table-cell v-else></md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest">{{ avgResults[expvar+'_t'] }}</md-table-cell><md-table-cell v-else></md-table-cell>
          </md-table-row>

          <md-table-row v-if="gsregOptions.intercept">
            <md-table-cell colspan="3"><b>_cons</b></md-table-cell>
            <md-table-cell>{{ bestResult['_cons_b'] }}</md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest">{{ avgResults['_cons_bstd'] }}</md-table-cell><md-table-cell v-else></md-table-cell>
            <md-table-cell v-if="gsregOptions.ttest">{{ avgResults['_cons_t'] }}</md-table-cell><md-table-cell v-else></md-table-cell>
          </md-table-row>

          <md-table-row class="observations">
            <md-table-cell colspan="3"><b>Observations</b></md-table-cell>
            <md-table-cell colspan="3">{{ bestResult['nobs'] }}</md-table-cell>
          </md-table-row>

          <md-table-row >
            <md-table-cell colspan="3"><b>{{ $constants.CRITERIA['r2adj'] }}</b></md-table-cell>
            <md-table-cell colspan="3">{{ avgResults['r2adj'] }}</md-table-cell>
          </md-table-row>

          <md-table-row >
            <md-table-cell colspan="3"><b>F-statistic</b></md-table-cell>
            <md-table-cell colspan="3">{{ avgResults['F'] }}</md-table-cell>
          </md-table-row>

          <md-table-row >
            <md-table-cell colspan="3"><b>Combined criteria</b></md-table-cell>
            <md-table-cell colspan="3">{{ avgResults['order'] }}</md-table-cell>
          </md-table-row>
        </md-table>
      </div>
    </div>
    <div class="text-right mt-3">
      <md-button class="md-raised md-primary" @click.native="startOver()">Start over</md-button>
    </div>
  </div>
</template>

<script>
import {mapState} from 'vuex'

export default {
  components: { },
  name: 'Results',
  data () {
    return {
      activeTab: 0
    }
  },
  computed: {
    ...mapState(['server', 'depvar', 'expvars', 'gsregOptions', 'paraprocs', 'exportcsv', 'bestResult', 'avgResults'])
  },
  methods: {
    startOver () {
      this.$store.commit('restartOperation', 0)
      this.$store.commit('setCurrentStep', 0)
    },
    activeTabClass (tab) {
      return {
        active: this.activeTab === tab
      }
    },
    setActiveTab (tab) {
      this.activeTab = tab
    }
  }
}
</script>

<style>

  .results-menu ul {
    margin: 0;
    padding: 0;
  }

  .results-menu ul li {
    display: inline-block;
    margin: 0;
    padding: 0;
  }

  .results-menu ul li button:hover {
    border-bottom: 1px solid #000;
    background-color: #fff!important;
  }

  .results-menu ul li button.active,
  .results-menu ul li button.active:hover {
    border-bottom: 1px solid #6682e0;
    color: #6682e0;
  }

  button:active,
  button:focus {
    outline: none;
  }

  .best-results-title {
    border-bottom: 2px solid #999;
  }

  .observations {
    border-top: 2px solid #999;
  }

h1 {
  font-weight: normal;
  font-family: "Lato Regular";
  margin-bottom: 0;
}

p {
  max-width: 800px;
  margin: 10px auto;
}

a.start-button {
  text-decoration: none;
  color: #4D63D4;
  font-size: 20px;
  font-family: "Lato Black";
}

.example-drag .drop-active {
    top: 0;
    bottom: 0;
    right: 0;
    left: 0;
    position: fixed;
    z-index: 9999;
    opacity: .6;
    text-align: center;
    background: #000;
  }
  .example-drag .drop-active h3 {
    margin: -.5em 0 0;
    position: absolute;
    top: 50%;
    left: 0;
    right: 0;
    -webkit-transform: translateY(-50%);
    -ms-transform: translateY(-50%);
    transform: translateY(-50%);
    font-size: 40px;
    color: #fff;
    padding: 0;
  }
</style>
