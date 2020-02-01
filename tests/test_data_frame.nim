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

    test "Read with data that has padding":
        let input = '\x04' & '\x01'.repeat(5) & '\x00'.repeat(4)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Data, length: 10'u32, stream_id: 1'u32, flags: 8'u8)
        let result = DataFrame.read(header, stream)
        check(result.unwrap().data == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Protocol error when the payload is only padding without data":
        let input = '\x09' & '\x00'.repeat(9)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Data, length: 10'u32, stream_id: 1'u32, flags: 8'u8)
        let result = DataFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Protocol error when targets the connection control stream":
        let header = Header(frame_type: FrameType.Data, length: 1'u32, stream_id: 0'u8)
        var stream = newStringStream("\x00")
        let result = DataFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Has flag END_STREAM":
        let header = Header(frame_type: FrameType.Data, flags: 1'u8)
        let frame = DataFrame(header: header)
        check(frame.is_end_stream())

    test "Does not have END_STREAM flag":
        let header = Header(frame_type: FrameType.Data, flags: 2'u8)
        let frame = DataFrame(header: header)
        check(frame.is_end_stream() == false)

    test "Has flag PADDED":
        let header = Header(frame_type: FrameType.Data, flags: 8'u8)
        let frame = DataFrame(header: header)
        check(frame.is_padded())

    test "Does not have PADDED flag":
        let header = Header(frame_type: FrameType.Data, flags: 4'u8)
        let frame = DataFrame(header: header)
        check(frame.is_padded() == false)

    test "Has flag END_STREAM and PADDED":
        let header = Header(frame_type: FrameType.Data, flags: 15'u8)
        let frame = DataFrame(header: header)
        check(frame.is_end_stream())
        check(frame.is_padded())
