import base


type
    GoAwayFrame* = object
        # Initiates the shutdown of a connection or to signal serious error conditions.
        # This frame allows an endpoint to gracefully stop accepting new streams while still
        # finishing processing of previously established streams.
        # This enables administrative actions, like server maintenance.
        #
        # Cf: https://tools.ietf.org/html/rfc7540#section-6.8
        # +-+-------------------------------------------------------------+
        # |R|                  Last-Stream-ID (31)                        |
        # +-+-------------------------------------------------------------+
        # |                      Error Code (32)                          |
        # +---------------------------------------------------------------+
        # |                  Additional Debug Data (*)                    |
        # +---------------------------------------------------------------+
        header*: Header
        last_stream_id*: StreamId
        error_code*: ErrorCode
        additional_debug_data*: seq[byte]


proc read*(cls: type[GoAwayFrame], header: Header, stream: StringStream): Result[GoAwayFrame, ErrorCode] =
    if not header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    var frame = GoAwayFrame(header: header)
    frame.last_stream_id = StreamId.read(stream)
    frame.error_code = ErrorCode.read(stream)

    let payload_length = cast[int](header.length) - 8
    if payload_length == 0:
        return Ok(frame)

    let data = stream.read_padded_data(payload_length)
    if data.is_err():
        return Err(data.unwrap_error())

    frame.additional_debug_data = data.unwrap()
    return Ok(frame)
