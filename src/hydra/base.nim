import bitops
import error_codes
import result
import streams


type
    StreamId* = uint32


proc create*(cls: type[StreamId], value: uint32): StreamId =
    return StreamId(value.bitand(0x7FFFFFFF))


proc read*(cls: type[StreamId], stream: StringStream): StreamId =
    return StreamId.create(stream.readUint32())


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

const CONNECTION_CONTROL_STREAM_ID = 0'u8


template can_read*(stream: StringStream, length: int): bool =
    stream.data.len() >= stream.getPosition() + length


proc has_payload_with_header_block(self: Header): bool =
    case self.frame_type:
    of FrameType.Headers, FrameType.Settings, FrameType.PushPromise, FrameType.Continuation:
        return true
    else:
        return false


template targets_connection_control_stream*(self: Header): bool =
    self.stream_id == CONNECTION_CONTROL_STREAM_ID


proc read*(cls: type[Header], stream: StringStream): Result[Header, ErrorCode] =
    if not stream.can_read(9):
        return Err(ErrorCode.FrameSize)

    let length =  cast[uint32](stream.readUint16()) + cast[uint32](stream.readUint8())
    let frame_type = FrameType(stream.readUint8())
    let flags = stream.readUint8()
    let stream_id = StreamId.read(stream)

    let header = Header(length: length, frame_type: frame_type, flags: flags, stream_id: stream_id)

    if stream.can_read(cast[int](length)):
        return Ok(header)

    if header.targets_connection_control_stream() or header.has_payload_with_header_block():
        return Err(ErrorCode.Protocol)
    else:
        return Err(ErrorCode.FrameSize)


proc serialize*(self: Header): seq[byte] =
    result = newSeq[byte](9)
    result[0] = cast[uint8](self.length shr 16)
    result[1] = cast[uint8](self.length shr 8)
    result[2] = cast[uint8](self.length)
    result[3] = cast[uint8](self.frame_type)
    result[4] = cast[uint8](self.flags)
    result[5] = cast[uint8](self.stream_id shr 24)
    result[6] = cast[uint8](self.stream_id shr 16)
    result[7] = cast[uint8](self.stream_id shr 8)
    result[8] = cast[uint8](self.stream_id)


type
    Priority* = object
        exclusive*: bool
        stream_dependency*: StreamId
        weight*: uint8


proc has_highest_order_bit_activated(value: uint32): bool =
    return value.bitand(2147483648'u32) == 2147483648'u32


proc read*(cls: type[Priority], buffer: StringStream): Priority =
    let tmp = buffer.readUint32()
    return Priority(
        stream_dependency: StreamId.create(tmp),
        exclusive: tmp.has_highest_order_bit_activated(),
        weight: buffer.readUint8()
    )


proc serialize*(self: Priority): array[5, byte] =
    let stream_dependency = self.stream_dependency.bitor(0x80000000'u32)
    result[0] = cast[uint8](stream_dependency shr 24)
    result[1] = cast[uint8](stream_dependency shr 16)
    result[2] = cast[uint8](stream_dependency shr 8)
    result[3] = cast[uint8](stream_dependency)
    result[4] = self.weight
    return result


proc read_bytes*(self: StringStream, length: int, padding: int = 0): Result[seq[byte], ErrorCode] =
    var payload_length = length - padding

    var data = newSeq[byte](payload_length)
    discard self.readData(addr(data[0]), payload_length)
    if padding != 0:
        self.setPosition(self.getPosition() + padding)

    return Ok(data)


proc pad*(self: var seq[byte], padding: int) =
    for i in 0..<padding:
        self.add(0'u8)


export bitops, error_codes, result, streams
