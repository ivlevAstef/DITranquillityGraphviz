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
    
    return false
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
    var vertices: [Int/*vertexIndex*/] = []
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
      frameworkInfo.vertices.append(vertexIndex)
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
      let lhsCoupling = (lhs.value.inLinks.count + 1) / (lhs.value.outLinks.count + 1)
      let rhsCoupling = (rhs.value.inLinks.count + 1) / (rhs.value.outLinks.count + 1)
      return lhsCoupling < rhsCoupling
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
      let lhsCoupling = (lhs.value.inLinks.count + 1) / (lhs.value.outLinks.count + 1)
      let rhsCoupling = (rhs.value.inLinks.count + 1) / (rhs.value.outLinks.count + 1)
      return lhsCoupling < rhsCoupling
    }).map {
      return ($0.key, $0.value)
    }
  }

}
