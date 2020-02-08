import bytes
import error_codes
import frame_header
import result
import streams


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
    result.add(self.window_size_increment.serialize())
    return result
