//
//  RouteManager.swfit
//  FRDIntent
//
//  Created by GUO Lin on 8/30/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

import Foundation

/**
 RouteManager offers the public operation interface of route path search tree.

 We maintains two register systems in one trie tree for saving space.
 Every tree node's value is a tuple (clazz, handler). 
 The clazz is for FRDIntent's register.
 The handler is for URLRoute's register.
 */
class RouteManager {

  static let sharedInstance = RouteManager()
  fileprivate var routes = Trie<RoutePathNodeValueType>()

  // MARK: - Register

  /**
   Register url for save the clazz in the routes.
   
   - parameter url: The path for search the storage position.
   - parameter clazz: The clazz to be saved.
   */
  @discardableResult func register(_ url: URL, clazz: FRDIntentReceivable.Type) -> Bool {

    if let node = routes.searchNodeWithoutMatchPlaceholder(for: url) {
      if let (_, handler) = node.value {
        return routes.insert(url, with: (clazz, handler))
      }
    }
    // not find it, insert
    return routes.insert(url, with: (clazz, nil))
  }

  /**
   Register url for save the handler in the routes.

   - parameter url: The path for search the storage position.
   - parameter hanlder: The handler to be saved.
  */
  @discardableResult func register(_ url: URL, handler: @escaping URLRoutesHandler) -> Bool {
    if let node = routes.searchNodeWithoutMatchPlaceholder(for: url) {
      if let (clazz, _) = node.value {
        return routes.insert(url, with: (clazz, handler))
      }
    }
    // not find it, insert
    return routes.insert(url, with: (nil, handler))
  }

  // MARK: - Unregister

  /**
   Unregister url

   - parameter url: The url to be unregistered
   */
  func unregisterHandler(for url: URL) {
    guard let node = routes.searchNodeWithoutMatchPlaceholder(for: url) else { return }
    if let (clazz, _) = node.value {
      if clazz == nil {
        node.value = nil
        routes.remove(node)
      } else {
        node.value = (clazz, nil)
      }
    }
  }

  func unregisterIntent(for url: URL) {
    guard let node = routes.searchNodeWithoutMatchPlaceholder(for: url) else { return }
    if let (_, handler) = node.value {
      if handler == nil {
        node.value = nil
        routes.remove(node)
      } else {
        node.value = (nil, handler)
      }
    }
  }

  // MARK: - Search

  /**
   Search the controller in in the routes whith the url.

   - parameter url: The url for search the clazz.

   - returns: A tuple with parameters and clazz.
   */
  func searchController(for url: URL) -> ([String: Any], FRDIntentReceivable.Type?) {
    let params = extractParameters(from: url)

    if let (clazz, _) = routes.searchNearestMatchedValue(with: url) {
      return (params, clazz)
    } else {
      return (params, nil)
    }

  }

  /**
   Search the handler in in the route whith the url.

   - parameter url: The url for search the handler.

   - returns: A tuple with parameters and handler.
   */
  func searchHandler(for url: URL) -> ([String: Any], URLRoutesHandler?) {
    let params = extractParameters(from: url)

    if let (_, handler) = routes.searchNearestMatchedValue(with: url) {
      return (params, handler)
    } else {
      return (params, nil)
    }
  }

  // MARK: - Private Methods

  private func extractParameters(from url: URL) -> [String: Any] {

    // Extract placeholder parameters
    var params = routes.matchedPattern(for: url)

    // Add url to params
    params.updateValue(url, forKey: FRDRouteParameters.URLRouteURL)

    // Add queries to params
    if let queryItems = url.queryItems {
      for queryItem in queryItems {
        if let value = queryItem.value {
          params.updateValue(value, forKey: queryItem.name)
        }
      }
    }

    // Add fragment to params
    if let fragment = url.fragment {
      params.updateValue(fragment, forKey: "fragment")
    }

    return params
  }

}
