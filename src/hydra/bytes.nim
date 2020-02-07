proc pad*(self: var seq[byte], padding: int) =
    if padding == 0:
        return

    for i in 0..<padding:
        self.add(0'u8)


proc serialize*(value: uint64): array[8, byte] =
    result[0] = byte(value shr 56'u64)
    result[1] = byte(value shr 48'u64)
    result[2] = byte(value shr 40'u64)
    result[3] = byte(value shr 32'u64)
    result[4] = byte(value shr 24'u64)
    result[5] = byte(value shr 16'u64)
    result[6] = byte(value shr 8'u64)
    result[7] = byte(value)


proc serialize*(value: uint32): array[4, byte] =
    result[0] = byte(value shr 24'u32)
    result[1] = byte(value shr 16'u32)
    result[2] = byte(value shr 8'u32)
    result[3] = byte(value)


proc serialize*(value: uint16): array[2, byte] =
    result[0] = byte(value shr 8'u32)
    result[1] = byte(value)
