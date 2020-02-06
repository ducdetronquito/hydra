import hydra
import streams
import unittest


suite "Ping Frame":

    test "Read":
        let header = Header(frame_type: FrameType.Ping, length: 8'u32, stream_id: StreamId(0))
        var stream = newStringStream("\x2a\x00\x00\x00\x00\x00\x00\x00")
        let result = PingFrame.read(header, stream)
        check(result.unwrap().opaque_data == 42'u64)

    test "Protocol error when does not target the connection control stream":
        let header = Header(frame_type: FrameType.Ping, length: 8'u32, stream_id: StreamId(42))
        var stream = newStringStream("\x2a\x00\x00\x00\x00\x00\x00\x00")
        let result = PingFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Frame size error when the header length is not 8":
        let header = Header(frame_type: FrameType.Ping, length: 42'u32, stream_id: StreamId(0))
        var stream = newStringStream("\x2a\x00\x00\x00\x00\x00\x00\x00")
        let result = PingFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.FrameSize)

    test "Has flag ACK":
        let header = Header(frame_type: FrameType.Ping, flags: ACK_FLAG)
        let frame = PingFrame(header: header)
        check(frame.is_ack())

    test "Does not have ACK flag":
        let header = Header(frame_type: FrameType.Ping, flags: NO_FLAG)
        let frame = PingFrame(header: header)
        check(frame.is_ack() == false)

    test "Serialize":
        let header = Header(
            length: 8'u32,
            frame_type: FrameType.Ping,
            flags: ACK_FLAG,
            stream_id: StreamId(0)
        )
        let frame = PingFrame(header: header, opaque_data: 42'U64)

        check(frame.serialize() == @[
            0'u8, 0'u8, 8'u8, 6'u8, 1'u8, 0'u8, 0'u8, 0'u8, 0'u8,
            0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 42'u8,
        ])
