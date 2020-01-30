import errors
import header
import result
import streams


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
        data*: seq[uint8]


proc read*(cls: type[DataFrame], header: Header, stream: StringStream): Result[DataFrame, Error] =
    if header.targets_connection_control_stream():
        return Err(Error.ProtocolError)

    var data = newSeq[uint8](header.length)
    discard stream.readData(addr(data[0]), cast[int](header.length))
    let frame = DataFrame(header: header, data: data)
    return Ok(frame)
