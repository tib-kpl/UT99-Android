/*=============================================================================
	FormatWAV.cpp: Unreal audio wav reading code.
	Copyright 1999 Epic Games, Inc. All Rights Reserved.

Revision history:
	* Created by Brandon Reinhart.
=============================================================================*/

/*------------------------------------------------------------------------------------
	Audio includes.
------------------------------------------------------------------------------------*/

#include "AudioPrivate.h"
#if defined(PLATFORM_ANDROID)
#include "SDL_audio.h"
#endif

/*------------------------------------------------------------------------------------
	WAVE management.
------------------------------------------------------------------------------------*/

Sample* LoadWAV( Sample* lSample, MemChunk* Chunk )
{
	WAVFileHeader FileHeader;
	ReadMem(&FileHeader, 1, sizeof(WAVFileHeader), Chunk);
	FileHeader.Size = ((FileHeader.Size+1)&~1);
	FileHeader.Size -= 4;

	WAVChunkHeader		ChunkHeader;
	WAVFormatHeader 	FormatHeader;
	WAVFormatExHeader 	FormatExHeader;
	WAVSampleHeader		SampleHeader;
	while (FileHeader.Size != 0)
	{
		if (ReadMem(&ChunkHeader, 1, sizeof(WAVChunkHeader), Chunk))
		{
			if (!appMemcmp(ChunkHeader.ID, "fmt ", 4))
			{
				ReadMem(&FormatHeader, 1, sizeof(WAVFormatHeader), Chunk);
				if (FormatHeader.Format != 0x0001)
				{
					ReadMem(&FormatExHeader, 1, sizeof(WAVFormatExHeader), Chunk);
					SeekMem(Chunk, ChunkHeader.Size - sizeof(WAVFormatHeader) - sizeof(WAVFormatExHeader), MEM_SEEK_CUR);
				} else
					SeekMem(Chunk, ChunkHeader.Size - sizeof(WAVFormatHeader), MEM_SEEK_CUR);
			}
			else if (!appMemcmp(ChunkHeader.ID, "data", 4))
			{
				if (FormatHeader.Format == 0x0001)
				{
					lSample->Size = sizeof(lSample);
					lSample->Panning = AUDIO_MIDPAN;
					lSample->Volume = AUDIO_MAXVOLUME;
					if (FormatHeader.Channels == 2)
						lSample->Type = SAMPLE_STEREO;
					else
						lSample->Type = SAMPLE_MONO;
					if (FormatHeader.BitsPerSample == 16)
						lSample->Type |= SAMPLE_16BIT;
					else
						lSample->Type |= SAMPLE_8BIT;
					lSample->Length = (ChunkHeader.Size / FormatHeader.BlockAlign);
					lSample->LoopStart = 0;
					lSample->LoopEnd = 0;
					lSample->SamplesPerSec = FormatHeader.SamplesPerSec;
					if ((lSample->SamplesPerSec != 11025) && (lSample->SamplesPerSec != 22050) && (lSample->SamplesPerSec != 44100)
#if defined(PLATFORM_ANDROID)
					    && (lSample->SamplesPerSec < 8000 || lSample->SamplesPerSec > 192000)
#endif
					)
						appErrorf( TEXT("Unsupported rate: %i"), lSample->SamplesPerSec );
					if (lSample->Data = appMalloc(ChunkHeader.Size, TEXT("Sample data.")))
						ReadMem(lSample->Data, FormatHeader.BlockAlign, lSample->Length, Chunk);
				} else {
					appErrorf( TEXT("Unsupported WAVE format!") );
					SeekMem(Chunk, ChunkHeader.Size, MEM_SEEK_CUR);
				}
			}
			else if (!appMemcmp(ChunkHeader.ID, "smpl", 4))
			{
				ReadMem(&SampleHeader, 1, sizeof(WAVSampleHeader), Chunk);
				SeekMem(Chunk, ChunkHeader.Size - sizeof(WAVSampleHeader), MEM_SEEK_CUR);
				if (SampleHeader.Loops != 0)
				{
					if (SampleHeader.Loop[0].Type & 1)
						lSample->Type |= SAMPLE_BIDILOOP | SAMPLE_LOOPED;
					else
						lSample->Type |= SAMPLE_LOOPED;
					lSample->LoopStart = SampleHeader.Loop[0].Start;
					lSample->LoopEnd = SampleHeader.Loop[0].End;
				}
			}
			else
				// Move past this chunk. 
				SeekMem(Chunk, ChunkHeader.Size, MEM_SEEK_CUR);
				
			SeekMem(Chunk, ChunkHeader.Size & 1, MEM_SEEK_CUR);
			FileHeader.Size -= (((ChunkHeader.Size+1)&~1)+8);
		}
	}
#if defined(PLATFORM_ANDROID)
	// Bonus-pack sounds also use 16 kHz PCM. The legacy mixer accepts only
	// 11025/22050/44100 Hz; resample once at load time, including loop points.
	if( lSample->Data && lSample->SamplesPerSec!=11025
	&& lSample->SamplesPerSec!=22050 && lSample->SamplesPerSec!=44100 )
	{
		INT OldRate=lSample->SamplesPerSec;
		INT NewRate=OldRate<=22050 ? 22050 : 44100;
		INT Channels=(lSample->Type&SAMPLE_STEREO) ? 2 : 1;
		INT Bytes=(lSample->Type&SAMPLE_16BIT) ? 2 : 1;
		SDL_AudioFormat Format=Bytes==2 ? AUDIO_S16LSB : AUDIO_U8;
		SDL_AudioCVT Conversion;
		if( SDL_BuildAudioCVT(&Conversion,Format,Channels,OldRate,Format,Channels,NewRate)<0
		|| lSample->Length > 0x7fffffff/(Channels*Bytes*Max(1,Conversion.len_mult)) )
			appErrorf(TEXT("Unable to resample PCM sound at %i Hz"),OldRate);
		Conversion.len=lSample->Length*Channels*Bytes;
		Conversion.buf=(Uint8*)appMalloc(Conversion.len*Conversion.len_mult,TEXT("Resampled PCM"));
		appMemcpy(Conversion.buf,lSample->Data,Conversion.len);
		if( SDL_ConvertAudio(&Conversion)<0 )
			appErrorf(TEXT("Unable to convert PCM sound at %i Hz"),OldRate);
		appFree(lSample->Data);
		lSample->Data=Conversion.buf;
		lSample->Length=Conversion.len_cvt/(Channels*Bytes);
		lSample->LoopStart=Min(lSample->Length,(DWORD)((double)lSample->LoopStart*NewRate/OldRate));
		lSample->LoopEnd=Min(lSample->Length,(DWORD)((double)lSample->LoopEnd*NewRate/OldRate));
		lSample->SamplesPerSec=NewRate;
		debugf(NAME_Log,TEXT("Android audio: resampled PCM from %i to %i Hz"),OldRate,NewRate);
	}
#endif
	return lSample;
}

