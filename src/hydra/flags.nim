import bitops


type
    Flag* = uint8


template contains*(self: Flag, other: Flag): bool =
    self.bitand(other) == other


const NO_FLAG* = Flag(0)
const END_STREAM_FLAG* = Flag(1)
const ACK_FLAG* = Flag(1)
const END_HEADERS_FLAG* = Flag(4)
const PADDED_FLAG* = Flag(8)
const PRIORITY_FLAG* = Flag(32)


export bitops
