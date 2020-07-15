//
//  GraphvizOptions.swift
//  DITranquillityGraphviz
//
//  Created by Ивлев А.Е. on 10.07.2020.
//  Copyright © 2020 sia. All rights reserved.
//

import DITranquillity

public struct GraphVizOptions {
  public static let `default` = GraphVizOptions(
    filePath: defaultURLPath(fileName: "dependency_graph.dot"),
    mode: .any,
    ignoreUnknown: true,
    ignoreOptional: false
  )

  public enum Mode {
    case any
    case onlyGraph(obfuscate: Bool)
    case framework(_ framework: DIFramework.Type)
    case frameworks
  }

  public var filePath: URL
  public var mode: Mode
  public var ignoreUnknown: Bool
  public var ignoreOptional: Bool
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

  let url = URL(fileURLWithPath: documentsPath, isDirectory: true)
  return url.appendingPathComponent(fileName, isDirectory: false)
}
