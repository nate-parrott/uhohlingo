import GameplayKit

class SeededGenerator: RandomNumberGenerator {
    let seed: UInt64
    private let generator: GKMersenneTwisterRandomSource
    convenience init() {
        self.init(seed: 0)
    }
    convenience init(string: String) {
        self.init(seed: UInt64(bitPattern: Int64(string.djb2hash)))
    }
    init(seed: UInt64) {
        self.seed = seed
        generator = GKMersenneTwisterRandomSource(seed: seed)
    }
    func next() -> UInt64 {
        // From https://stackoverflow.com/questions/54821659/swift-4-2-seeding-a-random-number-generator
        // GKRandom produces values in [INT32_MIN, INT32_MAX] range; hence we need two numbers to produce 64-bit value.
        let next1 = UInt64(bitPattern: Int64(generator.nextInt()))
        let next2 = UInt64(bitPattern: Int64(generator.nextInt()))
        return next1 ^ (next2 << 32)
    }
}

extension RandomNumberGenerator {
    mutating func nextRandFloat0_1() -> Double {
        let base: UInt64 = 32768
        let x = next() % base
        return Double(x) / Double(base)
    }

    mutating func nextRandFloat1_Neg1() -> Double {
        nextRandFloat0_1() * 2 - 1
    }
}

extension String {
    // hash(0) = 5381
    // hash(i) = hash(i - 1) * 33 ^ str[i];
    var djb2hash: Int {
        let unicodeScalars = self.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }

    // hash(0) = 0
    // hash(i) = hash(i - 1) * 65599 + str[i];
    var sdbmhash: Int {
        let unicodeScalars = self.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(0) {
            Int($1) &+ ($0 << 6) &+ ($0 << 16) - $0
        }
    }
}
