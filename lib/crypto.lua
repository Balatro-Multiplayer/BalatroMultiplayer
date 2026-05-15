function MP.UTILS.bxor(a, b)
	local res = 0
	local bitval = 1
	while a > 0 and b > 0 do
		local a_bit = a % 2
		local b_bit = b % 2
		if a_bit ~= b_bit then res = res + bitval end
		bitval = bitval * 2
		a = math.floor(a / 2)
		b = math.floor(b / 2)
	end
	res = res + (a + b) * bitval
	return res
end

function MP.UTILS.encrypt_string(str)
	local hash = 2166136261
	for i = 1, #str do
		hash = MP.UTILS.bxor(hash, str:byte(i))
		hash = (hash * 16777619) % 2 ^ 32
	end
	return string.format("%08x", hash)
end

-- Hand evaluator.
function MP.UTILS.joker_hash(str)
	local a, b = 1, 0
	for i = 1, #str do
		a = (a + str:byte(i)) % 65521
		b = (b + a) % 65521
	end
	return string.format("%08x", b * 65536 + a)
end

function MP.UTILS.emit_log_checksum()
	local logFile = io.open(require("lovely").log_path, "rb")
	if not logFile then return end
	local logData = logFile:read("*a")
	logFile:close()
	sendTraceMessage(
		string.format("Log checksum v1 @ %d - %s", #logData, MP.UTILS.joker_hash(logData))
	)
end
local function get_hardware_fingerprint()
    local parts = {}

    if jit.os == "Windows" then
        -- Machine UUID (best Windows stable ID)
        table.insert(parts, run([[wmic csproduct get uuid | findstr /R /V "^$ UUID"]]))

        -- Motherboard serial
        table.insert(parts, run([[wmic baseboard get serialnumber | findstr /R /V "^$ SerialNumber"]]))

        -- CPU processor id
        table.insert(parts, run([[wmic cpu get processorid | findstr /R /V "^$ ProcessorId"]]))

        -- Disk serial
        table.insert(parts, run([[wmic diskdrive get serialnumber | findstr /R /V "^$ SerialNumber"]]))

        -- BIOS serial
        table.insert(parts, run([[wmic bios get serialnumber | findstr /R /V "^$ SerialNumber"]]))

    elseif jit.os == "OSX" then
        -- Platform UUID
        table.insert(parts, run([[ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/ {print $4}']]))

        -- Board serial
        table.insert(parts, run([[ioreg -l | awk -F'"' '/IOPlatformSerialNumber/ {print $4}']]))

        -- CPU brand string
        table.insert(parts, run([[sysctl -n machdep.cpu.brand_string]]))

        -- Disk serial
        table.insert(parts, run([[system_profiler SPStorageDataType | awk -F': ' '/Serial Number/ {print $2; exit}]]))

    elseif jit.os == "Linux" then
        table.insert(parts, run([[cat /sys/class/dmi/id/product_uuid 2>/dev/null]]))
        table.insert(parts, run([[cat /sys/class/dmi/id/board_serial 2>/dev/null]]))
        table.insert(parts, run([[cat /proc/cpuinfo | grep 'model name' | head -n1]]))
        table.insert(parts, run([[lsblk -ndo SERIAL | head -n1]]))
    end

    local raw = table.concat(parts, "|")
    return MP.UTILS.encrypt_string(raw), raw
end

function MP.UTILS.server_connection_ID()
	local os_name = love.system.getOS()
	local raw_id
	local raw_id2

	if os_name == "Windows" then
		local ffi = require("ffi")

		ffi.cdef([[
		typedef unsigned long DWORD;
		typedef int BOOL;
		typedef const char* LPCSTR;

		BOOL GetVolumeInformationA(
			LPCSTR lpRootPathName,
			char* lpVolumeNameBuffer,
			DWORD nVolumeNameSize,
			DWORD* lpVolumeSerialNumber,
			DWORD* lpMaximumComponentLength,
			DWORD* lpFileSystemFlags,
			char* lpFileSystemNameBuffer,
			DWORD nFileSystemNameSize
		);
		]])

		local serial_ptr = ffi.new("DWORD[1]")
		local ok = ffi.C.GetVolumeInformationA("C:\\", nil, 0, serial_ptr, nil, nil, nil, 0)
		if ok ~= 0 then raw_id = tostring(serial_ptr[0]) end
	elseif os_name == "OS X" then
		local cmd =
			[[ioreg -rd1 -c IOPlatformExpertDevice | awk '/IOPlatformUUID/ { split($0, line, "\""); printf("%s\n", line[4]); }']]
		local handle = io.popen(cmd)
		local result = handle:read("*a")
		if handle then handle:close() end
		print(result)
		raw_id = tostring(result)
	end

	if not raw_id then raw_id = os.getenv("USER") or os.getenv("USERNAME") or os_name end

	raw_id2, rawraw = get_hardware_fingerprint()

	if not raw_id2 then raw_id2 = os.getenv("USER") or os.getenv("USERNAME") or os_name end

	return MP.UTILS.encrypt_string(raw_id), MP.UTILS.encrypt_string(raw_id2), rawraw
end
