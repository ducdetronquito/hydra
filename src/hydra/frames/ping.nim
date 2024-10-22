import bytes
import error_codes
import flags
import frame_header
import result
import streams


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


template is_ack*(self: PingFrame): bool =
    self.header.flags.contains(ACK_FLAG)


proc read*(cls: type[PingFrame], header: Header, stream: StringStream): Result[PingFrame, ErrorCode] =
    if header.length != 8'u32:
        return Err(ErrorCode.FrameSize)

    if not header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    let frame = PingFrame(header: header, opaque_data: stream.readUint64())
    return Ok(frame)


proc serialize*(self: PingFrame): seq[byte] =
    result = self.header.serialize()
    result.add(self.opaque_data.serialize())
    return result
