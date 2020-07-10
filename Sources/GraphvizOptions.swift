//
//  GraphvizOptions.swift
//  DITranquillityGraphviz
//
//  Created by Ивлев А.Е. on 10.07.2020.
//  Copyright © 2020 sia. All rights reserved.
//

import Foundation

public struct GraphVizOptions {
  public static let `default` = GraphVizOptions(
    filePath: defaultURLPath(fileName: "dependency_graph.dot")
  )

  public var filePath: URL
}

#if os(iOS)
private func defaultURLPath(fileName: String) -> URL {
  return urlPath(to: .documentDirectory, fileName: fileName)
}

#else
private func defaultURLPath(fileName: String) -> URL {
  return urlPath(to: .downloadsDirectory, fileName: fileName)
}

#endif

private func urlPath(to directory: FileManager.SearchPathDirectory, fileName: String) -> URL {
  guard let documentsPath = NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true).first else {
    fatalError("Can't make path to directory")
  }

  guard let url = URL(string: documentsPath) else {
    fatalError("Can't make path to directory")
  }

  return url.appendingPathComponent(fileName, isDirectory: false)
}
