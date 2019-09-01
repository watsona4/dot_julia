<template>
  <div class="main">
    <div v-if="!processing">
      <h2>Request details</h2>
      <p>Please confirm that the selected options are correct before starting.
      <h3>Selected variables</h3>
      <hr/>
      <div class="row">
        <div class="col">
          <ul class="gsregOptions">
            <li><b>Dependent variable: </b>{{ depvar }}</li>
            <li><b>Explanatory variables: </b><span v-for="(expvar, index) in expvars" :key="index" class="expvar">{{ expvar }}</span>
            </li>
            <li><b>Time variable: </b><span v-if="gsregOptions.time">{{ gsregOptions.time }}</span><span v-else>No selected</span>
            </li>
            <li><b>Include intercept: </b><span v-if="gsregOptions.intercept">Yes</span><span v-else>No</span></li>
          </ul>
        </div>
      </div>
      <h3>Settings</h3>
      <hr/>
      <div class="row">
        <div class="col">
          <ul class="gsregOptions">
            <li><b>Out-of-sample observations: </b>{{ gsregOptions.outsample }}</li>
            <li><b>Ordering criteria: </b><span class="criteria" v-for="(criteria, index) in gsregOptions.criteria"
                                                :key="index">{{ $constants.CRITERIA[criteria] }}</span></li>
            <li><b>Estimate residuals tests: </b><span v-if="gsregOptions.residualtest">Yes</span><span v-else>No</span>
            </li>
            <li><b>Estimate t-test: </b><span v-if="gsregOptions.ttest">Yes</span><span v-else>No</span></li>
          </ul>
        </div>
        <div class="col">
          <ul class="gsregOptions">
            <li><b>Number of parallel workers: </b>{{ paraprocs }}</li>
            <li><b>Calculation precision: </b>{{ $constants.METHODS[gsregOptions.method] }}</li>
            <li><b>Display model averaging results: </b><span v-if="gsregOptions.modelavg">Yes</span><span
              v-else>No</span></li>
          </ul>
        </div>
      </div>
      <div class="row">
        <div class="col">
          <ul class="gsregOptions">
            <li><b>Sort all models: </b><span v-if="gsregOptions.orderresults">Yes</span><span v-else>No</span></li>
            <li><b>Export to CSV: </b><span v-if="exportcsv">Yes</span><span v-else>No</span></li>
            <li v-if="exportcsv"><b>Output filename: </b>{{ csv }}</li>
          </ul>
        </div>
      </div>
      <div class="text-right">
        <md-button class="md-raised md-primary start-solve" @click.native="solve()">Solve</md-button>
      </div>
    </div>
    <div v-else>
      <div class="websocket-console">
        <div class="progress-spinner text-center" :hidden="error">
          <md-progress-spinner :md-diameter="150" :md-stroke="10" class="spinner"
                               md-mode="indeterminate"></md-progress-spinner>
        </div>
        <div class="progress-error text-center" :hidden="!error">
          <font-awesome-icon icon="exclamation-triangle"/>
        </div>
        <transition name="slide-fade" mode="out-in">
          <div :key="lastMessage" class="progress-text text-center">
            {{ lastMessage }}
          </div>
        </transition>
      </div>
      <div class="text-center" :hidden="!error">
        <md-button class="md-raised md-primary" @click.native="startOver()">Start over</md-button>
        <md-button class="md-raised md-accent" @click.native="solve()">Retry</md-button>
      </div>
    </div>
  </div>
</template>

<script>
  import {mapState, mapActions} from 'vuex'
  // TODO: Create a better view
  export default {
    components: {},
    name: 'WizardProcessing',
    data () {
      return {
        messages: [],
        lastMessage: null,
        processing: false,
        error: false
      }
    },
    created () {
      this.$options.sockets.onmessage = function (msg) {
        let parsedMessage = JSON.parse(msg.data)
        if (parsedMessage.hasOwnProperty('done')) {
          if (parsedMessage.done === true) {
            this.$store.commit('setBestResult', parsedMessage.result.bestresult)
            this.$store.commit('setAvgResults', parsedMessage.result.avgresults)
            this.$store.commit('updateCompleteStep', {step: this.$store.state.currentStep, complete: true})
            this.nextStep()
          }
        }
        this.messages.push(parsedMessage)
        this.lastMessage = parsedMessage['message']
      }
      this.sendMessage()
    },
    methods: {
      ...mapActions(['nextStep']),
      sendMessage (msg = {}) {
        msg['user-token'] = this.$store.state.userToken
        this.$socket.sendObj(msg)
      },
      startOver () {
        this.$store.commit('restartOperation', 0)
        this.$store.commit('setCurrentStep', 0)
      },
      solve () {
        this.$store.commit('setNavBlocked', true)
        this.$store.commit('setNavHidden', true)
        this.processing = true
        var request = {
          'depvar': this.$store.state.depvar,
          'expvars': this.$store.state.expvars,
          'paraprocs': this.$store.state.paraprocs,
          'csv': this.$store.state.csv,
          'options': this.$store.state.gsregOptions
        }
        var requestUrl = this.$constants.API.host + this.$constants.API.paths.solve_file_options + '/' + this.$store.state.server.operationId + '/' + btoa(JSON.stringify(request))
        this.$http.get(requestUrl).then(response => {
          this.$store.commit('setServerResultId', response.body.operation_id)
        })
      }
    },
    computed: {
      ...mapState(['depvar', 'expvars', 'gsregOptions', 'paraprocs', 'exportcsv', 'csv'])
    }
  }
</script>

<style>
  button.start-solve {
    background: #6682e0 !important;
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

  .gsregOptions {
    list-style: none;
    padding-left: 0;
    margin-top: 10px;
    font-size: 14px;
  }

  h4 {
    font-size: 16px;
  }

  .expvar + .expvar:before {
    content: ", ";
  }

  .criteria + .criteria:before {
    content: ", ";
  }

  .slide-fade-enter-active {
    transition: all .3s ease;
  }

  .slide-fade-leave-active {
    transition: all .3s cubic-bezier(1.0, 0.5, 0.8, 1.0);
  }

  .slide-fade-enter {
    transform: translateY(-10px);
    opacity: 0;
  }

  .slide-fade-leave-to
    /* .slide-fade-leave-active for <2.1.8 */
  {
    transform: translateY(10px);
    opacity: 0;
  }

  .footer {
    height: 127px;
  }

  .progress-error {
    color: #cb3c33;
    font-size: 95px;
  }

</style>
