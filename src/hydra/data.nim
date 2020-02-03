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

    let padding = if frame.is_padded(): cast[int](stream.readUint8()) else: 0
    let data = stream.read_padded_data(cast[int](header.length), padding)
    if data.is_err():
        return Err(data.unwrap_error())

    frame.data = data.unwrap()

    return Ok(frame)


proc is_end_stream*(self: DataFrame): bool =
    return self.header.flags.bitand(DATA_END_STREAM) == DATA_END_STREAM

proc is_padded*(self: DataFrame): bool =
    return self.header.flags.bitand(DATA_PADDED) == DATA_PADDED
