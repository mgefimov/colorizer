import Foundation
import CoreML
import Accelerate

@objc(Lambda) class Lambda: NSObject, MLCustomLayer {
    required init(parameters: [String : Any]) throws {
        print(#function, parameters)
        super.init()
    }
    
    func setWeightData(_ weights: [Data]) throws {
        print(#function, weights)
    }
    
    func outputShapes(forInputShapes inputShapes: [[NSNumber]]) throws
        -> [[NSNumber]] {
            print(#function, inputShapes)
            return inputShapes
    }
    
    
    func evaluate(inputs: [MLMultiArray], outputs: [MLMultiArray]) throws {
        for i in 0..<inputs.count {
            let input = inputs[i]
            let output = outputs[i]
            
            for j in 0..<input.count {
                let x = input[j].floatValue
                let y = (x + 1) * 127.5
                output[j] = NSNumber(value: y)
            }
        }
    }
}
