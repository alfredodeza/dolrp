--[[----------------------------------------------------------------------------

Info.lua
Summary information for DreanObjects plug-in

--------------------------------------------------------------------------------

 Copyright 2013 Alfredo Deza

------------------------------------------------------------------------------]]

return {

	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'com.adobe.lightroom.export.dreamobjects',
	LrPluginName = LOC "$$$/DreamObjects/PluginName=DreamObjects",

	LrExportServiceProvider = {
		title = LOC "$$$/DreamObjects/DreamObjects-title=DreamObjects",
		file = 'DreamObjectsExportServiceProvider.lua',
	},

    LrMetadataProvider = 'DreamObjectsMetadataDefinition.lua',

	VERSION = { major=0, minor=0, revision=1, build=1, },

}
