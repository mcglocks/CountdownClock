//
//  Countdowncomplication.swift
//  Countdowncomplication
//
//  Created by Max McLoughlin on 11/27/23.
//

import WidgetKit
import SwiftUI
import WatchKit
import ClockKit

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> SecondEntry {
        return SecondEntry(date: Date(), name: "Delancey", north: [], south: [], refreshTime: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SecondEntry) -> ()) {
        let entry = SecondEntry(date: Date(), name: "Delancey", north: [], south: [], refreshTime: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            var widgetLocationManager = WidgetViewModel()
            let stations = await StationViewModel.fetchStations(location: widgetLocationManager.manager.location)
                
            var entries: [SecondEntry] = []

            // Generate a timeline consisting of five entries an hour apart, starting from the current date.
            let currentDate = Date()
            var afterdate = Calendar.current.date(byAdding: .second, value: 900, to: currentDate)!
            
            var manhattan: [Arrival] = []
            var brooklyn: [Arrival] = []
            
            var station = stations[0]
            if let location = widgetLocationManager.manager.location {
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
                let entry = SecondEntry(date: entryDate, name: station.name, north: manhattanTime, south: brooklynTime, refreshTime: afterdate)
                entryDate = train.time

                entries.append(entry)
            }
             entryDate = Date.now

            for train in brooklyn {
                var manhattanTime = manhattan.filter{$0.time > entryDate}
                var brooklynTime = brooklyn.filter{$0.time > entryDate}
                let entry = SecondEntry(date: entryDate,  name: station.name, north: manhattanTime, south: brooklynTime, refreshTime: afterdate)
                
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
    let name: String
    let north: [Arrival]
    let south: [Arrival]
    let refreshTime: Date
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct CountdowncomplicationEntryView : View {
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
    var arrivals = [Arrival(route: "NO", time: Date.now, stationID: "F15", name: "NO")]
    
    init(entry: Provider.Entry) {
        self.entry = entry
        arrivals = getArrivals()
    }

    
    var body: some View {
        ZStack{
            Image(systemName: "arrow.down")
        }.widgetLabel{
                getTrain() + getText()
        }
        .frame(width: 40, height: 40)

    }
    
    func getText() -> Text {
        if arrivals.count == 2 {
            Text("  |  \(arrivals[1].route): ") + Text(
                timerInterval: Date.now...arrivals[1].time,
                pauseTime: (Date.now...arrivals[1].time).lowerBound
            )
        } else {
            Text("")
        }
    }
    func getTrain() -> Text {
        if arrivals.count >= 1 {
            Text("\(arrivals[0].route): ") + Text(
                timerInterval: Date.now...arrivals[0].time,
                pauseTime: (Date.now...arrivals[0].time).lowerBound
            )
        } else {
            Text("No trains")
        }
    }
    
    
    func getArrivals() -> [Arrival]{
        let now = Date.now
        var arr = entry.south.filter({
            let diff = ($0.time.timeIntervalSinceReferenceDate - now.timeIntervalSinceReferenceDate)
            return diff > 0
        })
        
        return Array(arr[0..<min(2, arr.count)])
//        if arr.count < 2{
//            // iterate from i = 1 to i = 3
//            for _ in arr.count...2 {
//                arr.append(Arrival(route: "X", time: Date.distantFuture, stationID: "F15", name: "Delancey"))
//            }
//
//        }
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
            self.textColor = Color.black

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


@main
struct Countdowncomplication: Widget {
    let kind: String = "Countdowncomplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(watchOS 10.0, *) {
                CountdowncomplicationEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                CountdowncomplicationEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Downtown")
        .description("This is an example widget.")
    }
}

#Preview(as: .accessoryRectangular) {
    Countdowncomplication()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
