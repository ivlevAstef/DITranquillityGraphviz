//
//  DotFileMakerModeOnlyGraph.swift
//  DITranquillityGraphviz
//
//  Created by Ивлев А.Е. on 12.07.2020.
//  Copyright © 2020 sia. All rights reserved.
//

import DITranquillity

final class DotFileMakerModeOnlyGraph: DotFileMaker {

  private let graph: DIGraph
  private let options: GraphVizOptions
  private let obfuscate: Bool

  init(graph: DIGraph, options: GraphVizOptions, obfuscate: Bool) {
    self.graph = graph
    self.options = options
    self.obfuscate = obfuscate
  }

  func makeDotString() -> String {
    // coupling info sorted by coupling: inLinks / outLinks.
    let frameworksCouplingInfo = FrameworkCouplingInfoMaker(graph: graph).make(ignoreOptional: options.ignoreOptional)
    let verticesCouplingInfo = VertexCouplingInfoMaker(graph: graph).make(ignoreOptional: options.ignoreOptional)

    return makeDotString(frameworksCouplingInfo: frameworksCouplingInfo,
                         verticesCouplingInfo: verticesCouplingInfo)
  }

  private func makeDotString(frameworksCouplingInfo: [FrameworkCouplingInfo],
                             verticesCouplingInfo: [VertexCouplingInfo]) -> String {
    let nameMaker = NameMaker(graph: graph)
    nameMaker.frameworksCouplingInfo = frameworksCouplingInfo
    nameMaker.verticesCouplingInfo = verticesCouplingInfo

    let verticesNameMap = nameMaker.makeVerticesName(obfuscate: obfuscate)

    var graphvizStr = ""

    graphvizStr += "digraph Dependencies {\n"

    let notEmptyFrameworks = frameworksCouplingInfo.filter { !$0.framework.isEmpty }

    for (index, frameworkInfo) in notEmptyFrameworks.enumerated() {
      graphvizStr += "  subgraph cluster_\(index) {\n"
      defer { graphvizStr += "  }\n" }

      if !obfuscate {
        graphvizStr += "    label=\"" + nameMaker.makeFrameworkName(for: frameworkInfo) + "\";\n"
      }
      
      graphvizStr += makeFrameworkVerticesStr(for: frameworkInfo,
                                              tab: "    ",
                                              verticesNameMap: verticesNameMap,
                                              verticesCouplingInfo: verticesCouplingInfo)
    }

    if let frameworkInfo = frameworksCouplingInfo.first(where: { $0.framework.isEmpty }) {
      graphvizStr += makeFrameworkVerticesStr(for: frameworkInfo,
                                              tab: "  ",
                                              verticesNameMap: verticesNameMap,
                                              verticesCouplingInfo: verticesCouplingInfo)
    }

    graphvizStr += makeEdgesStr(frameworksCouplingInfo: frameworksCouplingInfo,
                                verticesCouplingInfo: verticesCouplingInfo,
                                verticesNameMap: verticesNameMap)

    graphvizStr += "}"

    return graphvizStr
  }

  private func makeFrameworkVerticesStr(for frameworkInfo: FrameworkCouplingInfo,
                                        tab: String,
                                        verticesNameMap: [Int: String],
                                        verticesCouplingInfo: [VertexCouplingInfo]) -> String {
    let vertexInfos = verticesCouplingInfo
      .filter { frameworkInfo.couplingInfo.vertices.contains($0.vertexIndex) }

    var resultStr: String = ""
    for vertexInfo in vertexInfos {
      guard let vertexName = verticesNameMap[vertexInfo.vertexIndex] else {
        continue
      }

      resultStr += tab + vertexName + ";\n"
    }

    return resultStr
  }

  private func makeEdgesStr(frameworksCouplingInfo: [FrameworkCouplingInfo],
                            verticesCouplingInfo: [VertexCouplingInfo],
                            verticesNameMap: [Int: String]) -> String {
    var resultStr = ""

    for frameworkInfo in frameworksCouplingInfo {
      let vertexInfos = verticesCouplingInfo
        .filter { frameworkInfo.couplingInfo.vertices.contains($0.vertexIndex) }

      for vertexInfo in vertexInfos {
        guard let fromVertexName = verticesNameMap[vertexInfo.vertexIndex] else {
          continue
        }

        for (_, toIndices) in graph.adjacencyList[vertexInfo.vertexIndex] {
          for toIndex in toIndices {
            guard let toVertexName = verticesNameMap[toIndex] else {
              continue
            }

            resultStr += "  \(fromVertexName) -> \(toVertexName);\n"
          }
        }
      }

      resultStr += "\n"
    }

    return resultStr
  }
}
