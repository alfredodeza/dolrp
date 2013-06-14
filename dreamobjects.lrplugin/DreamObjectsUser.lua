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
	return prefs.bucket and string.len( prefs.bucket ) > 0
		and propertyTable.validBucket
end


--------------------------------------------------------------------------------

local function noKeys( propertyTable )
    logger:trace("noKeys being called")

	prefs.apiKey = nil
	prefs.sharedSecret = nil

	propertyTable.accountStatus = LOC "$$$/DreamObjects/AccountStatus/NotLoggedIn=No valid keys"
	propertyTable.keysButtonTitle = LOC "$$$/DreamObjects/keysButton/NotLoggedIn=Add keys"
	propertyTable.keysButtonEnabled = true
	propertyTable.validKeys = false

end

local function noBucket( propertyTable )
    logger:trace("noBucket being called")

    prefs.bucket = nil
	propertyTable.bucketButtonTitle = LOC "$$$/DreamObjects/BucketButton/NoBucket=Add bucket"
	propertyTable.bucketButtonEnabled = true
	propertyTable.validBucket = false
	propertyTable.bucketNameTitle = LOC "$$$/DreamObjects/BucketButton/NoBucket=Add bucket"
	propertyTable.bucketStatus = LOC "$$$/DreamObjects/BucketButton/HasBucket=No valid bucket"

end

doingBucket = false

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

		-- Make sure login is valid when done, or is marked as invalid.

		context:addCleanupHandler( function()

			doingBucket = false

			if not storedKeysAreValid( propertyTable ) then
				noKeys( propertyTable )
			end

		end )

		-- Make sure we have an API key.
		DreamObjectsAPI.getApiKeyAndSecret()

		require 'DreamObjectsAPI'

        local s3 = require('s3')

        -- set credentials
        s3.AWS_Access_Key_ID =  prefs.apiKey
        s3.AWS_Secret_Key =  prefs.sharedSecret

        -- get the bucket
        local bucket = s3.getBucket(prefs.bucket)
        if bucket:is_valid() then
            propertyTable.bucketButtonEnabled = true
            propertyTable.validBucket = true
            propertyTable.bucketStatus = string.format('Bucket: %s', prefs.bucket)
            propertyTable.bucketNameTitle = LOC "$$$/DreamObjects/BucketStatus/Status=Edit bucket"
        else
            propertyTable.validBucket = false
            propertyTable.bucketNameTitle = LOC "$$$/DreamObjects/BucketStatus/Status=Edit bucket"
            propertyTable.bucketStatus = "Invalid bucket"
        end
        doingBucket = false



		--local data = DreamObjectsAPI.callRestMethod( propertyTable, { method = 'flickr.auth.getToken', frob = frob, suppressError = true, skipAuthToken = true } )

		--local auth = data.auth

		--if not auth then
		--	return
		--end

		---- If editing existing connection, make sure user didn't try to change user ID on us.

		--if propertyTable.LR_editingExistingPublishConnection then

		--	if auth.user and propertyTable.nsid ~= auth.user.nsid then
		--		LrDialogs.message( LOC "$$$/DreamObjects/CantChangeUserID=You can not change DreamObjects accounts on an existing publish connection. Please log in again with the account you used when you first created this connection." )
		--		return
		--	end

		--end

		---- Now we can read the DreamObjects user credentials. Save off to prefs.

		--propertyTable.nsid = auth.user.nsid
		--propertyTable.username = auth.user.username
		--propertyTable.fullname = auth.user.fullname
		--propertyTable.auth_token = auth.token._value

		--DreamObjectsUser.updateUserStatusTextBindings( propertyTable )

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

            -- If this gets triggered it will take me to FLICKR
			--DreamObjectsUser.updateUserStatusTextBindings( propertyTable )
		end )

	end

	propertyTable:addObserver( 'validKeys', updateStatus )
	updateStatus()

end


function DreamObjectsUser.verifyBucket( propertyTable )

	-- Observe changes to prefs and update status message accordingly.

	local function updateStatus()
		logger:trace( "verifyBucket: updateStatus() was triggered." )

		LrTasks.startAsyncTask( function()
			logger:trace( "verifyBucket: updateStatus() is executing." )
			if storedBucketIsValid( propertyTable ) then

				propertyTable.bucketStatus = LOC( "$$$/DreamObjects/BucketStatus/HasBucket=Bucket stored")
                propertyTable.bucketNameTitle = LOC "$$$/DreamObjects/BucketButton/EditBucket=Edit bucket"
                propertyTable.bucketButtonEnabled = true
                propertyTable.validBucket = true
			else
				noBucket( propertyTable )
			end

		end )

	end

	propertyTable:addObserver( 'validBucket', updateStatus )
	updateStatus()

end

--------------------------------------------------------------------------------

--function DreamObjectsUser.updateUserStatusTextBindings( settings )
--
--	local nsid = settings.nsid
--
--	if nsid and string.len( nsid ) > 0 then
--
--		LrFunctionContext.postAsyncTaskWithContext( 'DreamObjects account status check',
--		function( context )
--
--			context:addFailureHandler( function()
--
--				-- Login attempt failed. Offer chance to re-establish connection.
--
--				if settings.LR_editingExistingPublishConnection then
--
--					local displayUserName = getDisplayUserNameFromProperties( settings )
--
--					settings.accountStatus = LOC( "$$$/DreamObjects/AccountStatus/LogInFailed=Log in failed, was logged in as ^1", displayUserName )
--
--					settings.keysButtonTitle = LOC "$$$/DreamObjects/keysButton/LogInAgain=Log In"
--					settings.keysButtonEnabled = true
--					settings.validAccount = false
--
--					settings.isUserPro = false
--					settings.accountTypeMessage = LOC "$$$/DreamObjects/AccountStatus/LoginFailed/Message=Could not verify this DreamObjects account. Please log in again. Please note that you can not change the DreamObjects account for an existing publish connection. You must log in to the same account."
--
--				end
--
--			end )
--
--			local userinfo = DreamObjectsAPI.getUserInfo( settings, { userId = nsid } )
--			if userinfo and ( not userinfo.ispro ) then
--				settings.accountTypeMessage = LOC( "$$$/DreamObjects/NonProAccountLimitations=This account is not a DreamObjects Pro account, and is subject to limitations. Once a photo has been uploaded, it will not be automatically updated if it changes. In addition, there is an upload bandwidth limit each month." )
--				settings.isUserPro = false
--			else
--				settings.accountTypeMessage = LOC( "$$$/DreamObjects/ProAccountDescription=This DreamObjects Pro account can utilize collections, modified photos will be automatically be re-published, and there is no monthly bandwidth limit." )
--				settings.isUserPro = true
--			end
--
--		end )
--	else
--
--		settings.accountTypeMessage = LOC( "$$$/DreamObjects/SignIn=Sign in with your DreamObjects account." )
--		settings.isUserPro = false
--
--	end
--
--end
