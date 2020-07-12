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
    return DotFileMaker(graph: self, options: options).makeDotFile()
  }
}

private final class EmptyFramework: DIFramework {
  static func load(container: DIContainer) { }
}

private final class DotFileMaker {

  private let graph: DIGraph
  private let options: GraphVizOptions

  init(graph: DIGraph, options: GraphVizOptions) {
    self.graph = graph
    self.options = options
  }

  func makeDotFile() -> Bool {
    // coupling info sorted by coupling: inLinks / outLinks.
    let frameworksCouplingInfo = FrameworkCouplingInfoMaker(graph: graph).make()
    let verticesCouplingInfo = VertexCouplingInfoMaker(graph: graph).make()

    return fillFile(options.filePath,
                    frameworksCouplingInfo: frameworksCouplingInfo,
                    verticesCouplingInfo: verticesCouplingInfo)
  }

  private func fillFile(_ file: URL,
                        frameworksCouplingInfo: [FrameworkCouplingInfo],
                        verticesCouplingInfo: [VertexCouplingInfo]) -> Bool {
    let verticesNameMap = makeVerticesName(frameworksCouplingInfo: frameworksCouplingInfo,
                                           verticesCouplingInfo: verticesCouplingInfo)

    var graphvizStr = ""

    graphvizStr += "digraph Dependencies {\n"

    let notEmptyFrameworks = frameworksCouplingInfo.filter { $0.framework != EmptyFramework.self }
    for (index, frameworkInfo) in notEmptyFrameworks.enumerated() {
      graphvizStr += "  subgraph cluster_\(index) {\n"
      defer { graphvizStr += "  }\n" }

      graphvizStr += "    style=filled;"
      graphvizStr += "    color=lightgoldenrodyellow;"
      graphvizStr += "    node [style=filled,color=white];\n"
      graphvizStr += "    label=\"" + makeFrameworkName(for: frameworkInfo) + "\";\n"

      graphvizStr += makeFrameworkVerticesStr(for: frameworkInfo,
                                              tab: "    ",
                                              verticesNameMap: verticesNameMap,
                                              verticesCouplingInfo: verticesCouplingInfo)
    }

    if let frameworkInfo = frameworksCouplingInfo.first(where: { $0.framework == EmptyFramework.self }) {
      graphvizStr += makeFrameworkVerticesStr(for: frameworkInfo,
                                              tab: "  ",
                                              verticesNameMap: verticesNameMap,
                                              verticesCouplingInfo: verticesCouplingInfo)
    }

    graphvizStr += makeEdgesStr(frameworksCouplingInfo: frameworksCouplingInfo,
                                verticesCouplingInfo: verticesCouplingInfo,
                                verticesNameMap: verticesNameMap)

    graphvizStr += "}"

    do {
      try graphvizStr.write(to: file, atomically: false, encoding: .ascii)
      print("Save dot file success on path: \(options.filePath)")
      return true
    } catch {
      assertionFailure("Can't write to file with error: \(error)")
      return false
    }
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
        assertionFailure("Can't find vertex name...")
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
          assertionFailure("Can't find vertex name...")
          continue
        }

        for (_, toIndices) in graph.adjacencyList[vertexInfo.vertexIndex] {
          for toIndex in toIndices {
            guard let toVertexName = verticesNameMap[toIndex] else {
              assertionFailure("Can't find vertex name...")
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
    func makeVertexName(for vertexIndex: Int, in frameworkName: String?) -> String {
      let vertex = graph.vertices[vertexIndex]

      var resultStr: String = frameworkName.flatMap { $0 + "_" } ?? ""
      switch vertex {
      case .component(let componentInfo):
        resultStr += "\(componentInfo.componentInfo.type)"
      case .unknown(let unknownInfo):
        assert(frameworkName == nil, "unknown types containts only in global namespace")
        resultStr += "\(unknownInfo.type)"
      case .argument:
        assertionFailure("argument not used for visualization dependency graph")
        return ""
      }

      return removeInvalidSymbols(resultStr)
    }

    var result: [Int: String] = [:]
    for frameworkInfo in frameworksCouplingInfo {
      var frameworkName: String?
      if frameworkInfo.framework != EmptyFramework.self {
        frameworkName = makeFrameworkName(for: frameworkInfo)
      }

      for vertexIndex in frameworkInfo.couplingInfo.vertices {
        let name = makeVertexName(for: vertexIndex, in: frameworkName)
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

  private func removeInvalidSymbols(_ string: String) -> String {
    var validSymbols = CharacterSet.alphanumerics
    validSymbols.insert(charactersIn: "_")

    return string.components(separatedBy: validSymbols.inverted)
      .joined()
  }

}

// MARK: - frameworks Coupling Info

fileprivate typealias FrameworkCouplingInfo = (framework: DIFramework.Type, couplingInfo: FrameworkCouplingInfoMaker.CouplingInfo)

private final class FrameworkCouplingInfoMaker {
  fileprivate struct FrameworkInfo: Hashable {
    private let id: ObjectIdentifier
    let value: DIFramework.Type

    init(value: DIFramework.Type) {
      self.id = ObjectIdentifier(value)
      self.value = value
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }

    static func ==(lhs: FrameworkInfo, rhs: FrameworkInfo) -> Bool {
      return lhs.id == rhs.id
    }
  }

  fileprivate class CouplingInfo {
    var inLinks: Set<FrameworkInfo> = []
    var outLinks: Set<FrameworkInfo> = []
    var vertices: Set<Int/*vertexIndex*/> = []

    var coupling: Double { return Double(inLinks.count + 1) / Double(outLinks.count + 1) }
  }

  private let graph: DIGraph

  init(graph: DIGraph) {
    self.graph = graph
  }

  func make() -> [FrameworkCouplingInfo] {
    let couplingInfo = makeDictionary()
    calculateInOut(couplingInfo)

    return sortDictionary(couplingInfo)
  }

  private func makeDictionary() -> [FrameworkInfo: CouplingInfo] {
    var couplingInfo: [FrameworkInfo: CouplingInfo] = [:]
    for (vertexIndex, vertex) in graph.vertices.enumerated() {
      guard let framework = makeFrameworkByVertex(vertex) else {
        continue
      }

      let frameworkInfo = couplingInfo[framework] ?? CouplingInfo()
      frameworkInfo.vertices.insert(vertexIndex)
      couplingInfo[framework] = frameworkInfo
    }

    return couplingInfo
  }

  private func calculateInOut(_ couplingInfo: [FrameworkInfo: CouplingInfo]) {
    for (fromIndex, fromVertex) in graph.vertices.enumerated() {
      guard let fromFramework = makeFrameworkByVertex(fromVertex) else {
        continue
      }

      for (_, toIndices) in graph.adjacencyList[fromIndex] {
        for toIndex in toIndices {
          guard let toFramework = makeFrameworkByVertex(graph.vertices[toIndex]) else {
            continue
          }

          if fromFramework != toFramework {
            couplingInfo[fromFramework]?.outLinks.insert(toFramework)
          }
        }
      }
    }
  }

  private func sortDictionary(_ couplingInfo: [FrameworkInfo: CouplingInfo]) -> [FrameworkCouplingInfo] {
    return couplingInfo.sorted(by: { (lhs, rhs) in
      return lhs.value.coupling < rhs.value.coupling
    }).map {
      return ($0.key.value, $0.value)
    }
  }

  private func makeFrameworkByVertex(_ vertex: DIVertex) -> FrameworkInfo? {
    switch vertex {
    case .component(let componentInfo):
      return FrameworkInfo(value: componentInfo.framework ?? EmptyFramework.self)
    case .unknown:
      return FrameworkInfo(value: EmptyFramework.self)
    case .argument:
      return nil
    }
  }
}

// MARK: - vertices Coupling Info

fileprivate typealias VertexCouplingInfo = (vertexIndex: Int, couplingInfo: VertexCouplingInfoMaker.CouplingInfo)

private final class VertexCouplingInfoMaker {
  fileprivate class CouplingInfo {
    var inLinks: Set<Int/*vertexIndex*/> = []
    var outLinks: Set<Int/*vertexIndex*/> = []
    var argLinks: [Int/*vertexIndex*/] = []

    var coupling: Double { return Double(inLinks.count + 1) / Double(outLinks.count + 1) }
  }

  private let graph: DIGraph

  init(graph: DIGraph) {
    self.graph = graph
  }

  func make() -> [VertexCouplingInfo] {
    let couplingInfo = makeDictionaryAndCalculateInOut()
    return sortDictionary(couplingInfo)
  }

  private func makeDictionaryAndCalculateInOut() -> [Int/*vertexIndex*/: CouplingInfo] {
    var couplingInfo: [Int/*vertexIndex*/: CouplingInfo] = [:]

    for fromIndex in graph.vertices.indices {
      for (_, toIndices) in graph.adjacencyList[fromIndex] {
        for toIndex in toIndices {
          let fromVertexInfo = couplingInfo[fromIndex] ?? CouplingInfo()
          let toVertexInfo = couplingInfo[toIndex] ?? CouplingInfo()

          switch graph.vertices[toIndex] {
          case .component, .unknown:
            fromVertexInfo.outLinks.insert(toIndex)
          case .argument:
            fromVertexInfo.argLinks.append(toIndex)
          }
          toVertexInfo.inLinks.insert(fromIndex)

          couplingInfo[fromIndex] = fromVertexInfo
          couplingInfo[toIndex] = toVertexInfo
        }
      }
    }

    return couplingInfo
  }

  private func sortDictionary(_ couplingInfo: [Int: CouplingInfo]) -> [VertexCouplingInfo] {
    return couplingInfo.sorted(by: { (lhs, rhs) in
      return lhs.value.coupling < rhs.value.coupling
    }).map {
      return ($0.key, $0.value)
    }
  }

}
