--[[----------------------------------------------------------------------------

Info.lua
Summary information for DreanObjects plug-in

--------------------------------------------------------------------------------

 Copyright 2012 Alfredo Deza

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

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
