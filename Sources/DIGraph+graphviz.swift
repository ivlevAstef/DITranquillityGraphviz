//
//  DIGraph+graphviz.swift
//  DITranquillityGraphviz
//
//  Created by Ивлев А.Е. on 10.07.2020.
//  Copyright © 2020 sia. All rights reserved.
//

import Foundation
import DITranquillity

extension DIGraph {
  public func makeDotFile(_ options: GraphVizOptions = GraphVizOptions.default) -> Bool {
    let fileMaker: DotFileMaker
    switch options.mode {
    case .onlyGraph(let obfuscate):
        fileMaker = DotFileMakerModeOnlyGraph(graph: self, options: options, obfuscate: obfuscate)
    case .any:
      fileMaker = DotFileMakerModeAny(graph: self, options: options)
    case .frameworks:
      fileMaker = DotFileMakerModeFrameworks(graph: self, options: options)
    case .framework(let framework):
      fatalError()
    }

    return fileMaker.makeDotFile(file: options.filePath)
  }
}

protocol DotFileMaker: AnyObject {
  func makeDotString() -> String
}

extension DotFileMaker {
  func makeDotFile(file: URL) -> Bool {
    do {
      try makeDotString().write(to: file, atomically: false, encoding: .ascii)
      print("Save dot file success on path: \(file)")
      return true
    } catch {
      assertionFailure("Can't write to file with error: \(error)")
      return false
    }
  }
}
