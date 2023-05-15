//
//  LessonsApp.swift
//  Lessons
//
//  Created by nate parrott on 3/26/23.
//

import SwiftUI

@main
struct LessonsApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CourseList()
            }
//            NavigationView {
//                CourseList()
//            }
            .colorScheme(.light)
            .preferredColorScheme(.light)
        }
    }
}
