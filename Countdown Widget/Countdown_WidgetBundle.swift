//
//  Countdown_WidgetBundle.swift
//  Countdown Widget
//
//  Created by Max McLoughlin on 11/6/23.
//

import WidgetKit
import SwiftUI

@main
struct Countdown_WidgetBundle: WidgetBundle {
    var body: some Widget {
        Countdown_Widget()
        Countdown_WidgetLiveActivity()
    }
}
