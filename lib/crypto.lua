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

function MP.UTILS.server_connection_ID()
	local os_name = love.system.getOS()
	local raw_id

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
	end

	if not raw_id then raw_id = os.getenv("USER") or os.getenv("USERNAME") or os_name end

	return MP.UTILS.encrypt_string(raw_id)
end
