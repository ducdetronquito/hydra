import hydra
import streams
import strutils
import unittest


suite "Headers Frame":

    test "Read":
        let input = '\x01'.repeat(10)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Headers, length: 10'u32, stream_id: StreamId(1))
        let result = HeadersFrame.read(header, stream)
        check(result.unwrap().header_block_fragment == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Read with data that has padding":
        let input = '\x04' & '\x01'.repeat(5) & '\x00'.repeat(4)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Headers, length: 10'u32, stream_id: StreamId(1), flags: PADDED_FLAG)
        let result = HeadersFrame.read(header, stream)
        check(result.unwrap().header_block_fragment == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Read with data that has priority":
        let input = "\x07\x00\x00\x80\x2a" & '\x01'.repeat(5)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Headers, length: 10'u32, stream_id: StreamId(1), flags: PRIORITY_FLAG)
        let frame = HeadersFrame.read(header, stream).unwrap()
        let priority = frame.priority.get()
        check(priority.weight == 42'u8)
        check(priority.exclusive == true)
        check(priority.stream_dependency == StreamId(7))
        check(frame.header_block_fragment == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Protocol error when the payload is only padding without data":
        let input = '\x09' & '\x00'.repeat(9)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Headers, length: 10'u32, stream_id: StreamId(1), flags: PADDED_FLAG)
        let result = HeadersFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Protocol error when targets the connection control stream":
        let header = Header(frame_type: FrameType.Headers, length: 1'u32, stream_id: StreamId(0))
        var stream = newStringStream("\x00")
        let result = HeadersFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Has flag PADDED":
        let header = Header(frame_type: FrameType.Headers, flags: PADDED_FLAG)
        let frame = HeadersFrame(header: header)
        check(frame.is_padded())

    test "Does not have PADDED flag":
        let header = Header(frame_type: FrameType.Headers, flags: NO_FLAG)
        let frame = HeadersFrame(header: header)
        check(frame.is_padded() == false)

    test "Has flag PRIORITY":
        let header = Header(frame_type: FrameType.Headers, flags: PRIORITY_FLAG)
        let frame = HeadersFrame(header: header)
        check(frame.has_priority())

    test "Does not have PRIORITY flag":
        let header = Header(frame_type: FrameType.Headers, flags: NO_FLAG)
        let frame = HeadersFrame(header: header)
        check(frame.has_priority() == false)

    test "Has flag PADDED and PRIORITY":
        let header = Header(frame_type: FrameType.Headers, flags: Flag(40))
        let frame = HeadersFrame(header: header)
        check(frame.is_padded())
        check(frame.has_priority())

    test "Has flag END_STREAM":
        let header = Header(frame_type: FrameType.Headers, flags: END_STREAM_FLAG)
        let frame = HeadersFrame(header: header)
        check(frame.ends_stream())

    test "Does not have PRIORITY flag":
        let header = Header(frame_type: FrameType.Headers, flags: NO_FLAG)
        let frame = HeadersFrame(header: header)
        check(frame.ends_stream() == false)

    test "Has flag END_HEADERS":
        let header = Header(frame_type: FrameType.Headers, flags: END_HEADERS_FLAG)
        let frame = HeadersFrame(header: header)
        check(frame.ends_headers())

    test "Does not have END_HEADERS flag":
        let header = Header(frame_type: FrameType.Headers, flags: NO_FLAG)
        let frame = HeadersFrame(header: header)
        check(frame.ends_headers() == false)

    test "Serialize":
        let header = Header(frame_type: FrameType.Headers, length: 5'u32, stream_id: StreamId(1))
        let frame = HeadersFrame(header: header, header_block_fragment: @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])
        check(frame.serialize() == [
            0'u8, 0'u8, 5'u8, 1'u8, 0'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            1'u8, 1'u8, 1'u8, 1'u8, 1'u8,
        ])

    test "Serialize padded header block":
        let header = Header(frame_type: FrameType.Headers, length: 10'u32, stream_id: StreamId(1), flags: PADDED_FLAG)
        let frame = HeadersFrame(header: header, header_block_fragment: @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])
        check(frame.serialize() == [
            0'u8, 0'u8, 10'u8, 1'u8, 8'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            5'u8,
            1'u8, 1'u8, 1'u8, 1'u8, 1'u8,
            0'u8, 0'u8, 0'u8, 0'u8, 0'u8,
        ])

    test "Serialize padded header block with priority":
        let header = Header(frame_type: FrameType.Headers, length: 15'u32, stream_id: StreamId(1), flags: Flag(40))
        let priority = Priority(exclusive: true, stream_dependency: StreamId(7), weight: 42'u8)
        let frame = HeadersFrame(
            header: header,
            priority: some(priority),
            header_block_fragment: @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8]
        )
        check(frame.serialize() == [
            0'u8, 0'u8, 15'u8, 1'u8, 40'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            5'u8,
            128'u8, 0'u8, 0'u8, 7'u8, 42'u8,
            1'u8, 1'u8, 1'u8, 1'u8, 1'u8,
            0'u8, 0'u8, 0'u8, 0'u8, 0'u8,
        ])
