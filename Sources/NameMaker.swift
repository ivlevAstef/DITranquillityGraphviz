//
//  NameMaker.swift
//  DITranquillityGraphviz
//
//  Created by Ивлев А.Е. on 15.07.2020.
//  Copyright © 2020 sia. All rights reserved.
//

import Foundation
import DITranquillity

final class NameMaker {

  private let graph: DIGraph

  var frameworksCouplingInfo: [FrameworkCouplingInfo] = []
  var verticesCouplingInfo: [VertexCouplingInfo] = []

  init(graph: DIGraph) {
    self.graph = graph
  }

  func makeFrameworkName(for frameworkInfo: FrameworkCouplingInfo) -> String {
    return makeFrameworkName(for: frameworkInfo.framework)
  }

  func makeFrameworkName(for framework: FrameworkCouplingInfoMaker.FrameworkInfo) -> String {
    return removeInvalidSymbols("\(framework.value)")
  }

  func makeVerticesName(obfuscate: Bool = false) -> [Int: String] {
    func makeVertexName(for vertexIndex: Int, in frameworkName: String?) -> String? {
      if obfuscate {
        return "vertex_\(vertexIndex)"
      }
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

  static func makeTypeStr(for vertex: DIVertex) -> String {
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
