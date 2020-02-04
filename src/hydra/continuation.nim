import base


type
    ContinuationFrame* = object
        header*: Header
        header_block_fragment*: seq[byte]


proc read*(cls: type[ContinuationFrame], header: Header, stream: StringStream): Result[ContinuationFrame, ErrorCode] =
    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    let data = stream.read_bytes(cast[int](header.length))
    if data.is_err():
        return Err(data.unwrap_error())

    let frame = ContinuationFrame(header: header, header_block_fragment: data.unwrap())
    return Ok(frame)


const END_HEADERS = 4'u8


proc is_end_headers*(self: ContinuationFrame): bool =
    return self.header.flags.bitand(END_HEADERS) == END_HEADERS
