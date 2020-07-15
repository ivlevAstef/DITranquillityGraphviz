//
//  DotFileMakerModeFrameworks.swift
//  DITranquillityGraphviz
//
//  Created by Ивлев А.Е. on 12.07.2020.
//  Copyright © 2020 sia. All rights reserved.
//

import DITranquillity

private struct FrameworkLink: Hashable {
  let one: FrameworkCouplingInfoMaker.FrameworkInfo
  let two: FrameworkCouplingInfoMaker.FrameworkInfo

  func hash(into hasher: inout Hasher) {
    hasher.combine(one)
    hasher.combine(two)
  }

  static func ==(lhs: FrameworkLink, rhs: FrameworkLink) -> Bool {
    return (lhs.one == rhs.one && lhs.two == rhs.two) ||
           (lhs.one == rhs.two && lhs.two == rhs.one)
  }
}

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
    let nameMaker = NameMaker(graph: graph)
    nameMaker.frameworksCouplingInfo = frameworksCouplingInfo

    var graphvizStr = ""

    graphvizStr += "digraph Dependencies {\n"
    graphvizStr += "  concentrate=true;\n" // for auto two side edges
    graphvizStr += "  newrank=true;\n"
    graphvizStr += "  rankdir=TB;\n"
    graphvizStr += "  graph [splines=ortho, nodesep=1];\n"

    graphvizStr += "  node [style=filled,color=lightgoldenrodyellow,shape=box];\n"

    let notEmptyFrameworks = frameworksCouplingInfo.filter { !$0.framework.isEmpty }
    for frameworkInfo in notEmptyFrameworks {
      graphvizStr += "  \(nameMaker.makeFrameworkName(for: frameworkInfo));\n"
    }

    for fromFrameworkInfo in notEmptyFrameworks {
      let fromFrameworkName = nameMaker.makeFrameworkName(for: fromFrameworkInfo)
      for toFramework in fromFrameworkInfo.couplingInfo.outLinks where !toFramework.isEmpty {
        let toFrameworkName = nameMaker.makeFrameworkName(for: toFramework)

        graphvizStr += "  \(fromFrameworkName) -> \(toFrameworkName);\n"
      }
      graphvizStr += "\n"
    }

    graphvizStr += "}"

    return graphvizStr
  }

}

