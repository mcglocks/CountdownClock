//
//  Countdown_Widget.swift
//  Countdown Widget
//
//  Created by Max McLoughlin on 11/6/23.
//

import WidgetKit
import SwiftUI
import Intents
import CoreLocation



struct Provider: IntentTimelineProvider {
    

    func placeholder(in context: Context) -> SecondEntry {
        return SecondEntry(date: Date(), configuration: ConfigurationIntent(), name: "Delancey", north: [], south: [], refreshTime: Date())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SecondEntry) -> ()) {
        let entry = SecondEntry(date: Date(), configuration: ConfigurationIntent(), name: "Delancey", north: [], south: [], refreshTime: Date())
        completion(entry)
    }

    var widgetLocationManager = StationViewModel()
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            widgetLocationManager.requestLocation()
            let stations = await StationViewModel.fetchStations(location: widgetLocationManager.location)
                
            var entries: [SecondEntry] = []

            // Generate a timeline consisting of five entries an hour apart, starting from the current date.
            let currentDate = Date()
            var afterdate = Calendar.current.date(byAdding: .second, value: 900, to: currentDate)!
            
            var manhattan: [Arrival] = []
            var brooklyn: [Arrival] = []
            
            var station = stations[0]
            if let location = widgetLocationManager.location {
                station = stations.sorted(by: {left, right in
                    location.distance(from: left.location) < location.distance(from: right.location)
                })[0]
                
            } else{
                afterdate = Calendar.current.date(byAdding: .second, value: 100, to: currentDate)!
            }
            station.north.forEach{ stat in
                manhattan.append(stat)
            }
            
            station.south.forEach{ stat in
                brooklyn.append(stat)
            }
            
            manhattan = manhattan.sorted{ $0.time < $1.time}

            brooklyn = brooklyn.sorted{ $0.time < $1.time}
            
            var entryDate = Date.now
            for train in manhattan {
                var manhattanTime = manhattan.filter{$0.time > entryDate}
                var brooklynTime = brooklyn.filter{$0.time > entryDate}
                let entry = SecondEntry(date: entryDate, configuration: ConfigurationIntent(),  name: station.name, north: manhattanTime, south: brooklynTime, refreshTime: afterdate)
                entryDate = train.time

                entries.append(entry)
            }
             entryDate = Date.now

            for train in brooklyn {
                var manhattanTime = manhattan.filter{$0.time > entryDate}
                var brooklynTime = brooklyn.filter{$0.time > entryDate}
                let entry = SecondEntry(date: entryDate, configuration: ConfigurationIntent(),  name: station.name, north: manhattanTime, south: brooklynTime, refreshTime: afterdate)
                
                entryDate = train.time


                entries.append(entry)
            }
            entries = entries.sorted{ $0.date < $1.date}
            entries = entries.filter{
                $0.date < entryDate
            }
//            entries.remove(at: 0)

            let timeline = Timeline(entries: entries, policy: .after(afterdate))
            completion(timeline)
            }
    }
}

struct SecondEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let name: String
    let north: [Arrival]
    let south: [Arrival]
    let refreshTime: Date
}



struct Countdown_WidgetEntryView : View {
    
    var entry: Provider.Entry
    
    var colors = [
        "a": Color("a_train"),
        "b": Color("b_train"),
        "c": Color("c_train"),
        "d": Color("d_train"),
        "e": Color("e_train"),
        "f": Color("f_train"),
        "fx": Color("fx_train"),
        "g": Color("g_train"),
        "j": Color("j_train"),
        "l": Color("l_train"),
        "m": Color("m_train"),
        "n": Color("n_train"),
        "q": Color("q_train"),
        "r": Color("r_train"),
        "s": Color("s_train"),
        "w": Color("w_train"),
        "z": Color("z_train"),
        "1": Color("1_train"),
        "2": Color("2_train"),
        "3": Color("3_train"),
        "4": Color("4_train"),
        "5": Color("5_train"),
        "6": Color("6_train"),
        "6x": Color("6x_train"),
        "7": Color("7_train"),
        "7x": Color("7x_train"),
        "SI": Color("si_train")
    ]

    
    var body: some View {
        ZStack{
            HStack(alignment: .top){
                VStack(alignment: .leading, spacing: 5){
                    Text("Uptown")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white)
                    Times(arrivals: entry.north, colors: colors)

                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                VStack{
                    Text(entry.name).font(.system(size: 10))
                        .foregroundStyle(Color.white)
                    Spacer()
                        .foregroundStyle(Color.white)
                    Text("Next Refresh")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white)
                    Text(nextRefreshed())
                        .foregroundStyle(Color.white)
                    Text("Next Refresh In")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white)

                    Text(Calendar.current.date(byAdding: tillRefresh(), to: Date())!, style: .timer)
                        .foregroundStyle(Color.white)
                    
                }

                VStack(alignment: .trailing, spacing: 5){
                    Text("Downtown")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white)
                    Times(arrivals: entry.south, inverse: true, colors: colors)

                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
            }
            .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            .frame(alignment: .topLeading)
            .widgetBackground(backgroundView:
                ContainerRelativeShape()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(cgColor: CGColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)), .black]), startPoint: .topLeading, endPoint: .bottomTrailing))            )
    
        }

    }
    
    func nextRefreshed () -> String {
        let ref = entry.refreshTime
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: ref)
    }
    
    func tillRefresh () -> DateComponents{
        var diff = entry.refreshTime.timeIntervalSinceNow

        let min = Int(floor(Double(diff / 60)))
        let sec = Int(Double(diff).truncatingRemainder(dividingBy: 60))
        return DateComponents(minute: min, second: sec)
    }
    


}

extension View {
func widgetBackground(backgroundView: some View) -> some View {
if #available(watchOS 10.0, iOSApplicationExtension 17.0, iOS 17.0, macOSApplicationExtension 14.0, *) {
    return containerBackground(for: .widget) {
        backgroundView
    }
} else {
    return background(backgroundView)
}
}
}

struct Times: View {
    var arrivals: [Arrival]
    var inverse = false
    var colors: Dictionary<String, Color>
    
    var body: some View{
        ForEach(getArrivals()){ arrival in
            TimeSquare(arrival: arrival, inverse: inverse, colors: colors)
        }
    }
    
    func getArrivals() -> [Arrival]{
        let now = Date.now
        var arr = arrivals.filter({
            let diff = ($0.time.timeIntervalSinceReferenceDate - now.timeIntervalSinceReferenceDate)
            return diff > 0
        })
        if arr.count < 5{
            // iterate from i = 1 to i = 3
            for _ in arr.count...5 {
                arr.append(Arrival(route: "NO TRAIN", time: Date.distantFuture, stationID: "F15", name: "Delancey"))
            }

        }
        return Array(arr[0..<min(arr.count, 5)])
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

struct TimeSquare: View {
    var arrival: Arrival
    var inverse: Bool
    var colors: Dictionary<String, Color>
    
    var body: some View{
        HStack{
            if arrival.route == "NO TRAIN"{
                Spacer()
            }else {
                if inverse {
                    Text(Calendar.current.date(byAdding: getTime(time: arrival.time), to: Date())!, style: .timer)
                        .foregroundStyle(Color.white)
                        .font(.system(size: 13))
                    Bullet(route: arrival.route, color: colors[arrival.route.lowercased()] ?? Color.purple)
                        .frame(width: 20, height: 20)
                } else{
                    Bullet(route: arrival.route, color: colors[arrival.route.lowercased()] ?? Color.purple)
                        .frame(width: 20, height: 20)
                    Text(Calendar.current.date(byAdding: getTime(time: arrival.time), to: Date())!, style: .timer)
                        .foregroundStyle(Color.white)
                        .font(.system(size: 13))
                }
            }
        }
    }
    func getTime(time: Date) -> DateComponents {
        let now = Date.now
        let diff = (time.timeIntervalSinceReferenceDate - now.timeIntervalSinceReferenceDate)
        
        let min = Int(floor(diff / 60))
        let sec = Int(floor(diff).truncatingRemainder(dividingBy: 60))
//        if (min < 0 && sec < 0){
//            return "left"
//        }
//        var secondString = "\(sec)"
//        if sec < 10 {
//            secondString = "0\(sec)"
//        }
        return DateComponents(minute: min, second: sec)
    }
}

struct Countdown_Widget: Widget {
    let kind: String = "Countdown_Widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            Countdown_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemMedium])
    }
}



struct Countdown_Widget_Previews: PreviewProvider {
    static var previews: some View {
        Countdown_WidgetEntryView(entry: SecondEntry(date: Date(), configuration: ConfigurationIntent(), name: "Delancey", north: [], south: [], refreshTime: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
