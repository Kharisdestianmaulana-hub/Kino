import Foundation

enum Corner { case topLeft, topRight, bottomRight, bottomLeft }
func offsetForScale(corner: Corner, width: Double, height: Double) -> (Double, Double) {
    let xSign: Double = (corner == .topLeft || corner == .bottomLeft) ? -1 : 1
    let ySign: Double = (corner == .topLeft || corner == .topRight) ? -1 : 1
    return (width/2 * xSign, height/2 * ySign)
}
func offsetForRotate(corner: Corner, width: Double, height: Double) -> (Double, Double) {
    let xSign: Double = (corner == .topLeft || corner == .bottomLeft) ? -1 : 1
    let ySign: Double = (corner == .topLeft || corner == .topRight) ? -1 : 1
    let inset: Double = -18
    return ((width/2 - inset) * xSign, (height/2 - inset) * ySign)
}
print(offsetForScale(corner: .topLeft, width: 100, height: 100))
print(offsetForRotate(corner: .topLeft, width: 100, height: 100))
