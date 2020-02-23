SetCompressor lzma

!define FULLNAME "VirtIO Balloon Service"
!define COMPACTNAME "VirtIOBalloonService"

!ifndef VERSION
!error "-DVERSION=<version> should be passed to makensis"
!endif

!define UNINSTALLER "Uninstall-${COMPACTNAME}.exe"

!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

Name "${FULLNAME}"
Caption "${FULLNAME} Installer"
OutFile "${COMPACTNAME}-${VERSION}.exe"
InstallDir "$PROGRAMFILES64\${COMPACTNAME}"

# SilentInstall silent
ShowInstDetails show
ShowUninstDetails show

!include "MUI2.nsh"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH
!insertmacro MUI_LANGUAGE "English"

XPStyle on
RequestExecutionLevel admin

Section "install"
  SectionIn RO

  SetOutPath "$INSTDIR"
  WriteUninstaller "$INSTDIR\${UNINSTALLER}"
  IfErrors 0 +3
    DetailPrint "'WriteUninstaller' failed!"
    Goto do_abort

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPACTNAME}" "UninstallString" "$\"$INSTDIR\${UNINSTALLER}$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPACTNAME}" "DisplayName" "${FULLNAME} ${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPACTNAME}" "DisplayVersion" "${VERSION}"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPACTNAME}" "NoModify" "1"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPACTNAME}" "NoRepair" "1"
  IfErrors 0 +3
    DetailPrint "'WriteReg*' failed!"
    Goto do_rollback

  File "blnsvr.exe"
  IfErrors 0 +3
    DetailPrint "File extracting failed!"
    Goto do_rollback

  ExecWait '"$INSTDIR\blnsvr.exe" -i'
  IfErrors 0 +3
    DetailPrint "'blnsvr -i' failed!"
    Goto do_rollback

  Return

do_rollback:
  DetailPrint "Invoking uninstaller..."
  Exec "$INSTDIR\${UNINSTALLER}"
do_abort:
  Abort "Aborting..."
SectionEnd

Section "Uninstall"
  DetailPrint "Uninstalling BalloonService..."
  ExecWait '"$INSTDIR\blnsvr.exe" -u'
  IfErrors 0 +3
    DetailPrint "'blnsvr -u' failed!"
    MessageBox MB_ICONEXCLAMATION|MB_YESNO|MB_DEFBUTTON2 "Continue?" IDNO do_abort

  SetOutPath "$TEMP"

  Delete /rebootok "$INSTDIR\blnsvr.exe"
  IfErrors 0 +3
    DetailPrint "Removing files failed!"
    MessageBox MB_ICONEXCLAMATION|MB_YESNO|MB_DEFBUTTON2 "Continue?" IDNO do_abort

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPACTNAME}"
  IfErrors 0 +3
    DetailPrint "'DeleteRegKey' failed!"
    MessageBox MB_ICONEXCLAMATION|MB_YESNO|MB_DEFBUTTON2 "Continue?" IDNO do_abort

  Delete /rebootok "$INSTDIR\${UNINSTALLER}"
  RMDir /rebootok "$INSTDIR"

  Return

do_abort:
  Abort "Aborting..."
SectionEnd

