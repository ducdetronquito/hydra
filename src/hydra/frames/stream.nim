import bitops
import bytes
import streams


type
    StreamId* = distinct uint32


const CONNECTION_CONTROL_STREAM_ID* = StreamID(0)


proc `==`*(self: StreamId, other: StreamId): bool =
    return uint32(self) == uint32(other)


proc create*(cls: type[StreamId], value: uint32): StreamId =
    return StreamId(value.bitand(0x7FFFFFFF))


proc read*(cls: type[StreamId], stream: StringStream): StreamId =
    return StreamId.create(stream.readUint32())


proc serialize*(self: StreamId): array[4, byte] =
    return serialize(uint32(self).bitand(0x7fffffff'u32))
