//
//  SceneDelegate.swift
//  mennikki
//
//  Created by 八木佑樹 on 2026/02/06.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = createTabBarController()
        self.window = window
        window.makeKeyAndVisible()
    }

    // MARK: - Setup

    /// TabBarControllerを作成
    private func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()

        // 記録一覧タブ
        let recordListVC = RecordListViewController()
        let recordListNav = UINavigationController(rootViewController: recordListVC)
        recordListNav.navigationBar.applyAppStyle()
        recordListNav.tabBarItem = UITabBarItem(
            title: "記録",
            image: UIImage(systemName: "fork.knife"),
            tag: 0
        )

        // お気に入りタブ
        let favoriteListVC = FavoriteListViewController()
        let favoriteListNav = UINavigationController(rootViewController: favoriteListVC)
        favoriteListNav.navigationBar.applyAppStyle()
        favoriteListNav.tabBarItem = UITabBarItem(
            title: "お気に入り",
            image: UIImage(systemName: "heart.fill"),
            tag: 1
        )

        // TabBarControllerにセット
        tabBarController.viewControllers = [recordListNav, favoriteListNav]

        // TabBarのスタイルを適用
        tabBarController.tabBar.applyAppStyle()

        return tabBarController
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // バックグラウンド移行時に未保存の変更を保存
        CoreDataManager.shared.saveIfNeeded()
    }


}

