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
            NavigationView {
                CourseList()
            }
            .colorScheme(.light)
        }
    }
}

