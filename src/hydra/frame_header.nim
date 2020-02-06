import error_codes
import flags
import result
import stream
import streams


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
        flags*: Flag

        # Stream ID: the stream identifier expressed as an unsigned 31-bit integer.
        # It is preceded by "R", a reserved 1-bit field.
        stream_id*: StreamId


template targets_connection_control_stream*(self: Header): bool =
    self.stream_id == CONNECTION_CONTROL_STREAM_ID


proc has_payload_with_header_block(self: Header): bool =
    case self.frame_type:
    of FrameType.Headers, FrameType.Settings, FrameType.PushPromise, FrameType.Continuation:
        return true
    else:
        return false


proc read*(cls: type[Header], stream: StringStream): Result[Header, ErrorCode] =
    if not stream.can_read(9):
        return Err(ErrorCode.FrameSize)

    let length =  uint32(stream.readUint16()) + uint32(stream.readUint8())
    let frame_type = FrameType(stream.readUint8())
    let flags = Flag(stream.readUint8())
    let stream_id = StreamId.read(stream)

    let header = Header(length: length, frame_type: frame_type, flags: flags, stream_id: stream_id)

    if stream.can_read(int(length)):
        return Ok(header)

    if header.targets_connection_control_stream() or header.has_payload_with_header_block():
        return Err(ErrorCode.Protocol)
    else:
        return Err(ErrorCode.FrameSize)


proc serialize*(self: Header): seq[byte] =
    result = newSeq[byte](9)
    result[0] = byte(self.length shr 16)
    result[1] = byte(self.length shr 8)
    result[2] = byte(self.length)
    result[3] = byte(self.frame_type)
    result[4] = byte(self.flags)
    result[5] = byte(self.stream_id shr 24)
    result[6] = byte(self.stream_id shr 16)
    result[7] = byte(self.stream_id shr 8)
    result[8] = byte(self.stream_id)
