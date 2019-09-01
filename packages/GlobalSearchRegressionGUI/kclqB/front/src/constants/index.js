export default {
  'API': {
    'host': 'http://localhost:45872',
    'paths': {
      'server_info': '/server-info',
      'load_database': '/upload',
      'solve_file_options': '/solve',
      'results': '/result'
    }
  },
  'VERSION': '0.1.0',
  'WS': {
    'url': 'ws://localhost:45872/ws'
  },
  'INSAMPLE_MIN_SIZE': 20,
  'STEPS': [
    {
      'label': 'Load database',
      'icon': 'database',
      'component': 'WizardLoadDatabase'
    },
    {
      'label': 'Select variables',
      'icon': 'flask',
      'component': 'WizardSelectVariables'
    },
    {
      'label': 'Settings',
      'icon': 'cog',
      'component': 'WizardSettings'
    },
    {
      'label': 'Processing',
      'icon': 'spinner',
      'component': 'WizardProcessing'
    },
    {
      'label': 'Results',
      'icon': 'clipboard-list',
      'component': 'WizardResults'
    }
  ],
  'CRITERIA': {
    'r2adj': 'Adjusted R²',
    'bic': 'BIC',
    'aic': 'AIC',
    'aicc': 'AIC Corrected',
    'cp': 'Mallows\'s Cp',
    'rmse': 'RMSE',
    'rmseout': 'RMSE OUT',
    'sse': 'SSE'
  },
  'METHODS': {
    'fast': 'Fast',
    'precise': 'Precise'
  }
}
