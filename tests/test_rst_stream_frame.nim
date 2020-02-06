import hydra
import strutils
import unittest


suite "RstStream Frame":

    test "Read":
        var stream = newStringStream("\x0b\x00\x00\x00")
        let header = Header(frame_type: FrameType.RstStream, length: 4'u32, stream_id: 1'u32)
        let result = RstStreamFrame.read(header, stream)
        check(result.unwrap().error_code == ErrorCode.EnhanceYourCalm)

    test "Read an unknown error code":
        var stream = newStringStream("\xff\xff\xff\xff")
        let header = Header(frame_type: FrameType.RstStream, length: 4'u32, stream_id: 1'u32)
        let result = RstStreamFrame.read(header, stream)
        check(result.unwrap().error_code == ErrorCode.No)

    test "Protocol error when targets the connection control stream":
        let header = Header(frame_type: FrameType.RstStream, length: 4'u32, stream_id: 0'u8)
        var stream = newStringStream("")
        let result = RstStreamFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Frame size error when the header length is not 4":
        let header = Header(frame_type: FrameType.RstStream, length: 8'u32, stream_id: 1'u8)
        var stream = newStringStream("")
        let result = RstStreamFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.FrameSize)

    test "Serialize":
        let header = Header(
            length: 4'u32,
            frame_type: FrameType.RstStream,
            flags: 0'u8,
            stream_id: StreamId(1'u32)
        )

        let frame = RstStreamFrame(header: header, error_code: ErrorCode.EnhanceYourCalm)
        check(frame.serialize() == [
            0'u8, 0'u8, 4'u8, 3'u8, 0'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            0'u8, 0'u8, 0'u8, 11'u8,
        ])
