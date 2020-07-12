//
//  FrameworkCouplingInfoMaker.swift
//  DITranquillityGraphviz
//
//  Created by Ивлев А.Е. on 12.07.2020.
//

import DITranquillity

typealias FrameworkCouplingInfo = (framework: FrameworkCouplingInfoMaker.FrameworkInfo, couplingInfo: FrameworkCouplingInfoMaker.CouplingInfo)

final class FrameworkCouplingInfoMaker {
  struct FrameworkInfo: Hashable {
    private let id: ObjectIdentifier
    let value: DIFramework.Type
    let isEmpty: Bool

    init(value: DIFramework.Type) {
      self.id = ObjectIdentifier(value)
      self.value = value
      self.isEmpty = false
    }

    init(empty: Void) {
      self.id = ObjectIdentifier(EmptyFramework.self)
      self.value = EmptyFramework.self
      self.isEmpty = true
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }

    static func ==(lhs: FrameworkInfo, rhs: FrameworkInfo) -> Bool {
      return lhs.id == rhs.id
    }
  }

  class CouplingInfo {
    var inLinks: Set<FrameworkInfo> = []
    var outLinks: Set<FrameworkInfo> = []
    var vertices: Set<Int/*vertexIndex*/> = []

    var coupling: Double { return Double(inLinks.count + 1) / Double(outLinks.count + 1) }
  }

  private let graph: DIGraph

  init(graph: DIGraph) {
    self.graph = graph
  }

  func make(ignoreOptional: Bool) -> [FrameworkCouplingInfo] {
    let couplingInfo = makeDictionary()
    calculateInOut(ignoreOptional: ignoreOptional, couplingInfo: couplingInfo)

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

  private func calculateInOut(ignoreOptional: Bool, couplingInfo: [FrameworkInfo: CouplingInfo]) {
    for (fromIndex, fromVertex) in graph.vertices.enumerated() {
      guard let fromFramework = makeFrameworkByVertex(fromVertex) else {
        continue
      }

      for (edge, toIndices) in graph.adjacencyList[fromIndex] {
        if ignoreOptional && edge.optional {
          continue
        }
        
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
      return ($0.key, $0.value)
    }
  }

  private func makeFrameworkByVertex(_ vertex: DIVertex) -> FrameworkInfo? {
    switch vertex {
    case .component(let componentInfo):
      return componentInfo.framework.flatMap { FrameworkInfo(value: $0) } ?? FrameworkInfo(empty: ())
    case .unknown:
      return FrameworkInfo(empty: ())
    case .argument:
      return nil
    }
  }
}

private final class EmptyFramework: DIFramework {
  static func load(container: DIContainer) { }
}
