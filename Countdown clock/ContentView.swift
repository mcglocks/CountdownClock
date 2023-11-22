//
//  ContentView.swift
//  Countdown clock
//
//  Created by Max McLoughlin on 11/6/23.
//

import SwiftUI
import WidgetKit
import CoreLocationUI
import CoreLocation
import ActivityKit

struct ContentView: View {

    
    
    @State var test = "here"
    @StateObject var stationsViewModel = StationViewModel()
    @StateObject var timer = TimeViewModel()
    @Environment(\.scenePhase) var scenePhase
    @State var lastFetched = Date.now
    var formatter = {
        let format = DateFormatter()
        format.dateFormat = "HH:mm:ss"
        return format
    }()
        

    
    
    var body: some View {
        NavigationStack {
            ZStack{
                ContainerRelativeShape()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(cgColor: CGColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)), .black]), startPoint: .topLeading, endPoint: .bottomTrailing))
                ScrollView{
                    VStack{
                        Text("Last Refresh")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white)
                        
                        Text(lastRefreshed())
                            .foregroundStyle(Color.white)
                        
                    }
                    VStack{
                        if stationsViewModel.location == nil {
                            Text("Waiting for location...")
                        }
                        ForEach(stationsViewModel.stations.sorted(by: {left, right in
                            (stationsViewModel.location?.distance(from: left.location) ?? 0 < stationsViewModel.location?.distance(from: right.location) ?? 0)
                        })){ station in
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
                                        Times(arrivals: station.north, offset: 0, now: $timer.currentTime, isUptown: true)
                                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                        
                                    }
                                    VStack(alignment: .trailing) {
                                        
                                        Times(arrivals: station.south, offset: 0, now: $timer.currentTime, isUptown: false)
                                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                                        
                                        
                                    }
                                }
                                
                            }
                            
                        }
                    }
                }
                .padding(EdgeInsets(top: 75, leading: 20, bottom: 20, trailing: 20))
                .frame(alignment: .topLeading)
                .task(id: scenePhase) {
                    stationsViewModel.requestLocation()
                    await stationsViewModel.openActivity()
//                    if scenePhase == .background{
//                        await stationsViewModel.updateItems(reloadWidget: true, location: stationsViewModel.location)
//                        lastFetched = Date.now
//                    } else if scenePhase == .inactive{
//                        await stationsViewModel.updateItems(reloadWidget: false, location: stationsViewModel.location)
//                        lastFetched = Date.now
//                        
//                    }
//                    else{
//                        await stationsViewModel.updateItems(reloadWidget: false, location: stationsViewModel.location)
//                        lastFetched = Date.now
//                        
//                    }
                    
                }
                .refreshable {
                    print("refreshing")
                    await stationsViewModel.updateItems(reloadWidget: true, location: stationsViewModel.location)
                    lastFetched = Date.now
                    
                }
                
            }
            .ignoresSafeArea()
        }
    }
        func lastRefreshed () -> String {
            let ref = lastFetched
            return formatter.string(from: ref)
        }
    
}

//struct StationView: View {
//    
//    var station: Station
//   
//    var body: some View {
//        VStack {
//            Text("Manhattan").padding(10)
//            ForEach(station.north){arrival in
//                Text("\(arrival.route): \(getTime(time: arrival.time))")
//            }
//            Text("Brooklyn").padding(10)
//            ForEach(station.south){arrival in
//                Text("\(arrival.route): \(getTime(time: arrival.time))")
//            }
//        }
//        .background(Color.gray)
//        .cornerRadius(20)
//        
//    }
//    
//    func getTime(time: Date) -> String {
//        let now = Date.now
//        let diff = (time.timeIntervalSinceReferenceDate - now.timeIntervalSinceReferenceDate )
//        
//        let min = Int(floor(diff / 60))
//        let sec = Int(floor(diff).truncatingRemainder(dividingBy: 60))
//        if (min < 0 && sec < 0){
//            return "left"
//        }
//        return "\(min):\(sec)"
//    }
//    
//}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Bullet: View {
    var route: String
    var color: Color
    var textColor: Color
    
    init(route: String, color: Color) {
        self.route = route
        self.color = color
        if route == "Q" || route == "N" || route == "R" || route == "W"{
            self.textColor = Color.black
        } else {
            self.textColor = Color.white

        }
    }
    
    var body: some View {
        ZStack {
            Circle().foregroundStyle(color)
            Text(route).font(.bold(.system(size: 13))())
                .foregroundStyle(textColor)
        }
        
    }
}

struct Times: View {
    @State var arrivals: [Arrival]
    var offset: Int
    @Binding var now: Date
    var inverse = false
    var isUptown = true
    var minTime = 0.0

    
    public var body: some View{
        ForEach(getArrivals()){ arrival in
            TimeSquare(arrival: arrival, offset: offset, inverse: inverse, now: $now, isUptown: isUptown)

        }
    }
    
    func getArrivals() -> [Arrival]{
        var arr = arrivals.filter({
            let diff = ($0.time.timeIntervalSinceReferenceDate - Date.now.timeIntervalSinceReferenceDate - Double(offset))
            return diff > minTime
        })
        return arr
    }
    
}
struct TimeSquare: View {
    @State var arrival: Arrival
    var offset: Int
    var inverse: Bool
    @Binding var now: Date
    @State var isActive = false
    var isUptown = true
    
    var body: some View{
        NavigationLink(destination: DetailsView(arrival: arrival, isUptown: isUptown)){
            HStack{
                if getTime(time: arrival.time) == "left"{
                    Spacer()
                }else {
                    if inverse {
                        Text(getTime(time: arrival.time))
                            .foregroundStyle(Color.white)
                            .font(.system(size: 13))
                        Bullet(route: arrival.route, color: Color("\(arrival.route.lowercased())_train"))
                            .frame(width: 20, height: 20)
                    } else{
                        Bullet(route: arrival.route, color: Color("\(arrival.route.lowercased())_train"))
                            .frame(width: 20, height: 20)
                        Text(getTime(time: arrival.time))
                            .foregroundStyle(Color.white)
                            .font(.system(size: 13))
                    }
                }
            }
        }
    }
    func getTime(time: Date) -> String {
        let nowDouble = now
        let diff = (time.timeIntervalSinceReferenceDate - nowDouble.timeIntervalSinceReferenceDate - Double(offset))
        
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
}
