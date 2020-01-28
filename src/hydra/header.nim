import bitops
import streams

type
    Header* = object
        # All frames begin with a fixed 9-octet header
        # +-----------------------------------------------+
        # |                 Length (24)                   |
        # +---------------+---------------+---------------+
        # |   Type (8)    |   Flags (8)   |
        # +-+-------------+---------------+-------------------------------+
        # |R|                 Stream Identifier (31)                      |
        # +-+-------------------------------------------------------------+
        #
        # Cf: Frame header format: https://tools.ietf.org/html/rfc7540#section-4.1

        # Length: the length of the frame payload expressed as an unsigned 24-bit integer
        # The 9 octets of the frame header are not included in this value.
        length* : uint32

        # Type: the 8-bit type of the frame.
        frame_type*: char

        # Flags: an 8-bit field reserved for boolean flags specific to the frame type.
        flags*: char

        # Stream ID: the stream identifier expressed as an unsigned 31-bit integer.
        # It is preceded by "R", a reserved 1-bit field.
        stream_id*: uint32


proc read*(cls: type[Header], buffer: StringStream): Header =
    let length = cast[uint32](buffer.readUint16()) + cast[uint32](buffer.readChar())
    return Header(
        length: length,
        frame_type: buffer.readChar(),
        flags: buffer.readChar(),
        stream_id: buffer.readUInt32().bitand(0x7FFFFFFF)
    )
