import base


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


const END_HEADERS = 4'u8
const PADDED = 8'u8


proc is_padded*(self: PushPromiseFrame): bool =
    return self.header.flags.bitand(PADDED) == PADDED


proc is_end_headers*(self: PushPromiseFrame): bool =
    return self.header.flags.bitand(END_HEADERS) == END_HEADERS


proc read*(cls: type[PushPromiseFrame], header: Header, stream: StringStream): Result[PushPromiseFrame, ErrorCode] =
    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    var frame = PushPromiseFrame(header: header)

    var length = cast[int](header.length)
    var padding = 0
    if frame.is_padded():
        padding = cast[int](stream.readUint8())
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
