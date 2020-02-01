import bitops
import streams

const CONNECTION_CONTROL_STREAM_ID = 0'u8

type
    FrameType* {.pure.} = enum
        Data = 0'u8
        Headers = 1'u8
        Priority = 2'u8
        RstStream = 3'u8
        Settings = 4'u8
        PushPromise = 5'u8
        Ping = 6'u8
        GoAway = 7'u8
        WindowUpdate = 8'u8
        Continuation = 9'u8

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
        frame_type*: FrameType

        # Flags: an 8-bit field reserved for boolean flags specific to the frame type.
        flags*: byte

        # Stream ID: the stream identifier expressed as an unsigned 31-bit integer.
        # It is preceded by "R", a reserved 1-bit field.
        stream_id*: uint32


proc read*(cls: type[Header], buffer: StringStream): Header =
    let length =  cast[uint32](buffer.readUint16()) + cast[uint32](buffer.readUint8())
    return Header(
        length: length,
        frame_type: FrameType(buffer.readUint8()),
        flags: buffer.readUint8(),
        stream_id: buffer.readUInt32().bitand(0x7FFFFFFF)
    )


template targets_connection_control_stream*(self: Header): bool =
    self.stream_id == CONNECTION_CONTROL_STREAM_ID


type
    Priority* = object
        exclusive*: bool
        stream_dependency*: uint32
        weight*: uint8


proc has_highest_order_bit_activated(value: uint32): bool =
    return value.bitand(2147483648'u32) == 2147483648'u32


proc read*(cls: type[Priority], buffer: StringStream): Priority =
    let tmp = buffer.readUint32()
    return Priority(
        stream_dependency: tmp.bitand(0x7FFFFFFF),
        exclusive: tmp.has_highest_order_bit_activated(),
        weight: buffer.readUint8()
    )
