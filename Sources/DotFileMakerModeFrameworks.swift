//
//  DotFileMakerModeFrameworks.swift
//  DITranquillityGraphviz
//
//  Created by Ивлев А.Е. on 12.07.2020.
//  Copyright © 2020 sia. All rights reserved.
//

import DITranquillity

final class DotFileMakerModeFrameworks: DotFileMaker {

  private let graph: DIGraph
  private let options: GraphVizOptions

  init(graph: DIGraph, options: GraphVizOptions) {
    self.graph = graph
    self.options = options
  }

  func makeDotString() -> String {
    // coupling info sorted by coupling: inLinks / outLinks.
    let frameworksCouplingInfo = FrameworkCouplingInfoMaker(graph: graph).make(ignoreOptional: options.ignoreOptional)

    return makeDotString(frameworksCouplingInfo: frameworksCouplingInfo)
  }

  private func makeDotString(frameworksCouplingInfo: [FrameworkCouplingInfo]) -> String {
    var graphvizStr = ""

    graphvizStr += "digraph Dependencies {\n"
    graphvizStr += "  newrank=true;\n"
    graphvizStr += "  rankdir=TB;\n"

    graphvizStr += "  node [style=filled,color=lightgoldenrodyellow,shape=box];\n"

    let notEmptyFrameworks = frameworksCouplingInfo.filter { !$0.framework.isEmpty }
    for frameworkInfo in notEmptyFrameworks {
      graphvizStr += "  \(makeFrameworkName(for: frameworkInfo.framework));\n"
    }

    for fromFrameworkInfo in notEmptyFrameworks {
      let fromFrameworkName = makeFrameworkName(for: fromFrameworkInfo.framework)
      for toFramework in fromFrameworkInfo.couplingInfo.outLinks where !toFramework.isEmpty {
        let toFrameworkName = makeFrameworkName(for: toFramework)

        graphvizStr += "  \(fromFrameworkName) -> \(toFrameworkName);\n"
      }
      graphvizStr += "\n"
    }

    graphvizStr += "}"

    return graphvizStr
  }

  private func makeFrameworkName(for frameworkInfo: FrameworkCouplingInfoMaker.FrameworkInfo) -> String {
    return removeInvalidSymbols("\(frameworkInfo.value)")
  }

}

