import base


const DATA_END_STREAM = 1'u8
const DATA_PADDED = 8'u8

type
    DataFrame* = object
        # Data frames convey arbitrary, variable-length sequences of
        # octets associated with a stream. One or more data frames are used,
        # for instance, to carry HTTP request or response payloads.
        #
        # Data frames may also contain a padding to obscure the size of messages,
        # which is considered a security feature.
        # Cf: https://tools.ietf.org/html/rfc7540#section-6.1
        # +-----------------+
        # | Pad Length? (8) |
        # +-----------------+---------------------------------------------+
        # |                           Data (*)                            |
        # +---------------------------------------------------------------+
        # |                           Padding (*)                         |
        # +---------------------------------------------------------------+
        header*: Header
        data*: seq[byte]


proc read*(cls: type[DataFrame], header: Header, stream: StringStream): Result[DataFrame, ErrorCode] =
    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    var frame = DataFrame(header: header)

    var length = cast[int](header.length)
    var padding = 0
    if frame.is_padded():
        padding = cast[int](stream.readUint8())
        length -= 1
        if padding >= length:
            return Err(ErrorCode.Protocol)

    let data = stream.read_bytes(length, padding)
    if data.is_err():
        return Err(data.unwrap_error())

    frame.data = data.unwrap()

    return Ok(frame)


proc is_end_stream*(self: DataFrame): bool =
    return self.header.flags.bitand(DATA_END_STREAM) == DATA_END_STREAM

proc is_padded*(self: DataFrame): bool =
    return self.header.flags.bitand(DATA_PADDED) == DATA_PADDED


proc serialize*(self: DataFrame): seq[byte] =
    result = self.header.serialize()

    let pad_length = cast[int](self.header.length) - self.data.len()
    if pad_length != 0:
        result.add(cast[uint8](pad_length))

    result.add(self.data)

    if pad_length != 0:
        result.pad(pad_length)

    return result
