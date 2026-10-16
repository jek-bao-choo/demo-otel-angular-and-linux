import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';

import { ShipmentRequest, ShippingService } from '../shipping.service';

type Tab = 'shipment' | 'quote' | 'pickup';

interface Banner {
  kind: 'ok' | 'err';
  text: string;
}

@Component({
  selector: 'app-home',
  imports: [FormsModule],
  templateUrl: './home.html',
  styleUrl: './home.css'
})
export class Home {
  private readonly shipping = inject(ShippingService);
  private readonly router = inject(Router);

  protected readonly countries = ['Singapore', 'Malaysia', 'Indonesia', 'Thailand', 'Vietnam', 'Australia', 'Japan', 'United States'];

  protected readonly tab = signal<Tab>('shipment');
  protected readonly busy = signal(false);
  protected readonly banner = signal<Banner | null>(null);

  protected shipment: ShipmentRequest = { fromCountry: 'Singapore', from: '', toCountry: 'Malaysia', to: '' };
  protected pickupAddress = '';
  protected pickupDate = new Date(Date.now() + 86_400_000).toISOString().slice(0, 10);
  protected trackingId = '';

  protected selectTab(tab: Tab): void {
    this.tab.set(tab);
    this.banner.set(null);
  }

  protected next(): void {
    this.banner.set(null);
    this.busy.set(true);
    if (this.tab() === 'shipment') {
      this.shipping.createShipment(this.shipment).subscribe({
        next: (r) => this.done(`Shipment ${r.shipmentId} created (${r.status}).`),
        error: (e) => this.failed('Could not create shipment', e),
      });
    } else if (this.tab() === 'quote') {
      this.shipping.quote(this.shipment).subscribe({
        next: (r) => this.done(`Quote: ${r.currency} ${r.price.toFixed(2)} — estimated delivery ${r.eta}.`),
        error: (e) => this.failed('Could not get a quote', e),
      });
    } else {
      this.shipping.schedulePickup(this.pickupAddress, this.pickupDate).subscribe({
        next: (r) => this.done(`Pickup ${r.pickupId} booked for ${this.pickupDate}, ${r.window}.`),
        error: (e) => this.failed('Could not schedule pickup', e),
      });
    }
  }

  protected track(): void {
    const id = this.trackingId.trim() || 'SE1234567890';
    this.router.navigate(['/track'], { queryParams: { id } });
  }

  private done(text: string): void {
    this.busy.set(false);
    this.banner.set({ kind: 'ok', text });
  }

  private failed(prefix: string, error: HttpErrorResponse): void {
    this.busy.set(false);
    this.banner.set({ kind: 'err', text: `${prefix} — the server returned ${error.status || 'no response'}. Please try again.` });
  }
}
