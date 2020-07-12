//
//  DotFileMakerModeAny.swift
//  DITranquillityGraphviz
//
//  Created by Ивлев А.Е. on 12.07.2020.
//  Copyright © 2020 sia. All rights reserved.
//

import DITranquillity

final class DotFileMakerModeAny: DotFileMaker {

  private let graph: DIGraph
  private let options: GraphVizOptions

  init(graph: DIGraph, options: GraphVizOptions) {
    self.graph = graph
    self.options = options
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
    let verticesNameMap = makeVerticesName(frameworksCouplingInfo: frameworksCouplingInfo,
                                           verticesCouplingInfo: verticesCouplingInfo)

    var graphvizStr = ""

    graphvizStr += "digraph Dependencies {\n"
    graphvizStr += "  newrank=true;\n"

    let notEmptyFrameworks = frameworksCouplingInfo.filter { !$0.framework.isEmpty }

    if notEmptyFrameworks.isEmpty {
      graphvizStr += "  rankdir=TB;\n"
    } else {
      graphvizStr += "  rankdir=LR;\n"
    }

    for (index, frameworkInfo) in notEmptyFrameworks.enumerated() {
      graphvizStr += "  subgraph cluster_\(index) {\n"
      defer { graphvizStr += "  }\n" }

      graphvizStr += "    style=filled;\n"
      graphvizStr += "    color=lightgoldenrodyellow;\n"
      graphvizStr += "    node [style=filled,color=white];\n"
      graphvizStr += "    label=\"" + makeFrameworkName(for: frameworkInfo) + "\";\n"

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

      let typeName = makeTypeStr(for: graph.vertices[vertexInfo.vertexIndex])
      resultStr += tab + vertexName + " [label=\"\(typeName)\"];\n"
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

  private func makeFrameworkName(for frameworkInfo: FrameworkCouplingInfo) -> String {
    return removeInvalidSymbols("\(frameworkInfo.framework)")
  }

  private func makeVerticesName(frameworksCouplingInfo: [FrameworkCouplingInfo],
                                verticesCouplingInfo: [VertexCouplingInfo]) -> [Int: String] {
    func makeVertexName(for vertexIndex: Int, in frameworkName: String?) -> String? {
      let vertex = graph.vertices[vertexIndex]

      var resultStr: String = frameworkName.flatMap { $0 + "_" } ?? ""
      switch vertex {
      case .component(let componentInfo):
        resultStr += "\(componentInfo.componentInfo.type)"
      case .unknown(let unknownInfo):
        if options.ignoreUnknown {
          return nil
        }
        assert(frameworkName == nil, "unknown types containts only in global namespace")
        resultStr += "\(unknownInfo.type)"
      case .argument:
        assertionFailure("argument not used for visualization dependency graph")
        return nil
      }

      return removeInvalidSymbols(resultStr)
    }

    var result: [Int: String] = [:]
    for frameworkInfo in frameworksCouplingInfo {
      var frameworkName: String?
      if !frameworkInfo.framework.isEmpty {
        frameworkName = makeFrameworkName(for: frameworkInfo)
      }

      for vertexIndex in frameworkInfo.couplingInfo.vertices {
        guard let name = makeVertexName(for: vertexIndex, in: frameworkName) else {
          continue
        }
        assert(result[vertexIndex] == nil, "incorrect info - has dublicated vertexes in different frameworks")
        result[vertexIndex] = name
      }
    }

    return result
  }

  private func makeTypeStr(for vertex: DIVertex) -> String {
    switch vertex {
    case .component(let componentInfo):
      return "\(componentInfo.componentInfo.type)"
    case .argument(let argInfo):
      return "\(argInfo.type)"
    case .unknown(let unknownInfo):
      return "\(unknownInfo.type)"
    }
  }

}
