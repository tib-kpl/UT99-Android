/*=============================================================================
	UnPenLev.cpp: Unreal pending level class.
	Copyright 1997-1999 Epic Games, Inc. All Rights Reserved.

	Revision history:
		* Created by Tim Sweeney
=============================================================================*/

#include "EnginePrivate.h"
#include "UnNet.h"
#if defined(PLATFORM_ANDROID)
extern "C" int UT99AndroidRedirectStart(const char*,const char*,int,int);
extern "C" int UT99AndroidRedirectPoll(int);
extern "C" void UT99AndroidRedirectCancel();
#endif

/*-----------------------------------------------------------------------------
	UPendingLevel implementation.
-----------------------------------------------------------------------------*/

//
// Constructor.
//
UPendingLevel::UPendingLevel( UEngine* InEngine, const FURL& InURL )
:	ULevelBase( InEngine, InURL )
{}
IMPLEMENT_CLASS(UPendingLevel);


/*-----------------------------------------------------------------------------
	UNetPendingLevel implementation.
-----------------------------------------------------------------------------*/

//
// Constructor.
//
UNetPendingLevel::UNetPendingLevel( UEngine* InEngine, const FURL& InURL )
:	UPendingLevel( InEngine, InURL )
{
	guard(UNetPendingLevel::UNetPendingLevel);

	// Init.
	Error     = TEXT("");
	NetDriver = NULL;
#if defined(PLATFORM_ANDROID)
	RedirectPackage = INDEX_NONE;
#endif

	// Try to create network driver.
	UClass* NetDriverClass = StaticLoadClass( UNetDriver::StaticClass(), NULL, TEXT("ini:Engine.Engine.NetworkDevice"), NULL, LOAD_NoFail, NULL );
	NetDriver = ConstructObject<UNetDriver>( NetDriverClass );
	if( NetDriver->InitConnect( this, URL, Error ) )
	{
		// Send initial message.
		INT AdvertisedVersion = ENGINE_CLIENT_NETWORK_VERSION;
#if defined(__ANDROID__) || defined(PLATFORM_ANDROID)
		debugf(NAME_Log, TEXT("AndroidNet: connecting with advertised version %i"), AdvertisedVersion);
#endif
		NetDriver->ServerConnection->Logf( TEXT("HELLO REVISION=0 MINVER=%i VER=%i"), ENGINE_MIN_NET_VERSION, AdvertisedVersion );
		NetDriver->ServerConnection->FlushNet();
	}
	else
	{
		delete NetDriver;
		NetDriver=NULL;
	}
	unguard;
}

//
// FNetworkNotify interface.
//
EAcceptConnection UNetPendingLevel::NotifyAcceptingConnection()
{
	guard(UNetPendingLevel::NotifyAcceptingConnection);
	return ACCEPTC_Reject;
	unguard;
}
void UNetPendingLevel::NotifyAcceptedConnection( class UNetConnection* Connection )
{
	guard(UNetPendingLevel::NotifyAcceptedConnection);
	unguard;
}
UBOOL UNetPendingLevel::NotifyAcceptingChannel( class UChannel* Channel )
{
	guard(UNetPendingLevel::NotifyAcceptingChannel);
	return 0;
	unguard;
}
ULevel* UNetPendingLevel::NotifyGetLevel()
{
	guard(UNetPendingLevel::NotifyGetLevel);
	return NULL;
	unguard;
}
void UNetPendingLevel::NotifyReceivedText( UNetConnection* Connection, const TCHAR* Text )
{
	guard(UNetPendingLevel::NotifyReceivedText);
	check(Connection==NetDriver->ServerConnection);
	debugf( NAME_DevNet, TEXT("PendingLevel received: %s"), Text );

	// This client got a response from the server.
	if( ParseCommand(&Text,TEXT("UPGRADE")) )
	{
		// Report mismatch.
		INT RemoteMinVer=0, RemoteVer=0;
		Parse( Text, TEXT("MINVER="), RemoteMinVer );
		Parse( Text, TEXT("VER="),    RemoteVer    );
#if defined(__ANDROID__) || defined(PLATFORM_ANDROID)
		Error = FString::Printf(TEXT("Incompatible network version: server %i, minimum %i."), RemoteVer, RemoteMinVer);
		Connection->State = USOCK_Closed;
		return;
#endif
		if( ENGINE_VERSION < RemoteMinVer )
		{
			// Upgrade message.
			Engine->SetProgress( TEXT(""), TEXT(""), -1.0 );
		}
		else
		{
			// Downgrade message.
			Engine->SetProgress( LocalizeError("ConnectionFailed"), LocalizeError("ServerOutdated"), 6.0 );//!!localize
		}
	}
	else if( ParseCommand(&Text,TEXT("FAILURE")) )
	{
		// Report problem to user.
#if defined(__ANDROID__) || defined(PLATFORM_ANDROID)
		Error = Text;
		Connection->State = USOCK_Closed;
#endif
		Engine->SetProgress( TEXT("Rejected By Server"), Text, 10.0 );
	}
	else if( ParseCommand(&Text,TEXT("FAILCODE")) )
	{
		// Notify console.
		if( Engine->Client &&
			Engine->Client->Viewports(0) &&
			Engine->Client->Viewports(0)->Console )
		{
			FURL NewURL(URL);

			for( INT i=NewURL.Op.Num()-1; i>=0; i-- )
				if( NewURL.Op(i).Left(9).Caps() ==TEXT("PASSWORD=") )
					NewURL.Op.Remove( i );

			Engine->Client->Viewports(0)->Console->eventConnectFailure( Text, *NewURL.String() );
		}
	}
	else if( ParseCommand( &Text, TEXT("USES") ) )
	{
		// Dependency information.
		FPackageInfo& Info = *new(Connection->PackageMap->List)FPackageInfo(NULL);
		TCHAR PackageName[NAME_SIZE]=TEXT("");
		Parse( Text, TEXT("GUID=" ), Info.Guid );
		Parse( Text, TEXT("GEN=" ),  Info.RemoteGeneration );
		Parse( Text, TEXT("SIZE="),  Info.FileSize );
		Parse( Text, TEXT("FLAGS="), Info.PackageFlags );
		Parse( Text, TEXT("PKG="), PackageName, ARRAY_COUNT(PackageName) );
		Info.Parent = CreatePackage(NULL,PackageName);
#if defined(PLATFORM_ANDROID)
		TCHAR Filename[256]=TEXT("");
		Parse(Text,TEXT("FNAME="),Filename,ARRAY_COUNT(Filename));
		new(RedirectNames)FString(Filename);
#endif
	}
	else if( ParseCommand(&Text,TEXT("DLMGR")) )
	{
#if defined(PLATFORM_ANDROID)
		TCHAR ClassName[128]=TEXT(""), Params[2048]=TEXT("");
		Parse(Text,TEXT("CLASS="),ClassName,ARRAY_COUNT(ClassName));
		Parse(Text,TEXT("PARAMS="),Params,ARRAY_COUNT(Params));
		if( !RedirectURL.Len() && appStricmp(ClassName,TEXT("IpDrv.HTTPDownload"))==0
		&& (appStrnicmp(Params,TEXT("http://"),7)==0 || appStrnicmp(Params,TEXT("https://"),8)==0) )
		{
			RedirectURL=Params;
			ParseUBOOL(Text,TEXT("COMPRESSION="),RedirectCompressed);
		}
#endif
	}
	else if( ParseCommand(&Text,TEXT("USERFLAG")) )
	{
		Connection->UserFlags = appAtoi(Text);
	}
	else if( ParseCommand( &Text, TEXT("CHALLENGE") ) )
	{
		// Challenged by server.
		INT RemoteStats = 0, i=0;
		Parse( Text, TEXT("VER="), Connection->NegotiatedVer );
#if defined(__ANDROID__) || defined(PLATFORM_ANDROID)
		if( Connection->NegotiatedVer < ENGINE_MIN_NET_VERSION || Connection->NegotiatedVer > ENGINE_CLIENT_NETWORK_VERSION )
		{
			Error = FString::Printf(TEXT("Unsupported negotiated network version %i."), Connection->NegotiatedVer);
			Connection->State = USOCK_Closed;
			return;
		}
#endif
		Parse( Text, TEXT("CHALLENGE="), Connection->Challenge );

		Parse( Text, TEXT("STATS="), RemoteStats );
		if (RemoteStats == 1)
		{
			// Get the Player Pawn.
			APlayerPawn* PlayerPawn = Engine->Client->Viewports(0)->Actor;

			// Calculate the player's checksum for ngWorldStats.
			FString URLOption;
			if (PlayerPawn->ngWorldSecret == TEXT(""))
			{
				URLOption += FString::Printf( TEXT("Checksum=NoChecksum") );
			} else {
				FMD5Context PContext;
				appMD5Init( &PContext );
				appMD5Update( &PContext, (BYTE*)*(PlayerPawn->PlayerReplicationInfo->PlayerName), PlayerPawn->PlayerReplicationInfo->PlayerName.Len()*sizeof(TCHAR) );
				appMD5Update( &PContext, (BYTE*)*(PlayerPawn->ngWorldSecret), PlayerPawn->ngWorldSecret.Len()*sizeof(TCHAR) );
				BYTE Digest[16];
				appMD5Final( Digest, &PContext );
				URLOption += FString::Printf( TEXT("Checksum=") );
				for (i=0; i<16; i++)
					URLOption += FString::Printf(TEXT("%02x"), Digest[i]);
			}
			URL.AddOption( *URLOption );
		}

		FURL PartialURL(URL);
		PartialURL.Host = TEXT("");
		for( i=URL.Op.Num()-1; i>=0; i-- )
			if( URL.Op(i).Left(5)==TEXT("game=") )
				URL.Op.Remove( i );
		NetDriver->ServerConnection->Logf( TEXT("NETSPEED %i"), Connection->CurrentNetSpeed );
		NetDriver->ServerConnection->Logf( TEXT("LOGIN RESPONSE=%i URL=%s"), Engine->ChallengeResponse(Connection->Challenge), *PartialURL.String() );
		NetDriver->ServerConnection->FlushNet();
	}
	else if( ParseCommand( &Text, TEXT("WELCOME") ) )
	{
		// Server accepted connection.
		debugf( NAME_DevNet, TEXT("Welcomed by server: %s"), Text );

		// Parse welcome message.
		Parse( Text, TEXT("LEVEL="), URL.Map );
		ParseUBOOL( Text, TEXT("LONE="), LonePlayer );
		Parse( Text, TEXT("CHALLENGE="), Connection->Challenge );

		// Make sure all packages we need are downloadable.
		for( INT i=0; i<Connection->PackageMap->List.Num(); i++ )
		{
			TCHAR Filename[256];
			FPackageInfo& Info = Connection->PackageMap->List(i);
			if( !appFindPackageFile( Info.Parent->GetName(), &Info.Guid, Filename ) )
			{
				appSprintf( Filename, TEXT("%s%s"), Info.Parent->GetName(), DLLEXT );
				if( GFileManager->FileSize(Filename) <= 0 )
				{
					// We need to download this package.
					FilesNeeded++;
					Info.PackageFlags |= PKG_Need;
					if( !NetDriver->AllowDownloads || !(Info.PackageFlags & PKG_AllowDownload) )
					{
						Error = FString::Printf( TEXT("Downloading '%s' not allowed"), Info.Parent->GetName() );
						NetDriver->ServerConnection->State = USOCK_Closed;
						return;
					}
				}
			}
		}

		// Send first download request.
		for( INT i=0; i<Connection->PackageMap->List.Num(); i++ )
			if( Connection->PackageMap->List(i).PackageFlags & PKG_Need )
				{
#if defined(PLATFORM_ANDROID)
					ReceivePackage(i);
#else
					Connection->ReceiveFile(i);
#endif
					break;
				}

		// We have successfully connected.
		Success = 1;
	}
	else
	{
		// Other command.
	}
	unguard;
}
void UNetPendingLevel::NotifyReceivedFile( UNetConnection* Connection, INT PackageIndex, const TCHAR* InError )
{
	guard(UNetPendingLevel::NotifyReceivedFile);
	check(Connection->PackageMap->List.IsValidIndex(PackageIndex));

	// Map pack to package.
	FPackageInfo& Info = Connection->PackageMap->List(PackageIndex);
	if( *InError )
	{
		// If transfer failed, so propagate error.
		if( Error==TEXT("") )
			Error = FString::Printf( LocalizeError("DownloadFailed"), Info.Parent->GetName(), InError );
	}
	else
	{
		// Now that a file has been successfully received, mark its package as downloaded.
		check(Connection==NetDriver->ServerConnection);
		check(Info.PackageFlags&PKG_Need);
		Info.PackageFlags &= ~PKG_Need;
		FilesNeeded--;

		// Send next download request.
		for( INT i=0; i<Connection->PackageMap->List.Num(); i++ )
			if( Connection->PackageMap->List(i).PackageFlags & PKG_Need )
				{
#if defined(PLATFORM_ANDROID)
					ReceivePackage(i);
#else
					Connection->ReceiveFile(i);
#endif
					break;
				}
	}
	unguard;
}
UBOOL UNetPendingLevel::NotifySendingFile( UNetConnection* Connection, FGuid Guid )
{
	guard(UNetPendingLevel::NotifySendingFile);

	// Server has requested a file from this client.
	debugf( NAME_DevNet, LocalizeError("RequestDenied") );
	return 0;

	unguard;
}

//
// Update the pending level's status.
//
void UNetPendingLevel::Tick( FLOAT DeltaTime )
{
	guard(UNetPendingLevel::Tick);
	check(NetDriver);
	check(NetDriver->ServerConnection);

	// Handle timed out or failed connection.
	if( NetDriver->ServerConnection->State==USOCK_Closed && Error==TEXT("") )
	{
		Error = LocalizeError("ConnectionFailed");
		return;
	}

	// Update network driver.
	NetDriver->TickDispatch( DeltaTime );
#if defined(PLATFORM_ANDROID)
	TickRedirect(DeltaTime);
#endif
	NetDriver->TickFlush();

	unguard;
}
//
// Send JOIN to other end
//
void UNetPendingLevel::SendJoin()
{
	guard(UNetPendingLevel::SendJoin);
	SentJoin = 1;
	NetDriver->ServerConnection->Logf( TEXT("JOIN") );
	NetDriver->ServerConnection->FlushNet();
	unguard;
}
IMPLEMENT_CLASS(UNetPendingLevel);

#if defined(PLATFORM_ANDROID)
void UNetPendingLevel::ReceivePackage(INT Index)
{
	FPackageInfo& Info=NetDriver->ServerConnection->PackageMap->List(Index);
	if( RedirectURL.Len() && RedirectNames.IsValidIndex(Index) && RedirectNames(Index).Len()
	&& Info.FileSize>0 && Info.FileSize<=256*1024*1024 )
	{
		FString Name=RedirectNames(Index), Escaped;
		UBOOL Safe=Name.Len()<256;
		for(INT i=0; i<Name.Len(); i++)
		{
			BYTE C=(BYTE)(*Name)[i];
			if(C=='/' || C=='\\' || C==':' || C<32) Safe=0;
			if((C>='a'&&C<='z') || (C>='A'&&C<='Z') || (C>='0'&&C<='9') || C=='-' || C=='_' || C=='.')
				Escaped+=FString::Printf(TEXT("%c"),C);
			else Escaped+=FString::Printf(TEXT("%%%02X"),C);
		}
		TCHAR Temp[256];
		FString TempDirectory=GSys->CachePath+PATH_SEPARATOR;
		appCreateTempFilename(*TempDirectory,Temp);
		RedirectTemp=Temp;
		FString Address=RedirectURL;
		if(Address.Right(1)!=TEXT("/")) Address+=TEXT("/");
		Address+=Escaped;
		if(RedirectCompressed) Address+=TEXT(".uz");
		if(Safe && UT99AndroidRedirectStart(TCHAR_TO_ANSI(*Address),TCHAR_TO_ANSI(*RedirectTemp),Info.FileSize,RedirectCompressed))
		{
			RedirectPackage=Index;
			RedirectClock=0;
			RedirectStarted=appSeconds();
			debugf(NAME_Log,TEXT("Android download: HTTP start package=%s compressed=%i"),Info.Parent->GetName(),RedirectCompressed);
			return;
		}
	}
	NetDriver->ServerConnection->ReceiveFile(Index);
}

void UNetPendingLevel::TickRedirect(FLOAT DeltaTime)
{
	if(RedirectPackage==INDEX_NONE) return;
	INT Status=UT99AndroidRedirectPoll(0);
	RedirectClock+=DeltaTime;
	if(Status==0 && appSeconds()-RedirectStarted<180.0)
	{
		if(RedirectClock>0.25)
		{
			RedirectClock=0;
			FPackageInfo& Info=NetDriver->ServerConnection->PackageMap->List(RedirectPackage);
			// Compressed redirects transfer .uz bytes, not the expanded package size.
			INT Received=Max(0,UT99AndroidRedirectPoll(1));
			INT Total=UT99AndroidRedirectPoll(2);
			FString Progress=Total>0
				? FString::Printf(TEXT("%s - HTTP: %.0f%% (%.2f / %.2f MB)"),Info.Parent->GetName(),Clamp(100.0*Received/Total,0.0,100.0),Received/1048576.0,Total/1048576.0)
				: FString::Printf(TEXT("%s - HTTP: %.2f MB"),Info.Parent->GetName(),Received/1048576.0);
			NotifyProgress(TEXT("Downloading"),*Progress,1.0);
		}
		return;
	}
	INT Index=RedirectPackage;
	RedirectPackage=INDEX_NONE;
	FPackageInfo& Info=NetDriver->ServerConnection->PackageMap->List(Index);
	UBOOL Valid=0;
	if(Status==1 && GFileManager->FileSize(*RedirectTemp)==Info.FileSize)
	{
		FArchive* Reader=GFileManager->CreateFileReader(*RedirectTemp);
		if(Reader && Reader->TotalSize()>=52)
		{
			DWORD Tag=0, Version=0;
			FGuid Guid;
			*Reader << Tag << Version;
			Reader->Seek(36);
			*Reader << Guid;
			Valid=!Reader->IsError() && Tag==PACKAGE_FILE_TAG && (Version>>16)==0 && (Version&65535)>=68 && (Version&65535)<=69 && Guid==Info.Guid;
		}
		delete Reader;
	}
	if(Valid)
	{
		FString Dest=FString::Printf(TEXT("%s") PATH_SEPARATOR TEXT("%s.uxx"),*GSys->CachePath,Info.Guid.String());
		Valid=GFileManager->Move(*Dest,*RedirectTemp);
	}
	UT99AndroidRedirectCancel();
	if(Valid)
	{
		debugf(NAME_Log,TEXT("Android download: HTTP complete package=%s bytes=%i seconds=%.3f"),Info.Parent->GetName(),Info.FileSize,appSeconds()-RedirectStarted);
		NotifyReceivedFile(NetDriver->ServerConnection,Index,TEXT(""));
	}
	else
	{
		GFileManager->Delete(*RedirectTemp);
		debugf(NAME_Log,TEXT("Android download: HTTP unavailable or invalid package=%s; using file channel"),Info.Parent->GetName());
		NetDriver->ServerConnection->ReceiveFile(Index);
	}
}

void UNetPendingLevel::Destroy()
{
	if(RedirectPackage!=INDEX_NONE) UT99AndroidRedirectCancel();
	Super::Destroy();
}
#endif

/*-----------------------------------------------------------------------------
	The End.
-----------------------------------------------------------------------------*/
