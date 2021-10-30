local version = "1.0.0"

return {
@#IF DEBUG
	version = version .. "-" .. os.date("%Y:%m:%d-%H:%M:%S") .. "-debug",
@#ELSE
	version = version,
@#ENDIF
}