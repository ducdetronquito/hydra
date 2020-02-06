import bitops
import streams


type
    StreamId* = uint32


const CONNECTION_CONTROL_STREAM_ID* = StreamID(0)


proc create*(cls: type[StreamId], value: uint32): StreamId =
    return StreamId(value.bitand(0x7FFFFFFF))


proc read*(cls: type[StreamId], stream: StringStream): StreamId =
    return StreamId.create(stream.readUint32())
