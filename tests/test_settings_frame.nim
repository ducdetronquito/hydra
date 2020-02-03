import hydra
import unittest


suite "Settings Frame":

    test "Read":
        var input = "\x01\x00\xff\x00\x00\x00"
        input.add("\x02\x00\x01\x00\x00\x00")
        input.add("\x03\x00\x05\x00\x00\x00")
        input.add("\x04\x00\x2a\x00\x00\x00")
        input.add("\x05\x00\x06\x00\x00\x00")
        input.add("\x06\x00\x07\x00\x00\x00")

        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Settings, length: 36'u32, stream_id: 0'u32)
        let frame = SettingsFrame.read(header, stream).unwrap()
        check(frame.header_table_size.get() == 255'u32)
        check(frame.enable_push.get() == true)
        check(frame.max_concurrent_streams.get() == 5'u32)
        check(frame.initial_window_size.get() == 42'u32)
        check(frame.max_frame_size.get() == 6'u32)
        check(frame.max_header_list_size.get() == 7'u32)

    test "Read no settings":
        var stream = newStringStream("")
        let header = Header(frame_type: FrameType.Settings, length: 0'u32, stream_id: 0'u32)
        let frame = SettingsFrame.read(header, stream).unwrap()
        check(frame.header_table_size.isNone)
        check(frame.enable_push.isNone)
        check(frame.max_concurrent_streams.isNone)
        check(frame.initial_window_size.isNone)
        check(frame.max_frame_size.isNone)
        check(frame.max_header_list_size.isNone)

    test "A duplicated settings is possible and override its previous value":
        var input = "\x02\x00\x01\x00\x00\x00"
        input.add("\x02\x00\x00\x00\x00\x00")
        var stream = newStringStream(input)
        let header = Header(frame_type: FrameType.Settings, length: 12'u32, stream_id: 0'u32)
        let frame = SettingsFrame.read(header, stream).unwrap()
        check(frame.enable_push.get() == false)

    test "Protocol error when does not target the connection control stream":
        let header = Header(frame_type: FrameType.Settings, length: 6'u32, stream_id: 1'u8)
        var stream = newStringStream("\x00")
        let result = SettingsFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.Protocol)

    test "Frame size error when length is not a multiple of 6 bytes":
        let header = Header(frame_type: FrameType.Settings, length: 7'u32, stream_id: 0'u8)
        var stream = newStringStream("\x00")
        let result = SettingsFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.FrameSize)

    test "Frame size error when frame is ACK but has payload":
        let header = Header(frame_type: FrameType.Settings, length: 6'u32, stream_id: 0'u8, flags: 1'u8)
        var stream = newStringStream("\x02\x00\x01\x00\x00\x00")
        let result = SettingsFrame.read(header, stream)
        check(result.unwrap_error() == ErrorCode.FrameSize)

    test "Has flag ACK":
        let header = Header(frame_type: FrameType.Settings, flags: 1'u8)
        let frame = SettingsFrame(header: header)
        check(frame.is_ack())

    test "Does not have ACK flag":
        let header = Header(frame_type: FrameType.Settings, flags: 254'u8)
        let frame = SettingsFrame(header: header)
        check(frame.is_ack() == false)
