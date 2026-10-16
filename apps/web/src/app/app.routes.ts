import { Routes } from '@angular/router';

import { Home } from './home/home';
import { Track } from './track/track';

export const routes: Routes = [
  { path: '', component: Home, title: 'Shipping Express — Home' },
  { path: 'ship', component: Home, title: 'Shipping Express — Ship' },
  { path: 'track', component: Track, title: 'Shipping Express — Track' },
  { path: '**', redirectTo: '' },
];
