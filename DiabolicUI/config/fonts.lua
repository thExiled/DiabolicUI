local Addon, Engine = ...
local path = ([[Interface\AddOns\%s\media\fonts\]]):format(Addon)

local config = {
	fonts = {
		text_normal = {
			path = path .. "DejaVuSans.ttf",
			locales = {
				enUS  = true,
				enGB = true,
				deDE = true,
				esES = true,
				esMX = true,
				frFR = true,
				itIT = true,
				ptBR = true,
				ptPT = true,
				ruRU = true
			}
		},
		text_narrow = {
			path = path .. "DejaVuSansCondensed.ttf",
			locales = {
				enUS  = true,
				enGB = true,
				deDE = true,
				esES = true,
				esMX = true,
				frFR = true,
				itIT = true,
				ptBR = true,
				ptPT = true,
				ruRU = true
			}
		},
		text_serif = {
			path = path .. "DejaVuSerifCondensed.ttf",
			locales = {
				enUS  = true,
				enGB = true,
				deDE = true,
				esES = true,
				esMX = true,
				frFR = true,
				itIT = true,
				ptBR = true,
				ptPT = true,
				ruRU = true
			}
		},
		text_serif_italic = {
			path = path .. "DejaVuSerifCondensed-Italic.ttf",
			locales = {
				enUS  = true,
				enGB = true,
				deDE = true,
				esES = true,
				esMX = true,
				frFR = true,
				itIT = true,
				ptBR = true,
				ptPT = true,
				ruRU = true
			}
		},
		header_normal = {
			path = path .. "ExocetBlizzardMedium.ttf",
			locales = {
				enUS  = true,
				enGB = true,
				deDE = true,
				esES = true,
				esMX = true,
				frFR = true,
				itIT = true,
				ptBR = true,
				ptPT = true,
				ruRU = true,
				koKR = true,
				zhTW = true
			}
		},
		header_light = {
			path = path .. "ExocetBlizzardLight.ttf",
			locales = {
				enUS  = true,
				enGB = true,
				deDE = true,
				esES = true,
				esMX = true,
				frFR = true,
				itIT = true,
				ptBR = true,
				ptPT = true,
				ruRU = true,
				koKR = true,
				zhTW = true
			}
		},
		number = {
			path = path .. "Sylfaen.ttf",
			locales = {
				enUS = true,
				enGB = true,
				deDE = true,
				esES = true,
				esMX = true,
				frFR = true,
				itIT = true,
				ptBR = true,
				ptPT = true,
				ruRU = true
			}
		},
		damage = {
			path = path .. "Coalition.ttf",
			locales = {
				enUS = true,
				enGB = true,
				deDE = true,
				esES = true,
				esMX = true,
				frFR = true,
				itIT = true,
				ptBR = true,
				ptPT = true
			}
		}
	}
}

Engine:NewStaticConfig("Fonts", config)
