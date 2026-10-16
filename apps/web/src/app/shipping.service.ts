import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

export interface ShipmentRequest {
  fromCountry: string;
  from: string;
  toCountry: string;
  to: string;
}

export interface ShipmentResponse {
  shipmentId: string;
  status: string;
}

export interface QuoteResponse {
  price: number;
  currency: string;
  eta: string;
}

export interface PickupResponse {
  pickupId: string;
  window: string;
}

export interface TrackingResponse {
  id: string;
  status: string;
  lastScan: string;
}

/** Calls adt-service-a on the same origin; RUM injects traceparent into each request. */
@Injectable({ providedIn: 'root' })
export class ShippingService {
  private readonly http = inject(HttpClient);

  createShipment(request: ShipmentRequest): Observable<ShipmentResponse> {
    return this.http.post<ShipmentResponse>('/api/shipments', request);
  }

  quote(request: ShipmentRequest): Observable<QuoteResponse> {
    return this.http.post<QuoteResponse>('/api/quotes', request);
  }

  schedulePickup(address: string, date: string): Observable<PickupResponse> {
    return this.http.post<PickupResponse>('/api/pickups', { address, date });
  }

  track(id: string): Observable<TrackingResponse> {
    return this.http.get<TrackingResponse>(`/api/track/${encodeURIComponent(id)}`);
  }
}
