import { bootstrapApplication } from '@angular/platform-browser';
import { datadogRum } from '@datadog/browser-rum';
import { angularPlugin } from '@datadog/browser-rum-angular';

import { appConfig } from './app/app.config';
import { App } from './app/app';

// Initialise RUM before Angular bootstraps so the first route and API calls are captured.
datadogRum.init({
  applicationId: '<RUM_APPLICATION_ID>',
  clientToken: '<RUM_CLIENT_TOKEN>',
  remoteConfiguration: {
    id: '<RUM_REMOTE_CONFIG_ID>',
  },
  site: 'datadoghq.com',
  service: 'shipping-express',
  env: 'uat',
  version: '1.0.0',
  sessionSampleRate: 100,
  sessionReplaySampleRate: 100,
  trackResources: true,
  trackUserInteractions: true,
  trackLongTasks: true,
  defaultPrivacyLevel: 'mask-user-input',
  // Inject W3C trace context (traceparent/tracestate) into same-origin /api calls so the
  // OTel-instrumented backend continues the trace started by the browser.
  allowedTracingUrls: [
    {
      match: (url: string) => url.startsWith(`${window.location.origin}/api/`),
      propagatorTypes: ['tracecontext'],
    },
  ],
  plugins: [angularPlugin({ router: true })],
});

bootstrapApplication(App, appConfig)
  .catch((err) => console.error(err));
