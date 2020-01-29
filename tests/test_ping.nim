import hydra
import streams
import unittest


suite "Ping Frame":

    test "Read":
        let header = Header(frame_type: FrameType.Ping, length: 8'u32, stream_id: 0'u32)
        var stream = newStringStream("\x2a\x00\x00\x00\x00\x00\x00\x00")
        let result = PingFrame.read(header, stream)
        check(result.unwrap().opaque_data == 42'u64)

    test "Protocol error when does not target the connection control stream":
        let header = Header(frame_type: FrameType.Ping, length: 8'u32, stream_id: 42'u8)
        var stream = newStringStream("\x2a\x00\x00\x00\x00\x00\x00\x00")
        let result = PingFrame.read(header, stream)
        check(result.unwrap_error() == Error.ProtocolError)

    test "Frame size error when the header length is not 8":
        let header = Header(frame_type: FrameType.Ping, length: 42'u32, stream_id: 0'u8)
        var stream = newStringStream("\x2a\x00\x00\x00\x00\x00\x00\x00")
        let result = PingFrame.read(header, stream)
        check(result.unwrap_error() == Error.FrameSizeError)

    test "Has flag ACK":
        let header = Header(frame_type: FrameType.Ping, flags: 1'u8)
        let frame = PingFrame(header: header)
        check(frame.is_ack())

    test "Does not have ACK flag":
        let header = Header(frame_type: FrameType.Ping, flags: 254'u8)
        let frame = PingFrame(header: header)
        check(frame.is_ack() == false)
