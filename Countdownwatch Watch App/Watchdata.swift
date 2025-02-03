//
//  Data.swift
//  Countdown clock
//
//  Created by Max McLoughlin on 11/10/23.
//

import Foundation
import WidgetKit
import CoreLocation

public struct Arrival: Identifiable, Codable, Equatable, Hashable {
    public var id: String {"\(route)\(time)"}

    var route: String
    var time: Date
    var stationID: String
    var name: String
}

public class TimeViewModel: ObservableObject {
    @Published var currentTime = Date.now
    var timer = Timer()
    
    
    init() {
        let repeatEverySecond:TimeInterval = 1
        timer = Timer.scheduledTimer(withTimeInterval: repeatEverySecond, repeats: true, block: {   [weak self] timer in

            self?.currentTime = Date.now
        })
    }
}

public class WidgetViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager: CLLocationManager
    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.distanceFilter = 100
        manager.requestAlwaysAuthorization()
    }
    
        
    @Published public var location: CLLocation?
    
    public func requestLocation() {
        DispatchQueue.main.async {
            self.manager.startUpdatingLocation()
        }
    }
    nonisolated public func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print(error)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.last
        
    }

}

@MainActor
public class StationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var stations: [Station] = []
    
    static var count:Int64 = 1


    let manager: CLLocationManager
    
    override init() {
        manager = CLLocationManager()
        super.init()

        manager.delegate = self
        manager.distanceFilter = 100
        manager.requestAlwaysAuthorization()
        print("requested")
    }
    
        
    @Published public var location: CLLocation?
        
    func updateItems(reloadWidget: Bool, location: CLLocation? = nil) async {
        
        let fetched = await StationViewModel.fetchStations(location: location)
        
        DispatchQueue.main.async {
            self.stations = fetched
            if reloadWidget{
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        
    }
    
    
    
    static func fetchStations(location: CLLocation? = nil) async -> [Station] {
        print("Fetch Locations")
        var link = "https://api.wheresthefuckingtrain.com/by-id/F15"
        if let location = location {
            link = "https://api.wheresthefuckingtrain.com/by-location?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)"
            print(link)
        }
        
        
        guard let url = URL(string: link) else { fatalError("Missing URL") }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        var jsonResponse: [AnyObject] = []

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return []}
            let json = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, AnyObject>
            jsonResponse = json["data"] as! [AnyObject]
        }
        catch {
            jsonResponse = []
            print("Error decoding", error)
            
        }
        var fetched: [Station] = []
        jsonResponse.forEach{ station in
            guard let station = station as? [String:AnyObject] else {return}
            guard let name = station["name"] as? String else {return}
                guard let north = station["N"] as? [Dictionary<String, AnyObject>] else {return}
                guard let south = station["S"] as? [Dictionary<String, AnyObject>] else {return}
                let formatter = DateFormatter()
                
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                
                let northOut = north.map{item in
                    let route = item["route"]
                    let time = item["time"] as! String
                    let timeDate = formatter.date(from: time)
                    
                    return Arrival(route: route as! String, time: timeDate!, stationID: station["id"] as! String, name: station["name"] as! String)
                }
                
                let southOut = south.map{item in
                    let route = item["route"]
                    let time = item["time"] as! String
                    let timeDate = formatter.date(from: time)
                    
                    return Arrival(route: route as! String, time: timeDate!, stationID: station["id"] as! String, name: station["name"] as! String)
                }
                let location = station["stops"] as! Dictionary<String, [Double]>
                let loca = location.sorted(by: {$0.key < $1.key})
            fetched.append(Station(name: name, north: northOut, south: southOut, location: CLLocation(latitude: loca[0].value[0], longitude: loca[0].value[1])))
            

        }
        return fetched
    }
    
    static func fetchStation(id: String) async -> Station {
        var link = "https://api.wheresthefuckingtrain.com/by-id/\(id)"
        
        
        guard let url = URL(string: link) else { fatalError("Missing URL") }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        var jsonResponse: [AnyObject] = []

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return Station(name: ""
                                                                                          , north: [], south: [], location: CLLocation(latitude: 10, longitude: 10))}
            let json = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, AnyObject>
            jsonResponse = json["data"] as! [AnyObject]
        }
        catch {
            jsonResponse = []
            print("Error decoding", error)
            
        }
        var stationReturn = Station(name: ""
                              , north: [], south: [], location: CLLocation(latitude: 10, longitude: 10))
        jsonResponse.forEach{ station in
            guard let station = station as? [String:AnyObject] else {return}
            guard let name = station["name"] as? String else {return}
                guard let north = station["N"] as? [Dictionary<String, AnyObject>] else {return}
                guard let south = station["S"] as? [Dictionary<String, AnyObject>] else {return}
                let formatter = DateFormatter()
                
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                
                let northOut = north.map{item in
                    let route = item["route"]
                    let time = item["time"] as! String
                    let timeDate = formatter.date(from: time)
                    
                    return Arrival(route: route as! String, time: timeDate!, stationID: station["id"] as! String, name: station["name"] as! String)
                }
                
                let southOut = south.map{item in
                    let route = item["route"]
                    let time = item["time"] as! String
                    let timeDate = formatter.date(from: time)
                    
                    return Arrival(route: route as! String, time: timeDate!, stationID: station["id"] as! String, name: station["name"] as! String)
                }
                let location = station["stops"] as! Dictionary<String, [Double]>
                let loca = location.sorted(by: {$0.key < $1.key})
            stationReturn = Station(name: name, north: northOut, south: southOut, location: CLLocation(latitude: loca[0].value[0], longitude: loca[0].value[1]))
            

        }
        return stationReturn
    }
    
    static func fetchRoute(route: String) async -> [Station] {
        var link = "https://api.wheresthefuckingtrain.com/by-route/\(route)"
        
        
        guard let url = URL(string: link) else { fatalError("Missing URL") }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        var jsonResponse: [AnyObject] = []

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return []}
            let json = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, AnyObject>
            jsonResponse = json["data"] as! [AnyObject]
        }
        catch {
            jsonResponse = []
            print("Error decoding", error)
            
        }
        var stations: [Station] = []
        jsonResponse.forEach{ station in
            guard let station = station as? [String:AnyObject] else {return}
            guard let name = station["name"] as? String else {return}
                guard let north = station["N"] as? [Dictionary<String, AnyObject>] else {return}
                guard let south = station["S"] as? [Dictionary<String, AnyObject>] else {return}
                let formatter = DateFormatter()
                
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                
                let northOut = north.map{item in
                    let route = item["route"]
                    let time = item["time"] as! String
                    let timeDate = formatter.date(from: time)
                    
                    return Arrival(route: route as! String, time: timeDate!, stationID: station["id"] as! String, name: station["name"] as! String)
                }
                
                let southOut = south.map{item in
                    let route = item["route"]
                    let time = item["time"] as! String
                    let timeDate = formatter.date(from: time)
                    
                    return Arrival(route: route as! String, time: timeDate!, stationID: station["id"] as! String, name: station["name"] as! String)
                }
                let location = station["stops"] as! Dictionary<String, [Double]>
                let loca = location.sorted(by: {$0.key < $1.key})
            stations.append(Station(name: name, north: northOut, south: southOut, location: CLLocation(latitude: loca[0].value[0], longitude: loca[0].value[1])))
            

        }
        return stations
    }
    
    public func requestLocation() {
        DispatchQueue.main.async {
            self.manager.startUpdatingLocation()
        }
    }
    nonisolated public func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print(error)
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location")
        Task {
            await self.updateItems(reloadWidget: true, location: locations.last)
        }
        DispatchQueue.main.async {
            self.location = locations.last
        }
        
    }
}

class ArrivalsViewModel: ObservableObject {
    var stations: [Station] = []
    
    func updateStationsObject(route: String) async {
        let stationObj = await StationViewModel.fetchRoute(route: route)
        stations.append(contentsOf: stationObj)
    }
    
    func updateStations(routes: [String]) async {
        for route in routes {
            let stationObj = await StationViewModel.fetchStation(id: route)
            stations.append(stationObj)
        }
    }
}

public struct Station: Identifiable {
    public var id: CLLocation { location }
    
    var name: String
    var north: [Arrival]
    var south: [Arrival]
    var location: CLLocation
}
