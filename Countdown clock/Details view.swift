//
//  Details view.swift
//  Countdown clock
//
//  Created by Max McLoughlin on 11/20/23.
//

import Foundation
import SwiftUI
import CoreLocation

struct DetailsView: View {
    
    @State var test = "here"
    @StateObject var arrivalsViewModel = ArrivalsViewModel()
    @StateObject var timer = TimeViewModel()
    @State var lastFetched = Date.now
    @State var arrival: Arrival
    var isUptown: Bool
    var formatter = {
        let format = DateFormatter()
        format.dateFormat = "HH:mm:ss"
        return format
    }()

    
    public var body: some View{
        NavigationView {
            ZStack{
                ContainerRelativeShape()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(cgColor: CGColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)), .black]), startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack{
                    HStack {
                        Text("\(isUptown ? "Uptown" : "Downtown")")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white)
                        Bullet(route: arrival.route, color: Color("\(arrival.route.lowercased())_train"))
                            .frame(width: 20, height: 20)

                        Text("train")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white)

                    }
                    HStack{
                        Text("Departs")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white)
                        Text("\(arrival.name) ")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.white)
                            .bold()
                        Text("in :")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white)
                        Text("\(getTime(time:arrival.time))")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.white)


                    }
                    ScrollView{
                        VStack{
                            ForEach(arrivalsViewModel.stations){ station in
                                VStack{
                                    
                                    Text(station.name)
                                        .font(.title3)
                                        .foregroundStyle(Color.white)
                                    HStack{
                                        Text("Uptown")
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color.white)
                                        Spacer()
                                        Text("Downtown")
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color.white)
                                        
                                    }
                                    HStack(alignment: .top){
                                        VStack(alignment: .leading){
                                            Times(arrivals: station.north, offset: 0, now: $timer.currentTime, isUptown: true, minTime: getTimeDouble(time: arrival.time))
                                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                            
                                        }
                                        VStack(alignment: .trailing) {
                                            
                                            Times(arrivals: station.south, offset: 0, now: $timer.currentTime, isUptown: false, minTime: getTimeDouble(time: arrival.time))
                                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                                            
                                            
                                        }
                                    }
                                    
                                }
                                
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: 75, leading: 20, bottom: 20, trailing: 20))
                .frame(alignment: .topLeading)
                .task {
                    let stations = getStations(arrival: arrival)
                    await arrivalsViewModel.updateStations(routes: stations)
                }
                    
                
            }
            .ignoresSafeArea()
        }
    }
        
        func lastRefreshed () -> String {
            let ref = lastFetched
            return formatter.string(from: ref)
        }
    
    func getStations(arrival: Arrival) ->  [String] {
        var stations: [String] = Routes.getArrayOfStations(route: arrival.route)
        var stationsReturn: [String] = []
        var index = stations.firstIndex(of: arrival.stationID) ?? 0
        if isUptown {
            for i in stride(from: index - 1, through: max(index - 5, 0), by: -1) {
                stationsReturn.append(stations[i])
            }
        } else {
            
            for i in index + 1...min(5 + index, stations.count - 1) {
                stationsReturn.append(stations[i])
            }
            
        }
        return stationsReturn
    }
    
    func getTime(time: Date) -> String {
        let nowDouble = Date.now
        let diff = (time.timeIntervalSinceReferenceDate - nowDouble.timeIntervalSinceReferenceDate)
        
        let min = Int(floor(diff / 60))
        let sec = Int(floor(diff).truncatingRemainder(dividingBy: 60))
        if (min < 0 && sec < 0){
            return "left"
        }
        var secondString = "\(sec)"
        if sec < 10 {
            secondString = "0\(sec)"
        }
        return "\(min):\(secondString)"
    }
    func getTimeDouble(time: Date) -> Double {
        let nowDouble = Date.now
        let diff = (time.timeIntervalSinceReferenceDate - nowDouble.timeIntervalSinceReferenceDate)
    
        return diff
    }
}
