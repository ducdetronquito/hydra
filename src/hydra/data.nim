import base
import bitops
import error_codes
import result
import streams


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
        # +-----------------------+
        # |Optional Pad Length (8)|
        # +-----------------------+---------------------------------------+
        # |                            Data (*)                           |
        # +---------------------------------------------------------------+
        # |                           Padding (*)                         |
        # +---------------------------------------------------------------+
        header*: Header
        data*: seq[byte]


proc read*(cls: type[DataFrame], header: Header, stream: StringStream): Result[DataFrame, ErrorCode] =
    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    var frame = DataFrame(header: header)

    let payload_length = cast[int](header.length)
    var pad_length = 0
    if frame.is_padded():
        pad_length = cast[int](stream.readUint8()) + 1
        if pad_length >= payload_length:
            return Err(ErrorCode.Protocol)

    let data_length = payload_length - pad_length
    var data = newSeq[byte](data_length)
    discard stream.readData(addr(data[0]), data_length)
    frame.data = data

    stream.setPosition(stream.getPosition() + pad_length)

    return Ok(frame)


proc is_end_stream*(self: DataFrame): bool =
    return self.header.flags.bitand(DATA_END_STREAM) == DATA_END_STREAM

proc is_padded*(self: DataFrame): bool =
    return self.header.flags.bitand(DATA_PADDED) == DATA_PADDED
