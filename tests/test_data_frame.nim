import hydra
import streams
import strutils
import unittest


suite "Data Frame":

    test "Read":
        let input = '\x01'.repeat(10)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Data, length: 10'u32, stream_id: 1'u32)
        let result = DataFrame.read(header, stream)
        check(result.unwrap().data == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Protocol error when targetq the connection control stream":
        let header = Header(frame_type: FrameType.Data, length: 1'u32, stream_id: 0'u8)
        var stream = newStringStream("\x00")
        let result = DataFrame.read(header, stream)
        check(result.unwrap_error() == Error.ProtocolError)
