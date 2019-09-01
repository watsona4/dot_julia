<template>
  <div class="wizard">
    <nav class="wizard-nav container">
      <div class="row">
        <div class="col">
          <div class="progress step-progress">
            <div class="progress-bar step-progress-bar" role="progressbar" :style="{ width: getProgress+'%' }"
                 :aria-valuenow="getProgress" aria-valuemin="0" aria-valuemax="100"></div>
          </div>
        </div>
      </div>
      <div class="row step-buttons">
        <div v-for="(step, index) in this.$constants.STEPS" :key="index" class="col step-button-container">
          <md-button class="step-button md-icon-button md-raised" :class="stepClass(index)"
                     @click.native="setStep(index)" @click.prevent="!completeSteps[index-1]">
            <font-awesome-icon :icon="step.icon"/>
          </md-button>
          <div class="step-label" :class="stepClass(index)">{{ step.label }}</div>
        </div>
      </div>
    </nav>
    <div class="tab container">
      <component :is="$constants.STEPS[currentStep].component"></component>
    </div>
    <div class="container nav-buttons">
      <div class="row">
        <div v-if="currentStep-1 >= 0" class="col nav-col nav-prev-col">
          <md-button class="md-icon-button md-raised nav-button nav-prev-button"
                     @click.native="setStep(currentStep-1)" :hidden="navHidden">
            <font-awesome-icon icon="chevron-left"/>
          </md-button>
          <span v-if="currentStep-1 >= 0"
                class="nav-label nav-prev-label">{{ $constants.STEPS[currentStep-1].label }}</span>
        </div>
        <div v-if="currentStep + 1 < $constants.STEPS.length" class="col nav-col nav-next-col">
          <md-button class="md-icon-button md-raised nav-button nav-next-button" :class="availableClass"
                     :disabled="!completeSteps[currentStep]"
                     @click.native="setStep(currentStep+1)" :hidden="navHidden">
            <font-awesome-icon icon="chevron-right"/>
          </md-button>
          <span v-if="currentStep + 1 < $constants.STEPS.length" class="nav-label nav-next-label">{{ $constants.STEPS[currentStep+1].label }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import {mapState, mapActions} from 'vuex'
  import WizardLoadDatabase from './WizardLoadDatabase.vue'
  import WizardSelectVariables from './WizardSelectVariables.vue'
  import WizardSettings from './WizardSettings.vue'
  import WizardProcessing from './WizardProcessing.vue'
  import WizardResults from './WizardResults.vue'

  export default {
    name: 'Wizard',
    components: {
      WizardLoadDatabase,
      WizardSelectVariables,
      WizardSettings,
      WizardProcessing,
      WizardResults
    },
    created () {
      this.setStep(0)
    },
    data () {
      return {}
    },
    computed: {
      ...mapState(['currentStep', 'completeSteps', 'navHidden']),
      getProgress () {
        return this.$store.state.currentStep * 100 / (this.$constants.STEPS.length - 1)
      },
      availableClass () {
        return {available: this.$store.state.completeSteps[this.$store.state.currentStep]}
      }
    },
    methods: {
      ...mapActions(['prevStep', 'nextStep']),
      stepClass (step) {
        return {
          active: this.$store.state.currentStep === step,
          complete: this.$store.state.completeSteps[step],
          disabled: (this.$store.state.navHidden) ? true : ((step > 0) ? !this.$store.state.completeSteps[step - 1] : false),
          set: this.$store.state.setSteps[step]
        }
      },
      setStep (step) {
        if (this.$store.state.setSteps[step] || (step - 1 >= 0 && this.$store.state.completeSteps[step - 1]) || step === 0) {
          if (!this.$store.state.navHidden) {
            this.$store.commit('setCurrentStep', step)
            // TODO: Unhardcode step
            switch (step) {
              case 0:
                this.$store.commit('restartOperation', true)
                this.$store.commit('setNavBlocked', true)
                this.$store.commit('setNavHidden', true)
                break
              case 1:
                this.$store.commit('setNavBlocked', false)
                this.$store.commit('setNavHidden', false)
                break
              case 2:
                this.$store.commit('setNavBlocked', false)
                this.$store.commit('setNavHidden', false)
                break
              case 3:
                this.$store.commit('setNavBlocked', false)
                this.$store.commit('setNavHidden', false)
                break
            }
          }
        }
      }
    }
  }
</script>

<style lang="scss">

  .wizard .step-progress {
    margin-top: 50px;
    height: 7px;
  }

  .wizard .step-progress-bar {
    background-color: #389826;
  }

  .wizard .step-buttons {
    transform: translateY(-39%);
  }

  .wizard .step-buttons .step-button-container {
    padding: 0;
    text-align: center;
  }

  .wizard .step-buttons .step-button-container:first-child {
    margin-left: -50px;
  }

  .wizard .step-buttons .step-button-container:last-child {
    margin-right: -50px;
  }

  .wizard .step-button-container .step-button {
    height: 50px;
    width: 50px;
    display: inline-block;
    background: #e9ecef;
    color: #666666;
    font-size: 22px;
    margin: 0;
  }

  .wizard .step-button-container .step-button:focus {
    outline: 0;
  }

  .wizard .step-button-container .step-button:hover {
    cursor: pointer;
    color: #222222;
  }

  .wizard .step-button-container .step-button.active,
  .wizard .step-button-container .step-button.set {
    border: 3px solid #389826;
    color: #389826;
    background: #e9ecef;
  }

  .wizard .step-button-container .step-button.complete,
  .wizard .step-button-container .step-button.complete.set
  .wizard .step-button-container .step-button.complete.set.active {
    background: #389826;
    color: #ffffff;
  }

  .wizard .step-button-container .step-button.disabled {
    cursor: not-allowed;
  }

  .wizard .step-button-container .step-label {
    font-size: 15px;
    color: #666;
    margin-top: 5px;
    transition: 1s opacity;
    opacity: 0.3;
  }

  .wizard .step-button-container .step-label.active,
  .wizard .step-button-container .step-label.active.completed {
    opacity: 1;
  }

  .wizard .step-button-container .step-label.complete {
    opacity: 0.6;
  }

  .wizard h2 {
    font-size: 20px;
  }

  .wizard h3 {
    font-size: 16px;
  }

  hr {
    margin-top: 0;
  }

  .nav-next-col {
    text-align: right;
  }

  .nav-buttons {
    margin-top: 20px;
  }

  .nav-button.available {
    background: #60ad51 !important;
    color: #FFFFFF !important;
  }

  .nav-button:focus {
    outline: none;
  }

  .nav-label {
    background: rgba(50, 50, 50, 0.8);
    color: #FFF;
    padding: 3px 6px;
    border-radius: 2px;
    font-size: 13px;
    font-weight: bold;
    position: relative;
    top: 15px;
    opacity: 0;
    transition: 0.3s all;
    user-select: none;

    margin-top: -7px;
  }

  .nav-prev-label,
  .nav-prev-button {
    float: left;
  }

  .nav-next-label,
  .nav-next-button {
    float: right;
  }

  .nav-prev-button:hover + .nav-prev-label {
    opacity: 100;
  }

  .nav-next-button:hover + .nav-next-label {
    opacity: 100;
  }

</style>
