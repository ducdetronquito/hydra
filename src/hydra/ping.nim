import header
import streams


type
    PingFrame* = object
        # The PING frame is a mechanism for measuring a minimal round-trip time from the sender,
        # as well as determining whether an idle connection is still functional.
        # Cf: https://httpwg.org/specs/rfc7540.html#rfc.section.6.7
        #  +---------------------------------------------------------------+
        #  |                                                               |
        #  |                      Opaque Data (64)                         |
        #  |                                                               |
        #  +---------------------------------------------------------------+
        header: Header
        opaque_data*: uint64


proc read*(cls: type[PingFrame], header: Header, stream: StringStream): PingFrame =
    # TODO: Handle when stream_id = 0x0 --> raises ProtocolError
    # TODO: Handle when lenght != 8 --> FrameSizeError
    return PingFrame(header: header, opaque_data: stream.readUint64())