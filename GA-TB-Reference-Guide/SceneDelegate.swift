//
//  SceneDelegate.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit
import Pendo
import Firebase
import AppTrackingTransparency

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let chapterIndex = ChapterIndex()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        
//        This person is a genius https://www.donnywals.com/handling-deeplinks-in-your-app/
        if let userActivity = connectionOptions.userActivities.first {
            self.scene(scene, continue: userActivity)
          }
        
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        ThemeManager.shared.applyStoredTheme()
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
        
        // Need to include this here because we are using the SceneDelegate so it overrides all functions in AppDelegate
        // https://stackoverflow.com/questions/69418845/app-tracking-transparency-dialog-does-not-appear-on-ios
        // This is to ask user if they are okay being tracked or not
//        if #available(iOS 14.0, *){
//        ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
//            // Tracking authorization completed. Start loading ads here.
//          })
//        }
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
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
       if let url = URLContexts.first?.url, url.scheme?.range(of: "pendo") !=
     nil {
         PendoManager.shared().initWith(url)
       }
       // your code here…
     }
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
//
//        print("after here")
//      return application(app, open: url,
//                         sourceApplication: options[UIApplication.OpenURLOptionsKey
//                           .sourceApplication] as? String,
//                         annotation: "")
//    }
//
//    func application(_ application: UIApplication, open url: URL, sourceApplication: String?,
//                     annotation: Any) -> Bool {
//      if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
//        // Handle the deep link. For example, show the deep-linked content or
//        // apply a promotional offer to the user's account.
//        // ...
//          print("this is the dynamic link",dynamicLink)
//
//        return true
//      }
//        print("but not here")
//      return false
//    }
    
    func handleIncomingDynamicLink(_ dynamicLink: DynamicLink){
        guard let url = dynamicLink.url else {
            print("Dynamic link doesn't have a URL")
            return
        }
        print("your dynamic link parameter is \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { return }
        
        if components.path == "/share" {
            // Loading specific piece of content
            if let chapterIdQueryItem = queryItems.first(where: {$0.name == "chapterId"}) {
                guard let chapterId = chapterIdQueryItem.value else { return }
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                guard let newWebVC = storyboard.instantiateViewController(withIdentifier: "web") as? WebViewViewController else { return }
                // Pass parameters to VC
                newWebVC.uniqueAddress = chapterId
                newWebVC.url = Bundle.main.url(forResource: chapterId, withExtension: "html")!
                newWebVC.titlelabel = chapterIndex.subChapterNames[Array(chapterIndex.chapterCode.joined()).firstIndex(of: chapterId) ?? 0]
                                 
                let tabBC = self.window?.rootViewController as? UITabBarController
                let navigationController = tabBC?.selectedViewController as? UINavigationController
                navigationController?.pushViewController(newWebVC, animated: true)
                
                // Modal presentation also works, with less casts too
//                self.window?.rootViewController?.present(newWebVC, animated: true, completion: {
//                    print("presented the controller")
//                })
            }
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let incomingURL = userActivity.webpageURL {
            print("incoming URL is \(incomingURL)")
            _ = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { dynamiclink, error in
                guard error == nil else {
                    print("Found an error! \(error!.localizedDescription)")
                    return
                }
                if let dynamicLink = dynamiclink {
                    self.handleIncomingDynamicLink(dynamicLink)
                }
                // ...
              }
            print("App doesn't handle any other links so no need for extra handling")
        }
    }
}

