import base
import bitops
import error_codes
import options
import result
import streams


type
    HeadersFrame* = object
        # Frame used to open a stream and additionally carry a header block fragment.
        #
        # Cf: https://tools.ietf.org/html/rfc7540#section-6.2
        # +---------------+
        # |Pad Length? (8)|
        # +-+-------------+-----------------------------------------------+
        # |E|                 Stream Dependency? (31)                     |
        # +-+-------------+-----------------------------------------------+
        # |  Weight? (8)  |
        # +-+-------------+-----------------------------------------------+
        # |                   Header Block Fragment (*)                   |
        # +---------------------------------------------------------------+
        # |                           Padding (*)                         |
        # +---------------------------------------------------------------+
        header*: Header
        header_block_fragment*: seq[byte]
        priority*: Option[Priority]


proc read*(cls: type[HeadersFrame], header: Header, stream: StringStream): Result[HeadersFrame, ErrorCode] =
    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    var frame = HeadersFrame(header: header)

    var priority_length = 0
    if frame.has_priority():
        frame.priority = some(Priority.read(stream))
        priority_length = 5

    let payload_length = cast[int](header.length)
    var pad_length = 0
    if frame.is_padded():
        pad_length = cast[int](stream.readUint8()) + 1
        if pad_length >= payload_length:
            return Err(ErrorCode.Protocol)

    let data_length = payload_length - pad_length - priority_length
    var data = newSeq[byte](data_length)
    discard stream.readData(addr(data[0]), data_length)
    frame.header_block_fragment = data

    stream.setPosition(stream.getPosition() + pad_length)

    return Ok(frame)


const END_STREAM = 1'u8
const END_HEADERS = 4'u8
const PADDED = 8'u8
const PRIORITY = 32'u8


proc is_padded*(self: HeadersFrame): bool =
    return self.header.flags.bitand(PADDED) == PADDED


proc has_priority*(self: HeadersFrame): bool =
    return self.header.flags.bitand(PRIORITY) == PRIORITY


proc is_end_stream*(self: HeadersFrame): bool =
    return self.header.flags.bitand(END_STREAM) == END_STREAM


proc is_end_headers*(self: HeadersFrame): bool =
    return self.header.flags.bitand(END_HEADERS) == END_HEADERS
