--[[----------------------------------------------------------------------------

DreamObjectsUser.lua
DreamObjects user account management

--------------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2007-2010 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

------------------------------------------------------------------------------]]

	-- Lightroom SDK
local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrTasks = import 'LrTasks'
local LrHttp = import 'LrHttp'

local logger = import 'LrLogger'( 'DreamObjectsAPI' )
local prefs = import 'LrPrefs'.prefsForPlugin()
logger:enable( 'logfile' )

require 'DreamObjectsAPI'


--============================================================================--

DreamObjectsUser = {}

--------------------------------------------------------------------------------

local function storedKeysAreValid( propertyTable )
	return prefs.apiKey and string.len( prefs.apiKey ) > 0
			and prefs.sharedSecret
end

local function storedBucketIsValid( propertyTable )
	local valid_prefs =  prefs.bucket and string.len( prefs.bucket ) > 0
    local valid_bucket = propertyTable.validBucket == true or propertyTable.validBucket == nil
    return valid_prefs and valid_bucket
end


--------------------------------------------------------------------------------

local function noKeys( propertyTable )
    logger:trace("noKeys being called")

	--prefs.apiKey = nil
	--prefs.sharedSecret = nil

	propertyTable.accountStatus = LOC "$$$/DreamObjects/AccountStatus/NotLoggedIn=No valid keys"
	propertyTable.keysButtonTitle = LOC "$$$/DreamObjects/keysButton/NotLoggedIn=Add keys"
	propertyTable.keysButtonEnabled = true
	propertyTable.validKeys = false

end

local function noBucket( propertyTable )
    logger:trace("noBucket being called")
    --prefs.bucket = nil
	propertyTable.bucketButtonTitle = LOC "$$$/DreamObjects/BucketButton/NoBucket=Add bucket"
	propertyTable.bucketButtonEnabled = true
	--propertyTable.validBucket = false
	propertyTable.bucketNameTitle = LOC "$$$/DreamObjects/BucketButton/NoBucket=Add bucket"
    if not prefs.bucket then
        propertyTable.bucketStatus = LOC "$$$/DreamObjects/BucketButton/HasBucket=No valid bucket"
    else
        propertyTable.bucketStatus = LOC "$$$/DreamObjects/BucketButton/HasBucket=Invalid bucket"
    end

end

doingBucket = false

function DreamObjectsUser.validate_bucket( propertyTable )

        local do_url =   'http://' .. prefs.bucket .. ".objects.dreamhost.com"
        local result, hdrs = LrHttp.get( do_url )
        logger:trace('Validating bucket against url ', do_url)
        logger:trace('Response from bucket validation ', hdrs['status'])
        local is_valid = hdrs['status'] == 200 or hdrs['status'] == 403
        logger:trace('is valid value ' ,  is_valid)
        return  hdrs['status'] == 200 or hdrs['status'] == 403
end

--------------------------------------------------------------------------------

function DreamObjectsUser.add_bucket( propertyTable )
	if not propertyTable.LR_editingExistingPublishConnection then
	    noBucket( propertyTable )
	end
    require 'DreamObjectsAPI'
    DreamObjectsAPI.showBucketDialog()

	LrFunctionContext.postAsyncTaskWithContext( 'DreamObjects add_bucket',
	function( context )

        doingBucket = true

		propertyTable.bucketStatus = LOC "$$$/DreamObjects/BucketStatus/Status=Verifying bucket..."
		propertyTable.BucketButtonEnabled = false

		LrDialogs.attachErrorDialogToFunctionContext( context )

		-- Make sure bucket is valid when done, or is marked as invalid.

		context:addCleanupHandler( function()
			doingBucket = false

			if not storedBucketIsValid( propertyTable ) then
                logger:trace("cleanup handler saw an invalid bucket")
				noBucket( propertyTable )
			end

		end )

		-- Make sure we have an API key.
		DreamObjectsAPI.getApiKeyAndSecret()

		require 'DreamObjectsAPI'
        local is_valid = DreamObjectsUser.validate_bucket()
        logger:trace('receiving is_valid value ', is_valid)

        if is_valid then
            propertyTable.bucketButtonEnabled = true
            propertyTable.validBucket = true
            propertyTable.bucketStatus = string.format('Bucket: %s', prefs.bucket)
            propertyTable.bucketNameTitle = LOC "$$$/DreamObjects/BucketStatus/Status=Edit bucket"
            logger:trace('Bucket is valid woooo!')
        else
            propertyTable.validBucket = false
            propertyTable.bucketNameTitle = LOC "$$$/DreamObjects/BucketStatus/Status=Edit bucket"
            propertyTable.bucketStatus = LOC( "$$$/DreamObjects/BucketStatus/HasBucket=Invalid bucket")
            propertyTable.bucketStatus = "Invalid bucket"
        end
        doingBucket = false

	end )



end


function DreamObjectsUser.add_keys( propertyTable )
	if not propertyTable.LR_editingExistingPublishConnection then
		noKeys( propertyTable )
	end

    require 'DreamObjectsAPI'
    DreamObjectsAPI.showApiKeyDialog()
    propertyTable.validKeys = true
end


--------------------------------------------------------------------------------

local function getDisplayUserNameFromProperties( propertyTable )

	local displayUserName = propertyTable.fullname
	if ( not displayUserName or #displayUserName == 0 )
		or displayUserName == propertyTable.username
	then
		displayUserName = propertyTable.username
	else
		displayUserName = LOC( "$$$/DreamObjects/AccountStatus/UserNameAndLoginName=^1 (^2)",
							propertyTable.fullname,
							propertyTable.username )
	end

	return displayUserName

end

--------------------------------------------------------------------------------

function DreamObjectsUser.verifyKeys( propertyTable )

	-- Observe changes to prefs and update status message accordingly.

	local function updateStatus()
		logger:trace( "verifyKeys: updateStatus() was triggered." )

		LrTasks.startAsyncTask( function()
			logger:trace( "verifyKeys: updateStatus() is executing." )
			if storedKeysAreValid( propertyTable ) then

				propertyTable.accountStatus = LOC( "$$$/DreamObjects/AccountStatus/LoggedIn=Key pairs stored")
                propertyTable.keysButtonTitle = LOC "$$$/DreamObjects/keysButton/LogInAgain=Edit keys"
                propertyTable.keysButtonEnabled = true
                propertyTable.validKeys = true
			else
				noKeys( propertyTable )
			end

		end )

	end

	propertyTable:addObserver( 'validKeys', updateStatus )
	updateStatus()

end


function DreamObjectsUser.verifyBucket( propertyTable )

	-- Observe changes to prefs and update status message accordingly.

	local function updateStatus()

		LrTasks.startAsyncTask( function()
			logger:trace( "verifyBucket: updateStatus() is executing." )
			if storedBucketIsValid( propertyTable ) then

                propertyTable.bucketNameTitle = LOC "$$$/DreamObjects/BucketButton/EditBucket=Edit bucket"
                propertyTable.bucketButtonEnabled = true
                propertyTable.validBucket = true
                propertyTable.bucketStatus = string.format('Bucket: %s', prefs.bucket)

			else
                logger:trace('bucket was not valid so clearing it')
                noBucket( propertyTable )
			end

		end )

	end

	propertyTable:addObserver( 'validBucket', updateStatus )
	updateStatus()

end
