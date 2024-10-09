//
//  Apperance.swift
//  this-day
//
//  Created by Sergey Bendak on 9.10.2024.
//

import UIKit

final class Apperance {
    static func apply() {
        applyTabBarAppearance()
        applyNavigationBarAppearance()
        applySegmentedControlAppearance()
    }

    private static func applyTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.main

        let selectedItemAppearance = UITabBarItemAppearance()
        selectedItemAppearance.normal.iconColor = UIColor.unavailable
        selectedItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.unavailable]
        selectedItemAppearance.selected.iconColor = UIColor.white
        selectedItemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]

        tabBarAppearance.stackedLayoutAppearance = selectedItemAppearance
        tabBarAppearance.inlineLayoutAppearance = selectedItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = selectedItemAppearance

        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }

    private static func applyNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.main
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    private static func applySegmentedControlAppearance() {
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = UIColor.main
        appearance.backgroundColor = UIColor.unavailable.withAlphaComponent(0.3)
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white
        ]
        appearance.setTitleTextAttributes(normalTextAttributes, for: .normal)
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white
        ]
        appearance.setTitleTextAttributes(selectedTextAttributes, for: .selected)
    }
}
