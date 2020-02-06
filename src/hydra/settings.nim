import error_codes
import flags
import frame_header
import options
import result
import streams


type
    Settings* {.pure.} = enum
        HeaderTableSize = 1'u16
        EnablePush = 2'u16
        MaxConcurrentStreams = 3'u16
        InitialWindowSize = 4'u16
        MaxFrameSize = 5'u16
        MaxHeaderListSize = 6'u16
        Unknown = 7'u16


proc create*(cls: type[Settings], value: uint32): Settings =
    if value < uint32(Settings.Unknown):
        return Settings(value)
    else:
        return Settings.Unknown


type
    SettingsFrame* = object
        # Conveys configuration parameters that affect how endpoints communicate,
        # such as preferences and constraints on peer behavior.
        # This frame is also used to acknowledge the receipt of those parameters.
        #
        # Cf: https://tools.ietf.org/html/rfc7540#section-6.5
        header*: Header
        header_table_size*: Option[uint32]
        enable_push*: Option[bool]
        max_concurrent_streams*: Option[uint32]
        initial_window_size*: Option[uint32]
        max_frame_size*: Option[uint32]
        max_header_list_size*: Option[uint32]


template is_ack*(self: SettingsFrame): bool =
    self.header.flags.contains(ACK_FLAG)


proc read*(cls: type[SettingsFrame], header: Header, stream: StringStream): Result[SettingsFrame, ErrorCode] =
    if not header.targets_connection_control_stream():
        return Err(ErrorCode.Protocol)

    if header.length mod 6'u32 != 0:
        return Err(ErrorCode.FrameSize)

    var frame = SettingsFrame(header: header)

    if frame.is_ack() and header.length != 0'u32:
        return Err(ErrorCode.FrameSize)

    var remaining_bytes = header.length
    while remaining_bytes != 0'u32:
        let identifier = Settings.create(stream.readUint16())
        let value = stream.readUint32()

        case identifier:
        of Settings.HeaderTableSize:
            frame.header_table_size = some(value)
        of Settings.EnablePush:
            frame.enable_push = some(value != 0'u32)
        of Settings.MaxConcurrentStreams:
            frame.max_concurrent_streams = some(value)
        of Settings.InitialWindowSize:
            frame.initial_window_size = some(value)
        of Settings.MaxFrameSize:
            frame.max_frame_size = some(value)
        of Settings.MaxHeaderListSize:
            frame.max_header_list_size = some(value)
        else:
            discard

        remaining_bytes -= 6'u32

    return Ok(frame)


export options