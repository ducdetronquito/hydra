import hydra
import streams
import unittest


suite "Window Update Frame":

    test "Read":
        var stream = newStringStream("\x2a\x00\x00\x00")
        let header = Header(frame_type: FrameType.WindowUpdate, length: 4'u32, stream_id: StreamId(1))
        let result = WindowUpdateFrame.read(header, stream)
        check(result.unwrap().window_size_increment == 42'u32)

    test "Frame size error when the header length is not 4":
        let header = Header(frame_type: FrameType.WindowUpdate, length: 5'u32, stream_id: StreamId(1))
        var stream = newStringStream("\x2a\x00\x00\x00\x00")
        let result = WindowUpdateFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.FrameSize)

    test "Protocol Error when the window size increment is 0":
        var stream = newStringStream("\x00\x00\x00\x00")
        let header = Header(frame_type: FrameType.WindowUpdate, length: 4'u32, stream_id: StreamId(1))
        let result = WindowUpdateFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Serialize":
        let header = Header(
            length: 4'u32,
            frame_type: FrameType.WindowUpdate,
            flags: NO_FLAG,
            stream_id: StreamId(1)
        )

        let frame = WindowUpdateFrame(header: header, window_size_increment: 42'u32)
        check(frame.serialize() == [
            0'u8, 0'u8, 4'u8, 8'u8, 0'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            0'u8, 0'u8, 0'u8, 42'u8,
        ])
