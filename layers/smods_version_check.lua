MP.Layer("smods_version_check", {
	is_disabled = function(self)
		return MP.UTILS.check_smods_version() or MP.UTILS.check_lovely_version()
	end,
})
