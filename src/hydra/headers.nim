import bytes
import error_codes
import flags
import frame_header
import options
import result
import streams
import utils


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


template is_padded*(self: HeadersFrame): bool =
    self.header.flags.contains(PADDED_FLAG)


template has_priority*(self: HeadersFrame): bool =
    self.header.flags.contains(PRIORITY_FLAG)


template ends_stream*(self: HeadersFrame): bool =
    self.header.flags.contains(END_STREAM_FLAG)


template ends_headers*(self: HeadersFrame): bool =
    self.header.flags.contains(END_HEADERS_FLAG)


proc read*(cls: type[HeadersFrame], header: Header, stream: StringStream): Result[HeadersFrame, ErrorCode] =
    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    var frame = HeadersFrame(header: header)

    var length = int(header.length)
    if frame.has_priority():
        frame.priority = some(Priority.read(stream))
        length -= 5

    var padding = 0
    if frame.is_padded():
        padding = int(stream.readUint8())
        length -= 1
        if padding >= length:
            return Err(ErrorCode.Protocol)

    let data = stream.read_bytes(length, padding)
    if data.is_err():
        return Err(data.unwrap_error())

    frame.header_block_fragment = data.unwrap()

    return Ok(frame)


proc serialize*(self: HeadersFrame): seq[byte] =
    result = self.header.serialize()

    let priority_length = if self.has_priority(): 5 else: 0
    let pad_length = int(self.header.length) - self.header_block_fragment.len() - priority_length

    if pad_length != 0:
        result.add(byte(pad_length))

    if priority_length != 0:
        result.add(self.priority.get().serialize())

    result.add(self.header_block_fragment)
    result.pad(pad_length)

    return result


export options
