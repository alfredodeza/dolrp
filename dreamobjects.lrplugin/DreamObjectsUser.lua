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

local function storedCredentialsAreValid( propertyTable )
	return prefs.apiKey and string.len( prefs.apiKey ) > 0
			and prefs.sharedSecret
end

local function storedBucketIsValid( propertyTable )
	return prefs.bucket and string.len( prefs.bucket ) > 0
end


--------------------------------------------------------------------------------

local function notLoggedIn( propertyTable )

	prefs.apiKey = nil
	prefs.sharedSecret = nil

	propertyTable.accountStatus = LOC "$$$/DreamObjects/AccountStatus/NotLoggedIn=No valid keys"
	propertyTable.loginButtonTitle = LOC "$$$/DreamObjects/LoginButton/NotLoggedIn=Add keys"
	propertyTable.loginButtonEnabled = true
	propertyTable.validAccount = false

end

local function noBucket( propertyTable )

    prefs.bucket = nil
	propertyTable.bucketNameTitle = LOC "$$$/DreamObjects/BucketButton/NoBucket=Add bucket"
	propertyTable.bucketStatus = LOC "$$$/DreamObjects/BucketButton/HasBucket=No valid bucket"

end

doingBucket = false

--------------------------------------------------------------------------------
function DreamObjectsUser.add_bucket( propertyTable )
    -- TODO Need to do async creation of bucket to DreamHost
	if not propertyTable.LR_editingExistingPublishConnection then
        noBucket( propertyTable )
        notLoggedIn( propertyTable )
	end
    require 'DreamObjectsAPI'
    DreamObjectsAPI.showBucketDialog()
    propertyTable.validAccount = true

	LrFunctionContext.postAsyncTaskWithContext( 'DreamObjects add_bucket',
	function( context )

		-- Clear any existing login info, but only if creating new account.
		-- If we're here on an existing connection, that's because the login
		-- token was rejected. We need to retain existing account info so we
		-- can cross-check it.
        -- XXX we already did this before starting
		--if not propertyTable.LR_editingExistingPublishConnection then
		--	notLoggedIn( propertyTable )
		--end
        doingBucket = true

		propertyTable.bucketStatus = LOC "$$$/DreamObjects/BucketStatus/Status=Verifying bucket..."
		propertyTable.BucketButtonEnabled = false

		LrDialogs.attachErrorDialogToFunctionContext( context )

		-- Make sure login is valid when done, or is marked as invalid.

		context:addCleanupHandler( function()

			doingBucket = false

			if not storedCredentialsAreValid( propertyTable ) then
				notLoggedIn( propertyTable )
			end

			-- Hrm. New API doesn't make it easy to show what operation failed.
			-- LrDialogs.message( LOC "$$$/DreamObjects/LoginFailed=Failed to log in." )

		end )

		-- Make sure we have an API key.

		DreamObjectsAPI.getApiKeyAndSecret()

		-- Show request for authentication dialog.
        -- XXX we probably don't need to ask for permission
		--local authRequestDialogResult = LrDialogs.confirm(
		--	LOC "$$$/DreamObjects/AuthRequestDialog/Message=Lightroom needs your permission to upload images to DreamObjects.",
		--	LOC "$$$/DreamObjects/AuthRequestDialog/HelpText=If you click Authorize, you will be taken to a web page in your web browser where you can log in. When you're finished, return to Lightroom to complete the authorization.",
		--	LOC "$$$/DreamObjects/AuthRequestDialog/AuthButtonText=Authorize",
		--	LOC "$$$/LrDialogs/Cancel=Cancel" )

		--if authRequestDialogResult == 'cancel' then
		--	return
		--end

		-- Request the frob that we need for authentication.

		propertyTable.accountStatus = LOC "$$$/DreamObjects/AccountStatus/WaitingForDreamObjects=Waiting for response from dreamhost.com..."

		require 'DreamObjectsAPI'
		--local frob = DreamObjectsAPI.openAuthUrl()

        -- XXX another confirmation we probably don't need
		--local waitForAuthDialogResult = LrDialogs.confirm(
		--	LOC "$$$/DreamObjects/WaitForAuthDialog/Message=Return to this window once you've authorized Lightroom on flickr.com.",
		--	LOC "$$$/DreamObjects/WaitForAuthDialog/HelpText=Once you've granted permission for Lightroom (in your web browser), click the Done button below.",
		--	LOC "$$$/DreamObjects/WaitForAuthDialog/DoneButtonText=Done",
		--	LOC "$$$/LrDialogs/Cancel=Cancel" )

		--if waitForAuthDialogResult == 'cancel' then
		--	return
		--end

		-- User has OK'd authentication. Get the user info.

		propertyTable.accountStatus = LOC "$$$/DreamObjects/AccountStatus/WaitingForDreamObjects=Waiting for response from dreamhost.com..."
        local s3 = require('s3')

        -- set credentials
        s3.AWS_Access_Key_ID =  prefs.apiKey
        s3.AWS_Secret_Key =  prefs.sharedSecret

        -- get the bucket
        local bucket = s3.getBucket(prefs.bucket)
        logger:trace('I think I got a bucket?')
        logger:trace(bucket:list("/", "", 100))
        return


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

function DreamObjectsUser.login( propertyTable )
	if not propertyTable.LR_editingExistingPublishConnection then
		notLoggedIn( propertyTable )
        noBucket( propertyTable )
	end

    require 'DreamObjectsAPI'
    DreamObjectsAPI.showApiKeyDialog()
    propertyTable.validAccount = true

	--doingLogin = false
	--LrFunctionContext.postAsyncTaskWithContext( 'DreamObjects login',
	--function( context )

	--	-- Clear any existing login info, but only if creating new account.
	--	-- If we're here on an existing connection, that's because the login
	--	-- token was rejected. We need to retain existing account info so we
	--	-- can cross-check it.

	--	if not propertyTable.LR_editingExistingPublishConnection then
	--		notLoggedIn( propertyTable )
	--	end

	--	propertyTable.accountStatus = LOC "$$$/DreamObjects/AccountStatus/LoggingIn=Logging in..."
	--	propertyTable.loginButtonEnabled = false

	--	LrDialogs.attachErrorDialogToFunctionContext( context )

	--	-- Make sure login is valid when done, or is marked as invalid.

	--	context:addCleanupHandler( function()

	--		doingLogin = false

	--		if not storedCredentialsAreValid( propertyTable ) then
	--			notLoggedIn( propertyTable )
	--		end

	--		-- Hrm. New API doesn't make it easy to show what operation failed.
	--		-- LrDialogs.message( LOC "$$$/DreamObjects/LoginFailed=Failed to log in." )

	--	end )

	--	-- Make sure we have an API key.

	--	DreamObjectsAPI.getApiKeyAndSecret()

	--	-- Show request for authentication dialog.

	--	local authRequestDialogResult = LrDialogs.confirm(
	--		LOC "$$$/DreamObjects/AuthRequestDialog/Message=Lightroom needs your permission to upload images to DreamObjects.",
	--		LOC "$$$/DreamObjects/AuthRequestDialog/HelpText=If you click Authorize, you will be taken to a web page in your web browser where you can log in. When you're finished, return to Lightroom to complete the authorization.",
	--		LOC "$$$/DreamObjects/AuthRequestDialog/AuthButtonText=Authorize",
	--		LOC "$$$/LrDialogs/Cancel=Cancel" )

	--	if authRequestDialogResult == 'cancel' then
	--		return
	--	end

	--	-- Request the frob that we need for authentication.

	--	propertyTable.accountStatus = LOC "$$$/DreamObjects/AccountStatus/WaitingForDreamObjects=Waiting for response from flickr.com..."

	--	require 'DreamObjectsAPI'
	--	local frob = DreamObjectsAPI.openAuthUrl()

	--	local waitForAuthDialogResult = LrDialogs.confirm(
	--		LOC "$$$/DreamObjects/WaitForAuthDialog/Message=Return to this window once you've authorized Lightroom on flickr.com.",
	--		LOC "$$$/DreamObjects/WaitForAuthDialog/HelpText=Once you've granted permission for Lightroom (in your web browser), click the Done button below.",
	--		LOC "$$$/DreamObjects/WaitForAuthDialog/DoneButtonText=Done",
	--		LOC "$$$/LrDialogs/Cancel=Cancel" )

	--	if waitForAuthDialogResult == 'cancel' then
	--		return
	--	end

	--	-- User has OK'd authentication. Get the user info.

	--	propertyTable.accountStatus = LOC "$$$/DreamObjects/AccountStatus/WaitingForDreamObjects=Waiting for response from flickr.com..."

	--	local data = DreamObjectsAPI.callRestMethod( propertyTable, { method = 'flickr.auth.getToken', frob = frob, suppressError = true, skipAuthToken = true } )

	--	local auth = data.auth

	--	if not auth then
	--		return
	--	end

	--	-- If editing existing connection, make sure user didn't try to change user ID on us.

	--	if propertyTable.LR_editingExistingPublishConnection then

	--		if auth.user and propertyTable.nsid ~= auth.user.nsid then
	--			LrDialogs.message( LOC "$$$/DreamObjects/CantChangeUserID=You can not change DreamObjects accounts on an existing publish connection. Please log in again with the account you used when you first created this connection." )
	--			return
	--		end

	--	end

	--	-- Now we can read the DreamObjects user credentials. Save off to prefs.

	--	propertyTable.nsid = auth.user.nsid
	--	propertyTable.username = auth.user.username
	--	propertyTable.fullname = auth.user.fullname
	--	propertyTable.auth_token = auth.token._value

	--	DreamObjectsUser.updateUserStatusTextBindings( propertyTable )

	--end )

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

function DreamObjectsUser.verifyLogin( propertyTable )

	-- Observe changes to prefs and update status message accordingly.

	local function updateStatus()
		logger:trace( "verifyLogin: updateStatus() was triggered." )

		LrTasks.startAsyncTask( function()
			logger:trace( "verifyLogin: updateStatus() is executing." )
			if storedCredentialsAreValid( propertyTable ) then

				propertyTable.accountStatus = LOC( "$$$/DreamObjects/AccountStatus/LoggedIn=Key pairs stored")

				--if propertyTable.LR_editingExistingPublishConnection then
                propertyTable.loginButtonTitle = LOC "$$$/DreamObjects/LoginButton/LogInAgain=Edit keys"
                propertyTable.loginButtonEnabled = true
                propertyTable.validAccount = true
				--else
				--	propertyTable.loginButtonTitle = LOC "$$$/DreamObjects/LoginButton/LoggedIn=Edit keys?"
				--	propertyTable.loginButtonEnabled = true
				--	propertyTable.validAccount = true
				--end
			else
				notLoggedIn( propertyTable )
			end

            -- If this gets triggered it will take me to FLICKR
			--DreamObjectsUser.updateUserStatusTextBindings( propertyTable )
		end )

	end

	propertyTable:addObserver( 'auth_token', updateStatus )
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

				--if propertyTable.LR_editingExistingPublishConnection then
                propertyTable.bucketNameTitle = LOC "$$$/DreamObjects/BucketButton/EditBucket=Edit bucket"
                propertyTable.validBucket = true
				--else
				--	propertyTable.loginButtonTitle = LOC "$$$/DreamObjects/LoginButton/LoggedIn=Edit keys?"
				--	propertyTable.loginButtonEnabled = true
				--	propertyTable.validAccount = true
				--end
			else
				noBucket( propertyTable )
			end

		end )

	end

	propertyTable:addObserver( 'auth_token', updateStatus )
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
--					settings.loginButtonTitle = LOC "$$$/DreamObjects/LoginButton/LogInAgain=Log In"
--					settings.loginButtonEnabled = true
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
