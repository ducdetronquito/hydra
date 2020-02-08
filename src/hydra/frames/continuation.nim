import error_codes
import flags
import frame_header
import result
import streams
import utils


type
    ContinuationFrame* = object
        header*: Header
        header_block_fragment*: seq[byte]


template ends_headers*(self: ContinuationFrame): bool =
    self.header.flags.contains(END_HEADERS_FLAG)
  

proc read*(cls: type[ContinuationFrame], header: Header, stream: StringStream): Result[ContinuationFrame, ErrorCode] =
    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    let data = stream.read_bytes(int(header.length))
    if data.is_err():
        return Err(data.unwrap_error())

    let frame = ContinuationFrame(header: header, header_block_fragment: data.unwrap())
    return Ok(frame)


proc serialize*(self: ContinuationFrame): seq[byte] =
    result = self.header.serialize()
    result.add(self.header_block_fragment)

    return result
