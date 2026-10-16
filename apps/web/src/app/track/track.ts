import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';

import { ShippingService, TrackingResponse } from '../shipping.service';

@Component({
  selector: 'app-track',
  imports: [FormsModule],
  templateUrl: './track.html',
  styleUrl: './track.css'
})
export class Track implements OnInit {
  private readonly shipping = inject(ShippingService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  protected trackingId = '';
  protected readonly busy = signal(false);
  protected readonly result = signal<TrackingResponse | null>(null);
  protected readonly error = signal<string | null>(null);

  ngOnInit(): void {
    this.route.queryParamMap.subscribe((params) => {
      const id = params.get('id');
      if (id) {
        this.trackingId = id;
        this.lookup(id);
      }
    });
  }

  protected submit(): void {
    const id = this.trackingId.trim();
    if (id) {
      this.router.navigate([], { queryParams: { id } });
    }
  }

  private lookup(id: string): void {
    this.busy.set(true);
    this.result.set(null);
    this.error.set(null);
    this.shipping.track(id).subscribe({
      next: (r) => {
        this.busy.set(false);
        this.result.set(r);
      },
      error: (e) => {
        this.busy.set(false);
        this.error.set(`Tracking is unavailable right now — the server returned ${e.status || 'no response'}.`);
      },
    });
  }
}
