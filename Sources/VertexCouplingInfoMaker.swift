//
//  VertexCouplingInfoMaker.swift
//  DITranquillityGraphviz
//
//  Created by Ивлев А.Е. on 12.07.2020.
//  Copyright © 2020 sia. All rights reserved.
//

import DITranquillity

typealias VertexCouplingInfo = (vertexIndex: Int, couplingInfo: VertexCouplingInfoMaker.CouplingInfo)

final class VertexCouplingInfoMaker {
  class CouplingInfo {
    var inLinks: Set<Int/*vertexIndex*/> = []
    var outLinks: Set<Int/*vertexIndex*/> = []
    var argLinks: [Int/*vertexIndex*/] = []

    var coupling: Double { return Double(inLinks.count + 1) / Double(outLinks.count + 1) }
  }

  private let graph: DIGraph

  init(graph: DIGraph) {
    self.graph = graph
  }

  func make(ignoreOptional: Bool) -> [VertexCouplingInfo] {
    let couplingInfo = makeDictionaryAndCalculateInOut(ignoreOptional: ignoreOptional)
    return sortDictionary(couplingInfo)
  }

  private func makeDictionaryAndCalculateInOut(ignoreOptional: Bool) -> [Int/*vertexIndex*/: CouplingInfo] {
    var couplingInfo: [Int/*vertexIndex*/: CouplingInfo] = [:]

    for fromIndex in graph.vertices.indices {
      for (edge, toIndices) in graph.adjacencyList[fromIndex] {
        if ignoreOptional && edge.optional {
          continue
        }
        
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

