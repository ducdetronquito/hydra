import error_codes
import flags
import frame_header
import result
import stream
import streams
import utils


type
    PushPromiseFrame* = object
        # Notifies the peer endpoint in advance of streams the sender intends to initiate.
        #
        # Cf: https://tools.ietf.org/html/rfc7540#section-6.6
        # +---------------+
        # |Pad Length? (8)|
        # +-+-------------+-----------------------------------------------+
        # |R|                  Promised Stream ID (31)                    |
        # +-+-----------------------------+-------------------------------+
        # |                   Header Block Fragment (*)                   |
        # +---------------------------------------------------------------+
        # |                           Padding (*)                         |
        # +---------------------------------------------------------------+
        header*: Header
        promised_stream_id*: StreamId
        header_block_fragment*: seq[byte]


template is_padded*(self: PushPromiseFrame): bool =
    self.header.flags.contains(PADDED_FLAG)


template ends_headers*(self: PushPromiseFrame): bool =
    self.header.flags.contains(END_HEADERS_FLAG)


proc read*(cls: type[PushPromiseFrame], header: Header, stream: StringStream): Result[PushPromiseFrame, ErrorCode] =
    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    var frame = PushPromiseFrame(header: header)

    var length = int(header.length)
    var padding = 0
    if frame.is_padded():
        padding = int(stream.readUint8())
        length -= 1
        if padding >= length:
            return Err(ErrorCode.Protocol)

    frame.promised_stream_id = StreamId.read(stream)
    length -= 4

    let data = stream.read_bytes(length, padding)
    if data.is_err():
        return Err(data.unwrap_error())

    frame.header_block_fragment = data.unwrap()

    return Ok(frame)
