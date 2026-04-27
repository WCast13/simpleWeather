//
//  GeocodeManager.swift
//  simpleWeather
//
//  Created by William Castellano on 11/5/25.
//

import Foundation
import MapKit

class GeocodeManager {
    func forwardGeocode(address: String) async -> MKMapItem? {
        var location: MKMapItem? = nil

        if let request = MKGeocodingRequest(addressString: address) {
            do {
                let mapItems = try await request.mapItems
                location = mapItems.first
            } catch {
                print("Error geocoding location \(address): \(error.localizedDescription)")
            }
        } else {
            print("Error creating geocoding request")
        }
        return location
    }
}
