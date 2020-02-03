import base


type
    PriorityFrame* = object
        # Specifies the sender-advised priority of a stream (Section 5.3).
        #
        # Cf: https://tools.ietf.org/html/rfc7540#section-6.3
        # +-+-------------------------------------------------------------+
        # |E|                  Stream Dependency (31)                     |
        # +-+-------------+-----------------------------------------------+
        # |   Weight (8)  |
        # +-+-------------+
        header*: Header
        priority*: Priority


proc read*(cls: type[PriorityFrame], header: Header, stream: StringStream): Result[PriorityFrame, ErrorCode] =
    if header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    if header.length != 5'u32:
        return Err(ErrorCode.FrameSize)

    let frame = PriorityFrame(header: header, priority: Priority.read(stream))
    return Ok(frame)
