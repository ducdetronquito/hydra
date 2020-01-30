import bitops
import errors
import header
import result
import streams


const PING_ACK = 1'u8


type
    PingFrame* = object
        # The PING frame is a mechanism for measuring a minimal round-trip time from the sender,
        # as well as determining whether an idle connection is still functional.
        # Cf: https://httpwg.org/specs/rfc7540.html#rfc.section.6.7
        #  +---------------------------------------------------------------+
        #  |                                                               |
        #  |                      Opaque Data (64)                         |
        #  |                                                               |
        #  +---------------------------------------------------------------+
        header*: Header
        opaque_data*: uint64


proc read*(cls: type[PingFrame], header: Header, stream: StringStream): Result[PingFrame, Error] =
    if not header.targets_connection_control_stream():
        return Err(Error.ProtocolError)

    if header.length != 8'u32:
        return Err(Error.FrameSizeError)

    let frame = PingFrame(header: header, opaque_data: stream.readUint64())
    return Ok(frame)


proc is_ack*(self: PingFrame): bool =
    return self.header.flags.bitand(PING_ACK) == PING_ACK
