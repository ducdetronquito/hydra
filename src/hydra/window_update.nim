import base


type
    WindowUpdateFrame* = object
        # Implements flow control for Data frames.
        #
        # Cf: https://tools.ietf.org/html/rfc7540#section-6.9
        # +-+-------------------------------------------------------------+
        # |R|              Window Size Increment (31)                     |
        # +-+-------------------------------------------------------------+
        header*: Header
        # Number of octets that the sender can transmit in addition to the existing flow-control window.
        window_size_increment*: uint32


proc read*(cls: type[WindowUpdateFrame], header: Header, stream: StringStream): Result[WindowUpdateFrame, ErrorCode] =
    if header.length != 4'u32:
        return Err(ErrorCode.FrameSize)

    let window_size_increment = stream.readUint32()
    if window_size_increment == 0'u32:
        return Err(ErrorCode.Protocol)

    return Ok(WindowUpdateFrame(header: header, window_size_increment: window_size_increment))


proc serialize*(self: WindowUpdateFrame): seq[byte] =
    result = self.header.serialize()
    let window_size_increment = cast[uint32](self.window_size_increment)
    result.add(cast[uint8](window_size_increment shr 24'u32))
    result.add(cast[uint8](window_size_increment shr 16'u32))
    result.add(cast[uint8](window_size_increment shr 8))
    result.add(cast[uint8](window_size_increment))

    return result
