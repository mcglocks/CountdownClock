//
//  LiveActivityUtil.swift
//  LiveActivity
//
//  Created by Praveenraj T on 11/10/23.
//

import Foundation
import ActivityKit

@available(iOS 16.1, *)
class LiveActivityUtil{



    static func startLiveActivity(for activityData:Countdown_WidgetAttributes,state contentState:Countdown_WidgetAttributes.ContentState){
        do{
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: contentState, staleDate: Date(timeIntervalSinceNow: 10))
                let _ =  try Activity<Countdown_WidgetAttributes>.request(attributes: activityData, content: content)

            } else {
                // Fallback on earlier versions
                    let _ = try Activity<Countdown_WidgetAttributes>.request(attributes: activityData, contentState: contentState)

            }

        }catch{
            print("Error:\(error)")
        }
    }

    static func updateLiveActivity(for recordId:Int64,contentState state:Countdown_WidgetAttributes.ContentState){
        guard let activity = getLiveActivity(for: recordId) else{
            return
        }
        if #available(iOS 16.2, *) {
            let content = ActivityContent(state: state, staleDate: nil)
            Task{
                await  activity.update(content)
            }
        } else  {
            Task{
                await  activity.update(using: state)
            }
        }
    }

    static func endLiveActvity(for recordId:String,contentState state:Countdown_WidgetAttributes.ContentState? = nil,dismissalPolicy:ActivityUIDismissalPolicy = .immediate){
        guard let id = Int64(recordId), let activity = getLiveActivity(for: id) else{
            return
        }
        Task{
            if #available(iOS 16.2, *),let state {
                let content = ActivityContent(state: state, staleDate: nil)
                await  activity.end(content,dismissalPolicy:dismissalPolicy)
            }else{
                await activity.end(using:state,dismissalPolicy: dismissalPolicy)
            }
        }
    }

    static func getCurrentStateData(forRecordId id:String)-> Countdown_WidgetAttributes.ContentState?{
        guard let recordId = Int64(id) else {return nil}
        let activity = getLiveActivity(for: recordId)
        if #available(iOS 16.2, *) {
            return activity?.content.state
        } else {
            return activity?.contentState
        }
    }

    static func getLiveActivity(for recordId:Int64) -> Activity<Countdown_WidgetAttributes>?{
        Activity<Countdown_WidgetAttributes>.activities.first(where: {$0.attributes.recordId == recordId})
    }
}

@available(iOS 17.0,*)
extension LiveActivityUtil{


    static func updateLiveActivity(forRecordID id:String,state:Countdown_WidgetAttributes.ContentState){
        guard let recordId = Int64(id) else{
            return
        }
        updateLiveActivity(for: recordId, contentState: state)
    }
}
