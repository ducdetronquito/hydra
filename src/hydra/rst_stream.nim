import error_codes
import header
import result
import streams

type
    RstStreamFrame* = object
        # Allows for immediate termination of a stream.
        # This frame is sent to request cancellation of a stream or to
        # indicate that an error condition has occurred.
        #
        # Cf: https://tools.ietf.org/html/rfc7540#section-6.4
        # +---------------------------------------------------------------+
        # |                        Error Code (32)                        |
        # +---------------------------------------------------------------+
        header*: Header
        error_code*: ErrorCode


proc read*(cls: type[RstStreamFrame], header: Header, stream: StringStream): Result[RstStreamFrame, ErrorCode] =
    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    if header.length != 4'u32:
        return Err(ErrorCode.FrameSize)

    let error_code = ErrorCode.create(stream.readUint32())
    return Ok(RstStreamFrame(header: header, error_code: error_code))
