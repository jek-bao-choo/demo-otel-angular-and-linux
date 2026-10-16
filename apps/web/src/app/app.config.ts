import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { provideRouter } from '@angular/router';
import { provideDatadogErrorHandler, provideDatadogRouter } from '@datadog/browser-rum-angular';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    // Required alongside angularPlugin({ router: true }) to track route changes as RUM views
    provideDatadogRouter(),
    provideDatadogErrorHandler(),
    provideHttpClient(withFetch()),
  ]
};
