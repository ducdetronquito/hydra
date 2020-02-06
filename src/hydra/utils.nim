import bitops
import bytes
import error_codes
import result
import stream
import streams

type
    Priority* = object
        exclusive*: bool
        stream_dependency*: StreamId
        weight*: byte


template has_highest_order_bit_activated*(value: uint32): bool =
    value.bitand(0x80000000'u32) == 0x80000000'u32


proc read*(cls: type[Priority], buffer: StringStream): Priority =
    let tmp = buffer.readUint32()
    return Priority(
        stream_dependency: StreamId.create(tmp),
        exclusive: tmp.has_highest_order_bit_activated(),
        weight: buffer.readUint8()
    )


proc serialize*(self: Priority): array[5, byte] =
    let stream_dependency = self.stream_dependency.bitor(0x80000000'u32).serialize()
    result[0] = stream_dependency[0]
    result[1] = stream_dependency[1]
    result[2] = stream_dependency[2]
    result[3] = stream_dependency[3]
    result[4] = self.weight
    return result


template can_read*(stream: StringStream, length: int): bool =
    stream.data.len() >= stream.getPosition() + length


proc read_bytes*(self: StringStream, length: int, padding: int = 0): Result[seq[byte], ErrorCode] =
    var payload_length = length - padding

    var data = newSeq[byte](payload_length)
    discard self.readData(addr(data[0]), payload_length)
    if padding != 0:
        self.setPosition(self.getPosition() + padding)

    return Ok(data)
