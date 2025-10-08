import CoreGraphics
//
//  Gate.swift
//  LogicGateGame
//
//  Created by Graden on 10/7/25.
//

enum GateType { case and, or, not, xor, nand, nor, xnor }

class LogicGate {
    var position: CGPoint
    var inputA: LogicGate?     // Made optional to allow source gates
    var inputB: LogicGate?
    let type: GateType
    var size: CGSize

    init(position: CGPoint, type: GateType, inputA: LogicGate?, inputB: LogicGate? = nil, size: CGSize = CGSize(width: 50, height: 50)) {
        self.position = position
        self.type = type
        self.inputA = inputA
        self.inputB = inputB
        self.size = size
    }

    // Compute this gate's output based on its type and inputs
    func run() -> Bool {
        let a = inputA?.run() ?? false
        let b = inputB?.run() ?? false
        switch type {
        case .and: return a && b
        case .or: return a || b
        case .not: return !a
        case .xor: return a != b
        case .nand: return !(a && b)
        case .nor: return !(a || b)
        case .xnor: return a == b
        }
    }
}
