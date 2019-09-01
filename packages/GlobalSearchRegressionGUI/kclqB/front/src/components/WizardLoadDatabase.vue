<template>
  <div>
    <div v-show="$refs.upload && $refs.upload.dropActive" class="drop-active">
      <h3>Drop files to upload</h3>
    </div>
    <h2>Load your database</h2>
    <p>You should select a Comma-separated values (CSV) file, where the first row is expected to contain the
      variable names (column headers). In this version, variables with string values will not be available for
      calculation.</p>
    <div class="text-center">
      <file-upload
        ref="upload"
        v-model="files"
        :custom-action="customAction"
        @input-filter="inputFilter"
        @input-file="inputFile"
        accept="text/csv"
        :extensions="['csv']"
        :drop="true">
        <span class="btn select-file" v-if="!files.length">
          Select CSV file
        </span>
      </file-upload>
    </div>

    <div v-for="(file, index) in files" :key="index">
      <span><font-awesome-icon icon="file" class="file-icon"/></span>
      <span>{{ file.name }}</span>

      <a href="#" class="float-right" v-if="!$refs.upload || !$refs.upload.active" @click.prevent="$refs.upload.remove(file)">Remove</a>

      <div class="progress file-upload-progress">
        <div class="progress-bar file-upload-progress-bar" role="progressbar"
             :style="{ width: file.progress+'%' }" :aria-valuenow="file.progress" aria-valuemin="0"
             aria-valuemax="100"></div>
      </div>
      <div class="file-upload-progress-speed">{{ file.speed | speed }}</div>
    </div>

    <div class="upload-button-container text-right" v-if="files.length">
      <md-button class="md-raised md-primary upload-file" v-if="!$refs.upload || !$refs.upload.active"
                 @click.prevent="$refs.upload.active = true">Start upload
      </md-button>
      <md-button class="md-raised md-default cancel-upload" v-else
                             @click.prevent="$refs.upload.clear()">Cancel</md-button>
    </div>
  </div>
</template>

<script>
  import FileUpload from 'vue-upload-component'
  import {mapState, mapActions} from 'vuex'

  export default {
    components: {FileUpload},
    name: 'WizardLoadDatabase',
    filters: {
      speed (value) {
        if (value / 1024 < 1024) {
          return (value / 1024).toFixed(0) + ' KB/s'
        }
        return (value / 1024 / 1024).toFixed(2) + ' MB/s'
      }
    },
    data () {
      return {
        files: []
      }
    },
    computed: {
      ...mapState(['userToken'])
    },
    methods: {
      ...mapActions(['nextStep']),
      validate () {
        this.$store.commit('updateCompleteStep', {step: this.$store.state.currentStep, complete: true})
      },
      customAction (file, component) {
        var xhr = new XMLHttpRequest()
        xhr.open('POST', this.$constants.API.host + this.$constants.API.paths.load_database, true)
        xhr.setRequestHeader('X-User-Token', this.$store.state.userToken)
        return component.uploadXhr(xhr, file, file.file)
      },
      inputFilter (newFile, oldFile, prevent) {
        if (newFile && !oldFile) {
          if (!/\.csv$/i.test(newFile.name)) {
            alert('The file must be .csv')
            return prevent()
          }
        }
      },
      inputFile (newFile, oldFile) {
        if (newFile && oldFile) {
          if (newFile.success !== oldFile.success) {
            // TODO: Validate response values
            this.$store.commit('setInputDataNobs', newFile.response.nobs)
            this.$store.commit('setInputDataDatanames', newFile.response.datanames)
            this.$store.commit('setServerOperationId', newFile.response.filename)
            this.validate()
            // TODO: Remove to other place
            this.$store.commit('setNavBlocked', false)
            this.$store.commit('setNavHidden', false)
            this.nextStep()
          }
        }
      }
    }
  }
</script>

<style>
  .btn.select-file,
  button.upload-file {
    background: #6682e0 !important;
  }

  .btn.select-file {
    color: #fff;
    box-shadow: 0 3px 1px -2px rgba(0, 0, 0, .2), 0 2px 2px 0 rgba(0, 0, 0, .14), 0 1px 5px 0 rgba(0, 0, 0, .12);
    min-width: 88px;
    height: 36px;
    margin: 6px 8px;
    user-select: none;
    border-radius: 2px;
    font-size: 14px;
    font-weight: 500;
    text-transform: uppercase;
  }

  .file-upload > div {
    display: flex;
    align-items: center;
    height: 90%;
    text-align: center;
  }

  .file-upload .file-upload-name {
    text-align: center;
    width: 100%;
  }

  .file-upload .file-upload-name .file-icon {
    font-size: 50px;
    margin-right: 20px;
  }

  .file-upload-progress {
    margin-bottom: 2px;
    height: 8px;
  }

  .file-upload-progress-bar {
    background: #60ad51;
  }

  .file-upload-progress-speed {
    margin-bottom: 2px;
    text-align: right;
    font-size: 15px;
    color: #999;
  }

  .upload-file, .cancel-upload {
    margin: 10px 0 0 0;
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

  .drop-active {
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

  .drop-active h3 {
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

  .progress-spinner {
    color: #6682e0;
    margin-top: 20px;
    margin-bottom: 20px;
  }

  .progress-text {
    font-size: 20px;
  }

  .fade-enter-active, .fade-leave-active {
    transition: opacity .5s;
  }
  .fade-enter, .fade-leave-to /* .fade-leave-active below version 2.1.8 */ {
    opacity: 0;
  }
</style>
