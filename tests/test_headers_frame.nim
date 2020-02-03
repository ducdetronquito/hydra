import hydra
import strutils
import unittest


suite "Headers Frame":

    test "Read":
        let input = '\x01'.repeat(10)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Headers, length: 10'u32, stream_id: 1'u32)
        let result = HeadersFrame.read(header, stream)
        check(result.unwrap().header_block_fragment == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Read with data that has padding":
        let input = '\x04' & '\x01'.repeat(5) & '\x00'.repeat(4)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Headers, length: 10'u32, stream_id: 1'u32, flags: 8'u8)
        let result = HeadersFrame.read(header, stream)
        check(result.unwrap().header_block_fragment == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Read with data that has priority":
        let input = "\x07\x00\x00\x80\x2a" & '\x01'.repeat(5)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Headers, length: 10'u32, stream_id: 1'u32, flags: 32'u8)
        let frame = HeadersFrame.read(header, stream).unwrap()
        let priority = frame.priority.get()
        check(priority.weight == 42'u8)
        check(priority.exclusive == true)
        check(priority.stream_dependency == 7'u32)
        check(frame.header_block_fragment == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Protocol error when the payload is only padding without data":
        let input = '\x09' & '\x00'.repeat(9)
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Headers, length: 10'u32, stream_id: 1'u32, flags: 8'u8)
        let result = HeadersFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Protocol error when targets the connection control stream":
        let header = Header(frame_type: FrameType.Headers, length: 1'u32, stream_id: 0'u8)
        var stream = newStringStream("\x00")
        let result = HeadersFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Has flag PADDED":
        let header = Header(frame_type: FrameType.Headers, flags: 8'u8)
        let frame = HeadersFrame(header: header)
        check(frame.is_padded())

    test "Does not have PADDED flag":
        let header = Header(frame_type: FrameType.Headers, flags: 4'u8)
        let frame = HeadersFrame(header: header)
        check(frame.is_padded() == false)

    test "Has flag PRIORITY":
        let header = Header(frame_type: FrameType.Headers, flags: 32'u8)
        let frame = HeadersFrame(header: header)
        check(frame.has_priority())

    test "Does not have PRIORITY flag":
        let header = Header(frame_type: FrameType.Headers, flags: 31'u8)
        let frame = HeadersFrame(header: header)
        check(frame.has_priority() == false)

    test "Has flag PADDED and PRIORITY":
        let header = Header(frame_type: FrameType.Headers, flags: 40'u8)
        let frame = HeadersFrame(header: header)
        check(frame.is_padded())
        check(frame.has_priority())

    test "Has flag END_STREAM":
        let header = Header(frame_type: FrameType.Headers, flags: 1'u8)
        let frame = HeadersFrame(header: header)
        check(frame.is_end_stream())

    test "Does not have PRIORITY flag":
        let header = Header(frame_type: FrameType.Headers, flags: 0'u8)
        let frame = HeadersFrame(header: header)
        check(frame.is_end_stream() == false)

    test "Has flag END_HEADERS":
        let header = Header(frame_type: FrameType.Headers, flags: 4'u8)
        let frame = HeadersFrame(header: header)
        check(frame.is_end_headers())

    test "Does not have END_HEADERS flag":
        let header = Header(frame_type: FrameType.Headers, flags: 3'u8)
        let frame = HeadersFrame(header: header)
        check(frame.is_end_headers() == false)
