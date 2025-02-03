//
//  Countdownwatch_complication.swift
//  Countdownwatch complication
//
//  Created by Max McLoughlin on 11/27/23.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent(), in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        // Create an array with all the preconfigured widgets to show.
        [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "Example Widget")]
    }
    func placeholder(in context: Context) -> SecondEntry {
        return SecondEntry(date: Date(), configuration: ConfigurationIntent(), name: "Delancey", north: [], south: [], refreshTime: Date())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SecondEntry) -> ()) {
        let entry = SecondEntry(date: Date(), configuration: ConfigurationIntent(), name: "Delancey", north: [], south: [], refreshTime: Date())
        completion(entry)
    }


    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
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

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct Countdownwatch_complicationEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            HStack {
                Text("Time:")
                Text(entry.date, style: .time)
            }
        
            Text("Favorite Emoji:")
            Text(entry.configuration.favoriteEmoji)
        }
    }
}

@main
struct Countdownwatch_complication: Widget {
    let kind: String = "Countdownwatch_complication"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Countdownwatch_complicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}


#Preview(as: .accessoryRectangular) {
    Countdownwatch_complication()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}    
