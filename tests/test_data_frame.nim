import hydra
import strutils
import streams
import unittest


suite "Data Frame":

    test "Read":
        let input = '\x01'.repeat(10)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Data, length: 10'u32, stream_id: StreamId(1))
        let result = DataFrame.read(header, stream)
        check(result.unwrap().data == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Read with data that has padding":
        let input = '\x04' & '\x01'.repeat(5) & '\x00'.repeat(4)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Data, length: 10'u32, stream_id: StreamId(1), flags: PADDED_FLAG)
        let result = DataFrame.read(header, stream)
        check(result.unwrap().data == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])
        check(stream.atEnd())

    test "Protocol error when the payload is only padding without data":
        let input = '\x09' & '\x00'.repeat(9)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Data, length: 10'u32, stream_id: StreamId(1), flags: PADDED_FLAG)
        let result = DataFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Protocol error when targets the connection control stream":
        let header = Header(frame_type: FrameType.Data, length: 1'u32, stream_id: StreamId(0))
        var stream = newStringStream("\x00")
        let result = DataFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Has flag END_STREAM":
        let header = Header(frame_type: FrameType.Data, flags: END_STREAM_FLAG)
        let frame = DataFrame(header: header)
        check(frame.ends_stream())

    test "Does not have END_STREAM flag":
        let header = Header(frame_type: FrameType.Data, flags: NO_FLAG)
        let frame = DataFrame(header: header)
        check(frame.ends_stream() == false)

    test "Has flag PADDED":
        let header = Header(frame_type: FrameType.Data, flags: PADDED_FLAG)
        let frame = DataFrame(header: header)
        check(frame.is_padded())

    test "Does not have PADDED flag":
        let header = Header(frame_type: FrameType.Data, flags: NO_FLAG)
        let frame = DataFrame(header: header)
        check(frame.is_padded() == false)

    test "Has flag END_STREAM and PADDED":
        let header = Header(frame_type: FrameType.Data, flags: Flag(15))
        let frame = DataFrame(header: header)
        check(frame.ends_stream())
        check(frame.is_padded())

    test "Serialize":
        let header = Header(
            length: 5'u32,
            frame_type: FrameType.Data,
            flags: NO_FLAG,
            stream_id: StreamId(1)
        )

        let frame = DataFrame(header: header, data: @[0'u8, 1'u8, 2'u8, 3'u8, 4'u8])
        check(frame.serialize() == [
            0'u8, 0'u8, 5'u8, 0'u8, 0'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            0'u8, 1'u8, 2'u8, 3'u8, 4'u8
        ])

    test "Serialize padded data":
        let header = Header(
            length: 10'u32,
            frame_type: FrameType.Data,
            flags: PADDED_FLAG,
            stream_id: StreamId(1)
        )

        let frame = DataFrame(header: header, data: @[0'u8, 1'u8, 2'u8, 3'u8, 4'u8])
        check(frame.serialize() == [
            0'u8, 0'u8, 10'u8, 0'u8, 8'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            5'u8,
            0'u8, 1'u8, 2'u8, 3'u8, 4'u8,
            0'u8, 0'u8, 0'u8, 0'u8, 0'u8,
        ])
