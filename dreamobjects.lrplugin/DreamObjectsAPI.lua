--[[----------------------------------------------------------------------------

DreamObjectsAPI.lua
Common code to initiate DreamObjects API requests

--------------------------------------------------------------------------------

(C) Copyright 2013 Alfredo Deza

------------------------------------------------------------------------------]]

    -- Lightroom SDK
local LrBinding = import 'LrBinding'
local LrDate = import 'LrDate'
local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
local LrFunctionContext = import 'LrFunctionContext'
local LrHttp = import 'LrHttp'
local LrMD5 = import 'LrMD5'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'
local LrXml = import 'LrXml'
local LrTasks = import 'LrTasks'

local prefs = import 'LrPrefs'.prefsForPlugin()

local bind = LrView.bind
local share = LrView.share

local logger = import 'LrLogger'( 'DreamObjectsAPI' )
--logger:enable( 'logfile' )

--============================================================================--

DreamObjectsAPI = {}

--------------------------------------------------------------------------------

local appearsAlive

--------------------------------------------------------------------------------

local function formatError( nativeErrorCode )
    return LOC "$$$/DreamObjects/Error/NetworkFailure=Could not contact the DreamObjects web service. Please check your Internet connection."
end

--------------------------------------------------------------------------------

local simpleXmlMetatable = {
    __tostring = function( self ) return self._value end
}

--------------------------------------------------------------------------------

-- XXX We probably don't need this

local function traverse( node )

    local type = string.lower( node:type() )

    if type == 'element' then

        local element = setmetatable( {}, simpleXmlMetatable )
        element._name = node:name()
        element._value = node:text()

        local count = node:childCount()

        for i = 1, count do
            local name, value = traverse( node:childAtIndex( i ) )
            if name and value then
                element[ name ] = value
            end
        end

        if type == 'element' then
            for k, v in pairs( node:attributes() ) do
                element[ k ] = v.value
            end
        end

        return element._name, element

    end

end

--------------------------------------------------------------------------------

local function xmlElementToSimpleTable( xmlString )

    local _, value = traverse( LrXml.parseXml( xmlString ) )
    return value

end

--------------------------------------------------------------------------------

local function trim( s )

    return string.gsub( s, "^%s*(.-)%s*$", "%1" )

end

--------------------------------------------------------------------------------


function DreamObjectsAPI.showBucketDialog( message )
    logger:trace('showBucketDialog executing')
    LrFunctionContext.callWithContext( 'DreamObjectsAPI.showBucketDialog', function( context )

        logger:trace('inside context showBucketDialog executing')
        local f = LrView.osFactory()

        local properties = LrBinding.makePropertyTable( context )
        properties.bucket = prefs.bucket

        local contents = f:column {
            bind_to_object = properties,
            spacing = f:control_spacing(),
            fill = 1,

            f:static_text {
                title = LOC "$$$/DreamObjects/BucketDialog/Message=In order to publish to DreamObjects you need to define a bucket.",
                fill_horizontal = 1,
                width_in_chars = 55,
                height_in_lines = 2,
                size = 'small',
            },

            message and f:static_text {
                title = message,
                fill_horizontal = 1,
                width_in_chars = 55,
                height_in_lines = 2,
                size = 'small',
                text_color = import 'LrColor'( 1, 0, 0 ),
            } or 'skipped item',

            f:row {
                spacing = f:label_spacing(),

                f:static_text {
                    title = LOC "$$$/DreamObjects/BucketDialog/Name=Bucket Name:",
                    alignment = 'right',
                    width = share 'title_width',
                },

                f:edit_field {
                    fill_horizonal = 1,
                    width_in_chars = 35,
                    value = bind 'bucket',
                },
            },

        }

        local result = LrDialogs.presentModalDialog {
                title = LOC "$$$/DreamObjects/ApiKeyDialog/Title=Enter Your DreamObjects API Keys",
                contents = contents,
                accessoryView = f:push_button {
                    title = LOC "$$$/DreamObjects/ApiKeyDialog/GoToDreamObjects=Get DreamObjects Bucket...",
                    action = function()
                        LrHttp.openUrlInBrowser( "https://panel.dreamhost.com/index.cgi?tree=cloud.objects&" )
                    end
                },
            }


        if result == 'ok' then
            prefs.bucket = trim ( properties.bucket )
        else
            LrErrors.throwCanceled()
        end

    end )

end

--------------------------------------------------------------------------------


-- Some utilities to run System Commands. Can be Async or Not.

--------------------------------------------------------------------------------


function runcommand(cmd)
        logger:trace("about to run blocking command ", cmd)
        status = LrTasks.execute(cmd)
        logger:trace("Status was: ", status)
end

function runAsyncCommand(cmd)
    LrTasks.startAsyncTask( function()
        logger:trace("about to run async command ", cmd)
        status = LrTasks.execute(cmd)
        logger:trace("Status was: ", status)
    end )
end



--------------------------------------------------------------------------------


-- We can't include a DreamObjects API key with the source code for this plug-in, so
-- we require you obtain one on your own and enter it through this dialog.

--------------------------------------------------------------------------------


function DreamObjectsAPI.showApiKeyDialog( message )

    LrFunctionContext.callWithContext( 'DreamObjectsAPI.showApiKeyDialog', function( context )

        local f = LrView.osFactory()

        local properties = LrBinding.makePropertyTable( context )
        properties.apiKey = prefs.apiKey
        properties.sharedSecret = prefs.sharedSecret

        local contents = f:column {
            bind_to_object = properties,
            spacing = f:control_spacing(),
            fill = 1,

            f:static_text {
                title = LOC "$$$/DreamObjects/ApiKeyDialog/Message=In order to use this plug-in, you must obtain an API key (and secret) from dreamhost.com.",
                fill_horizontal = 1,
                width_in_chars = 55,
                height_in_lines = 2,
                size = 'small',
            },

            message and f:static_text {
                title = message,
                fill_horizontal = 1,
                width_in_chars = 55,
                height_in_lines = 2,
                size = 'small',
                text_color = import 'LrColor'( 1, 0, 0 ),
            } or 'skipped item',

            f:row {
                spacing = f:label_spacing(),

                f:static_text {
                    title = LOC "$$$/DreamObjects/ApiKeyDialog/Key=API Key:",
                    alignment = 'right',
                    width = share 'title_width',
                },

                f:edit_field {
                    fill_horizonal = 1,
                    width_in_chars = 35,
                    value = bind 'apiKey',
                },
            },

            f:row {
                spacing = f:label_spacing(),

                f:static_text {
                    title = LOC "$$$/DreamObjects/ApiKeyDialog/Secret=Secret Key:",
                    alignment = 'right',
                    width = share 'title_width',
                },

                f:edit_field {
                    fill_horizonal = 1,
                    width_in_chars = 35,
                    value = bind 'sharedSecret',
                },
            },
        }

        local result = LrDialogs.presentModalDialog {
                title = LOC "$$$/DreamObjects/ApiKeyDialog/Title=Enter Your DreamObjects API Keys",
                contents = contents,
                accessoryView = f:push_button {
                    title = LOC "$$$/DreamObjects/ApiKeyDialog/GoToDreamObjects=Get DreamObjects API Keys...",
                    action = function()
                        LrHttp.openUrlInBrowser( "https://panel.dreamhost.com/index.cgi?tree=cloud.objects&" )
                    end
                },
            }

        if result == 'ok' then

            prefs.apiKey = trim ( properties.apiKey )
            prefs.sharedSecret = trim ( properties.sharedSecret )

        else

            LrErrors.throwCanceled()

        end

    end )

end

--------------------------------------------------------------------------------

function DreamObjectsAPI.getApiKeyAndSecret()

    local apiKey, sharedSecret = prefs.apiKey, prefs.sharedSecret
    return apiKey, sharedSecret

end

--------------------------------------------------------------------------------

function DreamObjectsAPI.makeApiSignature( params )

    -- If no API key, add it in now.

    local apiKey, sharedSecret = DreamObjectsAPI.getApiKeyAndSecret()

    if not params.api_key then
        params.api_key = apiKey
    end

    -- Get list of arguments in sorted order.

    local argNames = {}
    for name in pairs( params ) do
        table.insert( argNames, name )
    end

    table.sort( argNames )

    -- Build the secret string to be MD5 hashed.

    local allArgs = sharedSecret
    for _, name in ipairs( argNames ) do
        if params[ name ] then  -- might be false
            allArgs = string.format( '%s%s%s', allArgs, name, params[ name ] )
        end
    end

    -- MD5 hash this string.

    return LrMD5.digest( allArgs )

end

--------------------------------------------------------------------------------

function DreamObjectsAPI.callRestMethod( propertyTable, params )

    -- Automatically add API key.

    local apiKey = DreamObjectsAPI.getApiKeyAndSecret()

    if not params.api_key then
        params.api_key = apiKey
    end

    -- Remove any special values from params.

    local suppressError = params.suppressError
    local suppressErrorCodes = params.suppressErrorCodes
    local skipAuthToken = params.skipAuthToken

    params.suppressError = nil
    params.suppressErrorCodes = nil
    params.skipAuthToken = nil

end


function DreamObjectsAPI.create( fileName, filePath)

    runcommand('python ' .. _PLUGIN.path .. '/s3.py create ' .. prefs.apiKey .. ' ' .. prefs.sharedSecret .. ' ' .. prefs.bucket .. ' ' .. fileName .. ' ' .. filePath)

end

function DreamObjectsAPI.delete( fileName )

    runcommand('python ' .. _PLUGIN.path .. '/s3.py delete ' .. prefs.apiKey .. ' ' .. prefs.sharedSecret .. ' ' .. prefs.bucket .. ' ' .. fileName )

end


--------------------------------------------------------------------------------

function DreamObjectsAPI.uploadPhoto( propertyTable, params )

    logger:info( 'uploading photo ', params.filePath )
    local filePath = params.filePath
    local fileName = LrPathUtils.leafName( filePath )

    DreamObjectsAPI.create( fileName, filePath )

end

--------------------------------------------------------------------------------

function DreamObjectsAPI.constructPhotoURL( propertyTable, params )

    -- TODO: It would be nice to have this at some point
end

--------------------------------------------------------------------------------

function DreamObjectsAPI.deletePhoto( propertyTable, params )

    -- TODO: We need to be able to delete photos
    logger:info( 'deleting photo ', params.filePath )
    local filePath = params.filePath
    local fileName = LrPathUtils.leafName( filePath )

    DreamObjectsAPI.delete( fileName )
end

