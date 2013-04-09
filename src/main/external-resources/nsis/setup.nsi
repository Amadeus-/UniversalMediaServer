!include "MUI.nsh"
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "TextFunc.nsh"
!include "WordFunc.nsh"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"

; Include the project header file generated by the nsis-maven-plugin
!include "..\..\..\..\target\project.nsh"
!include "..\..\..\..\target\extra.nsh"

!define REG_KEY_UNINSTALL "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PROJECT_NAME}"
!define REG_KEY_SOFTWARE "SOFTWARE\${PROJECT_NAME}"

RequestExecutionLevel admin

Name "${PROJECT_NAME}"
InstallDir "$PROGRAMFILES\${PROJECT_NAME}"

; Get install folder from registry for updates
InstallDirRegKey HKCU "${REG_KEY_SOFTWARE}" ""

SetCompressor /SOLID lzma
SetCompressorDictSize 32

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\UMS.exe"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\win.bmp"
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE WelcomeLeave

!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Create Desktop Shortcut"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION CreateDesktopShortcut

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
Page Custom LockedListShow LockedListLeave
Page Custom AdvancedSettings AdvancedSettingsAfterwards ; Custom page
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

ShowUninstDetails show

; Offer to install AviSynth 2.6 MT unless installer is in silent mode
Section -Prerequisites

	IfSilent jump_if_silent jump_if_not_silent

	jump_if_not_silent:
		SetRegView 32
		ReadRegStr $0 HKLM Software\Microsoft\Windows\CurrentVersion\Uninstall\AviSynth DisplayVersion

		${If} $0 != "2.6.0 MT"
			SetOutPath $INSTDIR\win32\avisynth
			MessageBox MB_YESNO "AviSynth 2.6 MT is recommended. Install it now?" /SD IDYES IDNO endAviSynthInstall
			File "..\..\..\..\target\bin\win32\avisynth\avisynth.exe"
			ExecWait "$INSTDIR\win32\avisynth\avisynth.exe"
		${EndIf}

	jump_if_silent:

	endAviSynthInstall:

SectionEnd

Function WelcomeLeave
	StrCpy $R1 0
FunctionEnd

Function LockedListShow
	StrCmp $R1 0 +2 ; Skip the page if clicking Back from the next page.
		Abort
	!insertmacro MUI_HEADER_TEXT `UMS must be closed before installation` `Clicking Next will automatically close it.`
	LockedList::AddModule "$INSTDIR\MediaInfo.dll"
	LockedList::Dialog /autonext /autoclosesilent
	Pop $R0
FunctionEnd

Function LockedListLeave
	StrCpy $R1 1
FunctionEnd

Var Dialog
Var Text
Var LabelMemoryLimit
Var DescMemoryLimit
Var CheckboxCleanInstall
Var CheckboxCleanInstallState
Var DescCleanInstall

Function AdvancedSettings
	!insertmacro MUI_HEADER_TEXT "Advanced Settings" "If you don't understand them, don't change them."
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

	${NSD_CreateLabel} 0 0 100% 20u "This allows you to set the Java Heap size limit. If you are not sure what this means, just leave it at 768." 
	Pop $DescMemoryLimit

	${NSD_CreateLabel} 2% 20% 37% 12u "Maximum memory in megabytes"
	Pop $LabelMemoryLimit

	${NSD_CreateText} 3% 30% 10% 12u "768"
	Pop $Text

	${NSD_CreateLabel} 0 50% 100% 20u "This replaces your current configuration and deletes MPlayer's font cache, allowing you to take advantage of improved defaults. This deletes the UMS configuration directory."
	Pop $DescCleanInstall

	${NSD_CreateCheckbox} 3% 65% 100% 12u "Clean install"
	Pop $CheckboxCleanInstall

	nsDialogs::Show
FunctionEnd

Function AdvancedSettingsAfterwards
	${NSD_GetText} $Text $0
	WriteRegStr HKCU "${REG_KEY_SOFTWARE}" "HeapMem" "$0"

	${NSD_GetState} $CheckboxCleanInstall $CheckboxCleanInstallState
	${If} $CheckboxCleanInstallState == ${BST_CHECKED}
		ReadENVStr $R1 ALLUSERSPROFILE
		RMDir /r $R1\UMS
		RMDir /r $TEMP\fontconfig
	${EndIf}
FunctionEnd

Function CreateDesktopShortcut
	CreateShortCut "$DESKTOP\${PROJECT_NAME}.lnk" "$INSTDIR\UMS.exe"
FunctionEnd

Section "Program Files"
	SetOutPath "$INSTDIR"
	SetOverwrite on
	File /r /x "*.conf" /x "*.zip" /x "*.dll" /x "third-party" "${PROJECT_BASEDIR}\src\main\external-resources\plugins"
	File /r "${PROJECT_BASEDIR}\src\main\external-resources\documentation"
	File /r "${PROJECT_BASEDIR}\src\main\external-resources\renderers"
	File /r "${PROJECT_BASEDIR}\target\bin\win32"
	File "${PROJECT_BUILD_DIR}\UMS.exe"
	File "${PROJECT_BASEDIR}\src\main\external-resources\UMS.bat"
	File "${PROJECT_BUILD_DIR}\ums.jar"
	File "${PROJECT_BASEDIR}\MediaInfo.dll"
	File "${PROJECT_BASEDIR}\MediaInfo64.dll"
	File "${PROJECT_BASEDIR}\MediaInfo-License.html"
	File "${PROJECT_BASEDIR}\CHANGELOG.txt"
	File "${PROJECT_BASEDIR}\README.txt"
	File "${PROJECT_BASEDIR}\LICENSE.txt"
	File "${PROJECT_BASEDIR}\src\main\external-resources\logback.xml"
	File "${PROJECT_BASEDIR}\src\main\external-resources\icon.ico"

	CreateDirectory "$INSTDIR\data"

	; The user may have set the installation dir as the profile dir, so we can't clobber this
	SetOverwrite off
	File "${PROJECT_BASEDIR}\src\main\external-resources\UMS.conf"
	File "${PROJECT_BASEDIR}\src\main\external-resources\WEB.conf"
	File "${PROJECT_BASEDIR}\src\main\external-resources\ffmpeg.webfilters"

	; Store install folder
	WriteRegStr HKCU "${REG_KEY_SOFTWARE}" "" $INSTDIR

	; Create uninstaller
	WriteUninstaller "$INSTDIR\uninst.exe"

	WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "DisplayName" "${PROJECT_NAME}"
	WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "DisplayIcon" "$INSTDIR\icon.ico"
	WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "DisplayVersion" "${PROJECT_VERSION}"
	WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "Publisher" "${PROJECT_ORGANIZATION_NAME}"
	WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "URLInfoAbout" "${PROJECT_ORGANIZATION_URL}"
	WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "UninstallString" '"$INSTDIR\uninst.exe"'

	${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
	IntFmt $0 "0x%08X" $0
	WriteRegDWORD HKLM "${REG_KEY_UNINSTALL}" "EstimatedSize" "$0"

	WriteUnInstaller "uninst.exe"

	ReadENVStr $R0 ALLUSERSPROFILE
	SetOutPath "$R0\UMS"
	AccessControl::GrantOnFile "$R0\UMS" "(S-1-5-32-545)" "FullAccess"
	AccessControl::GrantOnFile "$INSTDIR\data" "(BU)" "FullAccess"
	File "${PROJECT_BASEDIR}\src\main\external-resources\UMS.conf"
	File "${PROJECT_BASEDIR}\src\main\external-resources\WEB.conf"
	File "${PROJECT_BASEDIR}\src\main\external-resources\ffmpeg.webfilters"
SectionEnd

Section "Start Menu Shortcuts"
	SetShellVarContext all
	CreateDirectory "$SMPROGRAMS\${PROJECT_NAME}"
	CreateShortCut "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME}.lnk" "$INSTDIR\UMS.exe" "" "$INSTDIR\UMS.exe" 0
	CreateShortCut "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME} (Select Profile).lnk" "$INSTDIR\UMS.exe" "profiles" "$INSTDIR\UMS.exe" 0
	CreateShortCut "$SMPROGRAMS\${PROJECT_NAME}\Uninstall.lnk" "$INSTDIR\uninst.exe" "" "$INSTDIR\uninst.exe" 0

	; Only start UMS with Windows when it is a new install
	IfFileExists "$SMPROGRAMS\${PROJECT_NAME}.lnk" 0 shortcut_file_not_found
		goto end_of_startup_section
	shortcut_file_not_found:
		CreateShortCut "$SMSTARTUP\${PROJECT_NAME}.lnk" "$INSTDIR\UMS.exe" "" "$INSTDIR\UMS.exe" 0
	end_of_startup_section:

	CreateShortCut "$SMPROGRAMS\${PROJECT_NAME}.lnk" "$INSTDIR\UMS.exe" "" "$INSTDIR\UMS.exe" 0
SectionEnd

Section "Uninstall"
	SetShellVarContext all

	Delete /REBOOTOK "$INSTDIR\uninst.exe"
	RMDir /R /REBOOTOK "$INSTDIR\plugins"
	RMDir /R /REBOOTOK "$INSTDIR\renderers"
	RMDir /R /REBOOTOK "$INSTDIR\documentation"
	RMDir /R /REBOOTOK "$INSTDIR\win32"
	RMDir /R /REBOOTOK "$INSTDIR\data"
	Delete /REBOOTOK "$INSTDIR\UMS.exe"
	Delete /REBOOTOK "$INSTDIR\UMS.bat"
	Delete /REBOOTOK "$INSTDIR\ums.jar"
	Delete /REBOOTOK "$INSTDIR\MediaInfo.dll"
	Delete /REBOOTOK "$INSTDIR\MediaInfo64.dll"
	Delete /REBOOTOK "$INSTDIR\MediaInfo-License.html"
	Delete /REBOOTOK "$INSTDIR\CHANGELOG.txt"
	Delete /REBOOTOK "$INSTDIR\WEB.conf"
	Delete /REBOOTOK "$INSTDIR\README.txt"
	Delete /REBOOTOK "$INSTDIR\LICENSE.txt"
	Delete /REBOOTOK "$INSTDIR\debug.log"
	Delete /REBOOTOK "$INSTDIR\logback.xml"
	Delete /REBOOTOK "$INSTDIR\icon.ico"
	RMDir /REBOOTOK "$INSTDIR"

	Delete /REBOOTOK "$DESKTOP\${PROJECT_NAME}.lnk"
	RMDir /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}"
	Delete /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME}.lnk"
	Delete /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME} (Select Profile).lnk"
	Delete /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}\Uninstall.lnk"

	DeleteRegKey HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}"
	DeleteRegKey HKCU "${REG_KEY_SOFTWARE}"

	nsSCM::Stop "${PROJECT_NAME}"
	nsSCM::Remove "${PROJECT_NAME}"
SectionEnd
