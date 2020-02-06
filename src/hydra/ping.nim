import base


const PING_ACK = 1'u8


type
    PingFrame* = object
        # The PING frame is a mechanism for measuring a minimal round-trip time from the sender,
        # as well as determining whether an idle connection is still functional.
        #
        # Cf: https://httpwg.org/specs/rfc7540.html#rfc.section.6.7
        #  +---------------------------------------------------------------+
        #  |                                                               |
        #  |                      Opaque Data (64)                         |
        #  |                                                               |
        #  +---------------------------------------------------------------+
        header*: Header
        opaque_data*: uint64


proc read*(cls: type[PingFrame], header: Header, stream: StringStream): Result[PingFrame, ErrorCode] =
    if header.length != 8'u32:
        return Err(ErrorCode.FrameSize)

    if not header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    let frame = PingFrame(header: header, opaque_data: stream.readUint64())
    return Ok(frame)

proc serialize*(self: PingFrame): seq[byte] =
    result = self.header.serialize()
    result.add(cast[uint8](self.opaque_data shr 56))
    result.add(cast[uint8](self.opaque_data shr 48))
    result.add(cast[uint8](self.opaque_data shr 40))
    result.add(cast[uint8](self.opaque_data shr 32))
    result.add(cast[uint8](self.opaque_data shr 24))
    result.add(cast[uint8](self.opaque_data shr 16))
    result.add(cast[uint8](self.opaque_data shr 8))
    result.add(cast[uint8](self.opaque_data))

    return result


proc is_ack*(self: PingFrame): bool =
    return self.header.flags.bitand(PING_ACK) == PING_ACK
