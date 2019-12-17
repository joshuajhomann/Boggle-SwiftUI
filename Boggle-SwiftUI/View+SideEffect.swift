//
//  View+SideEffect.swift
//  Boggle-SwiftUI
//
//  Created by Joshua Homann on 12/17/19.
//  Copyright © 2019 raya. All rights reserved.
//

import SwiftUI

extension View {
  func sideEffect(_ sideEffect: @escaping () -> Void) -> some View {
    sideEffect()
    return self
  }
}
