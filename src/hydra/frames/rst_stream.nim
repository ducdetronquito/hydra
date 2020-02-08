import error_codes
import frame_header
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
    if header.length != 4'u32:
        return Err(ErrorCode.FrameSize)

    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    let error_code = ErrorCode.read(stream)
    return Ok(RstStreamFrame(header: header, error_code: error_code))


proc serialize*(self: RstStreamFrame): seq[byte] =
    result = self.header.serialize()
    result.add(self.error_code.serialize())
    return result
