import hydra
import streams
import unittest


suite "Push Promise Frame":

    test "Read":
        var stream = newStringStream("\x2a\x00\x00\x00\x01\x01\x01\x01\x01")
        let header = Header(frame_type: FrameType.PushPromise, length: 9'u32, stream_id: StreamId(1))
        let frame = PushPromiseFrame.read(header, stream).unwrap()
        check(frame.promised_stream_id == StreamId(42))
        check(frame.header_block_fragment == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])

    test "Read with padding":
        var stream = newStringStream("\x02\x2a\x00\x00\x00\x01\x01\x01\x01\x01\x00\x00")
        let header = Header(frame_type: FrameType.PushPromise, length: 12'u32, stream_id: StreamId(1), flags: PADDED_FLAG)
        let frame = PushPromiseFrame.read(header, stream).unwrap()
        check(frame.promised_stream_id == StreamId(42))
        check(frame.header_block_fragment == @[1'u8, 1'u8, 1'u8, 1'u8, 1'u8])
        check(stream.atEnd())

    test "Protocol error when targets the connection control stream":
        let header = Header(frame_type: FrameType.PushPromise, length: 1'u32, stream_id: StreamId(0))
        var stream = newStringStream("\x00")
        let result = PushPromiseFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Has flag END_HEADERS":
        let header = Header(frame_type: FrameType.PushPromise, flags: END_HEADERS_FLAG)
        let frame = PushPromiseFrame(header: header)
        check(frame.ends_headers())

    test "Does not have END_HEADERS flag":
        let header = Header(frame_type: FrameType.PushPromise, flags: NO_FLAG)
        let frame = PushPromiseFrame(header: header)
        check(frame.ends_headers() == false)

    test "Has flag PADDED":
        let header = Header(frame_type: FrameType.PushPromise, flags: PADDED_FLAG)
        let frame = PushPromiseFrame(header: header)
        check(frame.is_padded())

    test "Does not have PADDED flag":
        let header = Header(frame_type: FrameType.PushPromise, flags: NO_FLAG)
        let frame = PushPromiseFrame(header: header)
        check(frame.is_padded() == false)

    test "Has flag END_HEADERS and PADDED":
        let header = Header(frame_type: FrameType.PushPromise, flags: Flag(15))
        let frame = PushPromiseFrame(header: header)
        check(frame.ends_headers())
        check(frame.is_padded())

    test "Serialize":
        let header = Header(
            length: 5'u32,
            frame_type: FrameType.PushPromise,
            flags: NO_FLAG,
            stream_id: StreamId(1)
        )

        let frame = PushPromiseFrame(
            header: header,
            promised_stream_id: StreamId(7),
            header_block_fragment: @[0'u8, 1'u8, 2'u8, 3'u8, 4'u8]
        )
        check(frame.serialize() == [
            0'u8, 0'u8, 5'u8, 5'u8, 0'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            0'u8, 0'u8, 0'u8, 7'u8,
            0'u8, 1'u8, 2'u8, 3'u8, 4'u8
        ])

    test "Serialize padded data":
        let header = Header(
            length: 10'u32,
            frame_type: FrameType.PushPromise,
            flags: PADDED_FLAG,
            stream_id: StreamId(1)
        )

        let frame = PushPromiseFrame(
            header: header,
            promised_stream_id: StreamId(7),
            header_block_fragment: @[0'u8, 1'u8, 2'u8, 3'u8, 4'u8]
        )
        check(frame.serialize() == [
            0'u8, 0'u8, 10'u8, 5'u8, 8'u8, 0'u8, 0'u8, 0'u8, 1'u8,
            5'u8,
            0'u8, 0'u8, 0'u8, 7'u8,
            0'u8, 1'u8, 2'u8, 3'u8, 4'u8,
            0'u8, 0'u8, 0'u8, 0'u8, 0'u8,
        ])
