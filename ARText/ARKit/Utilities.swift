/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility functions and type extensions used throughout the projects.
*/

import ARKit

// MARK: - float4x4 extensions

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
     将矩阵作为一个(右手坐标系)转换矩阵，并把转换的转换部分转化为因子。
    */
    var translation: float3 {
        let translation = columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
    /// Extracts the screen space point from a vector returned by SCNView.projectPoint(_:).
	init(_ vector: SCNVector3) {
		x = CGFloat(vector.x)
		y = CGFloat(vector.y)
	}

    /// 返回长度,平方开根号
    var length: CGFloat {
		return sqrt(x * x + y * y)
	}
}
extension UIColor{
    func hexString() -> String {
        let color = self
        let components = color.cgColor.components!
        let r: CGFloat = components[0]
        let g: CGFloat = components[1]
        let b: CGFloat = components[2]
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }
    convenience init(hexString color: String){
        let color = color.substring(from: color.index(color.endIndex, offsetBy: 1-color.count))
        let red = hexStringToInt(from: color.substring(with: color.index(color.startIndex, offsetBy: 0)..<color.index(color.endIndex, offsetBy: -4)))
        let green = hexStringToInt(from: color.substring(with: color.index(color.startIndex, offsetBy: 2)..<color.index(color.endIndex, offsetBy: -2)))
        let blue = hexStringToInt(from: color.substring(with: color.index(color.startIndex, offsetBy: 4)..<color.index(color.endIndex, offsetBy: 0)))
        
        self.init(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: 1.0)
    }

}
func hexStringToInt(from:String) -> Int {
    let str = from.uppercased()
    var sum = 0
    for i in str.utf8 {
        sum = sum * 16 + Int(i) - 48 // 0-9 从48开始
        if i >= 65 {                 // A-Z 从65开始，但有初始值10，所以应该是减去55
            sum -= 7
        }
    }
    return sum
}
