import hydra
import streams
import unittest


suite "Go Away Frame":

    test "Read":
        var stream = newStringStream("\x2a\x00\x00\x00\x0b\x00\x00\x00")
        let header = Header(frame_type: FrameType.GoAway, length: 8'u32, stream_id: StreamId(0))
        let frame = GoAwayFrame.read(header, stream).unwrap()
        check(frame.last_stream_id == StreamId(42))
        check(frame.error_code == ErrorCode.EnhanceYourCalm)

    test "Read with debug data":
        var stream = newStringStream("\x2a\x00\x00\x00\x0b\x00\x00\x00\x01\x01\x01\x01")
        let header = Header(frame_type: FrameType.GoAway, length: 12'u32, stream_id: StreamId(0))
        let frame = GoAwayFrame.read(header, stream).unwrap()
        check(frame.last_stream_id == StreamId(42))
        check(frame.error_code == ErrorCode.EnhanceYourCalm)
        check(frame.additional_debug_data == @[1'u8, 1'u8, 1'u8, 1'u8])

    test "Read unknown error code is equivalent to no error":
        var stream = newStringStream("\x2a\x00\x00\x00\xff\x00\x00\x00")
        let header = Header(frame_type: FrameType.GoAway, length: 8'u32, stream_id: StreamId(0))
        let frame = GoAwayFrame.read(header, stream).unwrap()
        check(frame.last_stream_id == StreamId(42))
        check(frame.error_code == ErrorCode.No)

    test "Protocol error when does not target the connection control stream":
        var stream = newStringStream("\x2a\x00\x00\x00\x0b\x00\x00\x00")
        let header = Header(frame_type: FrameType.GoAway, length: 8'u32, stream_id: StreamId(1))
        let error = GoAwayFrame.read(header, stream).unwrap_error()
        check(error == ErrorCode.Protocol)
