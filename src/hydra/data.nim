import bitops
import errors
import header
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


proc read*(cls: type[DataFrame], header: Header, stream: StringStream): Result[DataFrame, Error] =
    if header.targets_connection_control_stream():
        return Err(Error.ProtocolError)

    var data = newSeq[byte](header.length)
    discard stream.readData(addr(data[0]), cast[int](header.length))
    let frame = DataFrame(header: header, data: data)
    return Ok(frame)


proc is_end_stream*(self: DataFrame): bool =
    return self.header.flags.bitand(DATA_END_STREAM) == DATA_END_STREAM

proc is_padded*(self: DataFrame): bool =
    return self.header.flags.bitand(DATA_PADDED) == DATA_PADDED
