import hydra
import strutils
import unittest


suite "Continuation Frame":

    test "Read":
        let input = '\x01'.repeat(5)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Continuation, length: 5'u32, stream_id: 1'u32)
        let result = ContinuationFrame.read(header, stream)
        check(result.unwrap().header_block_fragment == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Protocol error when targets the connection control stream":
        let header = Header(frame_type: FrameType.Continuation, length: 3'u32, stream_id: 0'u8)
        var stream = newStringStream("\x01\x01\x01")
        let result = ContinuationFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Has flag END_HEADERS":
        let header = Header(frame_type: FrameType.Continuation, flags: 4'u8)
        let frame = ContinuationFrame(header: header)
        check(frame.is_end_headers())

    test "Does not have END_HEADERS flag":
        let header = Header(frame_type: FrameType.Continuation, flags: 3'u8)
        let frame = ContinuationFrame(header: header)
        check(frame.is_end_headers() == false)

    test "Serialize":
        let header = Header(
            length: 5'u32,
            frame_type: FrameType.Continuation,
            flags: 0'u8,
            stream_id: StreamId(1'u32)
        )

        let frame = DataFrame(header: header, data: @[0'u8, 1'u8, 2'u8, 3'u8, 4'u8])
        check(frame.serialize() == [
            0'u8, 0'u8, 5'u8, 9'u8, 0'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            0'u8, 1'u8, 2'u8, 3'u8, 4'u8
        ])
