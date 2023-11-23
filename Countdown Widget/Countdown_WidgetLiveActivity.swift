//
//  Countdown_WidgetLiveActivity.swift
//  Countdown Widget
//
//  Created by Max McLoughlin on 11/6/23.
//

import ActivityKit
import WidgetKit
import SwiftUI
import CoreLocation
import AppIntents

struct Countdown_WidgetAttributes: ActivityAttributes {
    
    public struct ContentState: Codable & Hashable {
        
        
        // Dynamic stateful properties about your activity go here!
        var north: [Arrival]
        var south: [Arrival]
        var now: Date
        var name: String
        var latitude: Double
        var longitude: Double
    }
    
    // Fixed non-changing properties about your activity go here!
    let recordId: Int64
}

struct UpdateIntent: LiveActivityIntent {
    
    static var title: LocalizedStringResource = "Check for Updates"
    static var description = IntentDescription("Update latest match scores.")
    
    @Parameter(title:"RecordId")
    var recordId : String

    init(recordId: String){
        self.recordId = recordId

    }
    
    public init() { }
    
    
    //triggered by press to button
    func perform() async throws -> some IntentResult {
        
        var vm = WidgetViewModel()
        
        let current = LiveActivityUtil.getCurrentStateData(forRecordId: recordId)
        let location = vm.manager.location

        let currentlocation = CLLocation(latitude: current!.latitude, longitude: current!.longitude)


        let fetched = await StationViewModel.fetchStations(location: location)
        let sorted = fetched.sorted(by: {left, right in
            (location?.distance(from: left.location) ?? currentlocation.distance(from: left.location) < location?.distance(from: right.location) ?? currentlocation.distance(from: right.location) )
        })
        let stationStatus = Countdown_WidgetAttributes.ContentState(north: sorted[0].north, south: sorted[0].south, now: Date.now,name: sorted[0].name, latitude: current!.latitude, longitude: current!.longitude)
        if #available(iOSApplicationExtension 17.0, *) {
            if #available(iOS 17.0, *) {
                LiveActivityUtil.updateLiveActivity(forRecordID: recordId, state: stationStatus)
            } else {
                // Fallback on earlier versions
            }
        } else {
        }
        return .result()
    }
}

struct Countdown_WidgetLiveActivity: Widget {
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
    ]
    
    var formatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Countdown_WidgetAttributes.self) { context in
            ZStack{
                ContainerRelativeShape()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(cgColor: CGColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)), .black]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .ignoresSafeArea()
                HStack{
                    VStack(alignment: .leading, spacing: 5){
                        Text("Uptown")
                            .font(.system(size: 15))
                        
                            .foregroundStyle(Color.white)
                        AppTimes(arrivals: context.state.north, offset: 0, now: Date.now)

                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    VStack{
                        Text(context.state.name).font(.system(size: 10))
                            .foregroundStyle(Color.white)
                        Text("Last Refresh")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white)
                        
                        Text("\(formatter.string(from: context.state.now))")
                            .foregroundStyle(Color.white)
                        Spacer()
                        if #available(iOS 17, *){
                            Button(intent: UpdateIntent(recordId: context.attributes.recordId.description), label: {
                                Text("Update")
                            })
                        }

                        
                    }

                    VStack(alignment: .trailing, spacing: 5){
                        Text("Downtown")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white)
                        AppTimes(arrivals: context.state.south, offset: 0, now: Date.now, inverse: false)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                }
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                .frame(alignment: .topLeading)
        
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T")
            } minimal: {
                Text("Min")
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

struct Countdown_WidgetLiveActivity_Previews: PreviewProvider {
    static let attributes = Countdown_WidgetAttributes(recordId: 1)
    static let contentState = Countdown_WidgetAttributes.ContentState(north: [Arrival(route: "F", time: Date.now, stationID: "F15", name: "Delancey")], south: [Arrival(route: "J", time: Date.now, stationID: "F15", name: "Delancey")], now: Date.now, name: "Delancey", latitude: 43, longitude: -71)

    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Island Compact")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Island Expanded")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Notification")
    }
}

struct AppTimes: View {
    @State var arrivals: [Arrival]
    var offset: Int
    var now: Date
    var inverse = false

    
    public var body: some View{
        ForEach(getArrivals()){ arrival in
            AppTimeSquare(arrival: arrival, offset: offset, inverse: inverse, now: now)
                

        }
    }
    
    func getArrivals() -> [Arrival]{
        var arr = arrivals.filter({
            let diff = ($0.time.timeIntervalSinceReferenceDate - now.timeIntervalSinceReferenceDate - Double(offset))
            return diff > 0
        })
        if arr.count < 5{
            // iterate from i = 1 to i = 3
            for _ in arr.count...5 {
                arr.append(Arrival(route: "X", time: Date.distantFuture, stationID: "F15", name: "Delancey"))
            }

        }
        return Array(arr[0..<min(arr.count, 5)])
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

struct AppTimeSquare: View {
    @State var arrival: Arrival
    var offset: Int
    var inverse: Bool
    var now: Date
    
    var formatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    var body: some View{
        HStack{
            if getTime(time: arrival.time).minute ?? -1 < 0 {
                Spacer()
            }else {
                if inverse {
                    if arrival.route == "X"{
                        Text("NO TRAIN")
                            .foregroundStyle(Color.white)
                            .font(.system(size: 13))
                    } else {
                        Text(
                            timerInterval: Date.now...arrival.time,
                            pauseTime: arrival.time
                        )
                        Bullet(route: arrival.route, color: Color("\(arrival.route.lowercased())_train"))
                            .frame(width: 20, height: 20)
                    }
                } else{
                    Bullet(route: arrival.route, color: Color("\(arrival.route.lowercased())_train"))
                        .frame(width: 20, height: 20)
                    if arrival.route == "X"{
                        Text("NO TRAIN")
                            .foregroundStyle(Color.white)
                            .font(.system(size: 13))
                    } else {
                        Text(
                            timerInterval: Date.now...arrival.time,
                            pauseTime: (Date.now...arrival.time).lowerBound
                        )
                    }
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
