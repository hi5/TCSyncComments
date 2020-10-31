#NoEnv
SetBatchLines, -1

/*

TC Button bar/start menu/user-defined command
Command    TCSyncComments.ahk 
Parameters %T %P %S

%T inserts the current target path.
%P causes the source path to be inserted into the command line, including a backslash (\) at the end.
%S insert the names of all selected files into the command line.
   Names containing spaces will be surrounded by double quotes.
   Please note the maximum command line length of 32767 characters.

TODO:
[ ] Check file encoding of descript.ion (utf-8/16,locale) from TC ini ??

*/

PathRead :=A_Args[1] "descript.ion" ; folder to read descript.ion from
PathWrite:=A_Args[2] "descript.ion" ; folder to write/update descript.ion to 
PathWriteStartup:=PathWrite
AppTitle:="TC Sync Comments - v1.0"

ini:=A_ScriptDir "\TCSyncComments.ini"

dpifactor:=A_ScreenDPI/96

EnvGet, Commander_Path, Commander_Path

If (Commander_Path = "") ; try to read registry
	 RegRead Commander_Path, HKEY_CURRENT_USER, Software\Ghisler\Total Commander, InstallDir

;FileEncoding, cp0

IniRead, X        , %ini%, Position, X        , 100
IniRead, Y        , %ini%, Position, Y        , 100
IniRead, W        , %ini%, Position, W        , 790
IniRead, H        , %ini%, Position, H        , 440
IniRead, Exact    , %ini%, Settings, Exact    , 1
IniRead, Skip     , %ini%, Settings, Skip     , 1
IniRead, Backup   , %ini%, Settings, Backup   , 0
IniRead, Replace  , %ini%, Settings, Replace  , 0
IniRead, Hidden   , %ini%, Settings, Hidden   , 0
IniRead, FCurrent , %ini%, Settings, FCurrent , 0
IniRead, FTarget  , %ini%, Settings, FTarget  , 0
IniRead, FAllFiles, %ini%, Settings, FAllFiles, 0

IniRead, IconFile  , %ini%, Settings, IconFile, \WCMICONS.DLL
IniRead, DescIcon  , %ini%, Settings, DescIcon, 29
IniRead, FileIcon  , %ini%, Settings, FileIcon, 63
IniRead, FolderIcon, %ini%, Settings, FolderIcon, 36

IconFile:=Commander_Path IconFile

IfNotExist, %IconFile%
	{
	 IconFile:=Commander_Path "\WCMICONS.DLL"
	 DescIcon  :=29
	 FileIcon  :=63
	 FolderIcon:=36
	}

Try
	Menu, Tray, Icon, %IconFile%, %DescIcon%

If (PathRead = PathWrite)
	FCurrent:=1

Gosub, BuildFiles
Gosub, BuildSourceFiles
Gosub, BuildTargetFiles

Gui, Browse:+Resize MinSize850x200
Gui, Browse:font, s8 Arial bold

Try
	Gui, Browse:Add, Picture , x10 y2 Icon%FileIcon%, %IconFile%
Gui, Browse:Add, Text    , xp+40 y1  w70 h20                    , Match files:
Gui, Browse:font
Gui, Browse:font, s8 Arial
Gui, Browse:Add, Radio   , xp yp+20  w50 vExact gUpdateListview , E&xact
Gui, Browse:Add, Radio   , xp+55 yp-6 w80 vSift gUpdateListview , &SIFT (Ngram)
Gui, Browse:Add, Checkbox, xp+90 yp+6     vSkip gUpdateListview , Skip identic&al

;Gui, Browse:Add, Groupbox, xp+100 yp-6 w1 h20
Gui, Browse:font, c0xcccccc s20
Gui, Browse:Add, Text, xp+80 yp-20, |
Gui, Browse:font,
Gui, Browse:font, s8 Arial bold

Try
	Gui, Browse:Add, Picture , xp+10  y2 Icon%DescIcon%, %IconFile%
Gui, Browse:Add, Text    , xp+40  y1 h20           , descript.ion:
Gui, Browse:font
Gui, Browse:font, s8 Arial 
Gui, Browse:Add, Checkbox, xp     yp+20      vReplace, &Replace comments
Gui, Browse:Add, Checkbox, xp+120 yp         vBackup , &Backup (bak)
Gui, Browse:Add, Checkbox, xp+95  yp         vHidden , Keep &hidden
Gui, Browse:font, c0xcccccc s20
Gui, Browse:Add, Text, xp+80 yp-20, |
Gui, Browse:font,

Gui, Browse:font, s8 Arial bold

Try
	Gui, Browse:Add, Picture , xp+10  y2 Icon%FolderIcon%, %IconFile%
Gui, Browse:Add, Text    , xp+40  y1 h20           , Folder:
Gui, Browse:font
Gui, Browse:font, s8 Arial
Gui, Browse:Add, Radio, xp    yp+20      vFCurrent  gFolder , &Current
Gui, Browse:Add, Radio, xp+65 yp         vFTarget   gFolder , &Target
Gui, Browse:Add, Checkbox, xp+65  yp     vFAllFiles gFolder , All files
Gui, Browse:font

Gui, Browse:font, s10 Arial 

Gui, Browse:Add, Text, x10 yp+25 vSourceTarget, Source:`t%PathRead%`nTarget:`t%PathWrite%

If Exact
	GuiControl, Browse:, Exact, 1
else
	GuiControl, Browse:, Sift, 1

If Skip
	GuiControl, Browse:, Skip, 1
If Backup
	GuiControl, Browse:, Backup, 1
If Replace
	GuiControl, Browse:, Replace, 1
If Hidden
	GuiControl, Browse:, Hidden, 1
If FCurrent
	GuiControl, Browse:, FCurrent, 1
If FTarget
	GuiControl, Browse:, FTarget, 1
If FAllFiles
	GuiControl, Browse:, FAllFiles, 1

Gui, Browse:font, s10 Arial

Gui, Browse:Add, Listview    , % "x10 yp+40 grid Checked gEditComment hwndHLV vLV w" W-20 " h" H-120 , File|Match|Comment to: [%PathWrite%]
CLV := New LV_Colors(HLV)

Gui, Browse:font, s8 Arial

Gui, Browse:Add, Button, % "x" W-113 "        h23 vCopyB   gCopySelectedComments", F5 Copy Comments
Gui, Browse:Add, Button, % "x" W-190 " yp w70 h23 vCancelB gBrowseGuiClose"      , Cancel
Gui, Browse:Add, Button, % "x" W-267 " yp w70 h23 vHelpB   gHelp"                , Help
Gui, Browse:Add, Button, x10 yp           w70 h23 vEditB   gEditComment          , F4 Edit
Gui, Browse:Add, Button, xp+80 yp         w70 h23 vDelB    gDeleteComment        , F8 Del

Gosub, UpdateListview
If (X = 100) and (Y = 100)
	Gui, Browse:Show, w%W% h%H%, %AppTitle%
else
	Gui, Browse:Show, w%W% h%H% x%X% y%Y%, %AppTitle%
Return

Help:
IfExist, %A_ScriptDir%\readme.md
	Run notepad "%A_ScriptDir%\readme.md"
Else
	{
	 MsgBox,36, %AppTitle%: View help online?, %A_ScriptDir%\readme.md not found.`nVisit Github repository to view help?
	 IfMsgBox, Yes
		Run https://github.com/hi5/TCSyncComments/blob/master/readme.md
	}
Return

BuildFiles:
Files:=[]             ; file(s) to process 
if !FAllFiles
	{
	 for n, param in A_Args
		{
		 if n in 1,2      ; skip target/source paths
			continue
		 Files.Push(param)
		}
	}

If !Files.Length()
	Loop, Files, *.*, F
		{
		 If (A_LoopFileName = "descript.ion") or (A_LoopFileName = "descript.ion.bak")
			Continue
		 Files.Push(A_LoopFileName)
		}
Return

BuildSourceFiles:
FileRead, SourceDescription, %PathRead%

if (errorlevel <> 0)
	{
	 Gui +OwnDialogs
	 Gui Show
	 If (errorLevel = 1)
		MsgBox, 48, %AppTitle%: Error, %PathRead% does not exist.`nClosing %AppTitle%
	 If (errorLevel = 2)
		MsgBox, 48, %AppTitle%: Error, %PathRead% is locked or inaccessible.`nClosing %AppTitle%
	 If (errorLevel = 3)
		MsgBox, 48, %AppTitle%: Error, The system lacks sufficient memory to load the file.`nClosing %AppTitle%
	 ExitApp
	}

SourceFiles:=[]
SourceFilesIndex:=[]
SourceFilesList:=""
Loop, parse, SourceDescription, `n, `r
	{
	 if (Trim(A_LoopField) = "")
		continue
	 SourceFiles.Push(GetFileComment(A_LoopField))
	 SourceFilesIndex[SourceFiles[A_Index].FileName]:=A_Index
	 SourceFilesList .= SourceFiles[A_Index].FileName "`n"
	}
Return

BuildTargetFiles:
FileRead, TargetDescription, %PathWrite%
TargetFiles:=[]
TargetFilesIndex:=[]
If TargetDescription
	Loop, parse, TargetDescription, `n, `r
		{
		 if (Trim(A_LoopField) = "")
			continue
		 TargetFiles.Push(GetFileComment(A_LoopField))
		 TargetFilesIndex[TargetFiles[A_Index].FileName]:=A_Index
		}
Return

#If WinActive(AppTitle)
Esc::Gosub, BrowseGuiClose
F1::Gosub, Help
F4::Gosub, EditComment
F5::Gosub, CopySelectedComments
F8::Gosub, DeleteComment
#If

BrowseGuiSize:
AutoXYWH("w h","lv")
AutoXYWH("y","EditB")
AutoXYWH("x y","HelpB")
AutoXYWH("x y","CancelB")
AutoXYWH("x y","CopyB")
AutoXYWH("x y","DelB")
Return

Folder:
Gui, Browse:Default
Gui, Browse:Submit, NoHide
If FCurrent
	PathWrite:=PathRead
else
	PathWrite:=PathWriteStartup
Gosub, BuildFiles
Gosub, BuildSourceFiles
Gosub, BuildTargetFiles
GuiControl, , SourceTarget, Source:`t%PathRead%`nTarget:`t%PathWrite%
LV_ModifyCol(3, ,"Comment to: [" PathWrite "]")
;MsgBox % FCurrent ":" FTarget
Gosub, UpdateListview
Return

UpdateListview:
Gui, Browse:Default
Gui, Browse:Submit, NoHide
GuiControl, -Redraw, LV
CLV.Clear()
LV_Delete()
Row:=0
for k, v in Files
	{
;	 If TargetFilesIndex.HasKey(v) ; debug
;		MsgBox % "both:" TargetFiles[TargetFilesIndex[v]].Comment ":" SourceFiles[SourceFilesIndex[v]].Comment

;if (v = "")
;	continue
;MsgBox % v

	 If (SourceFilesIndex.HasKey(v) and TargetFilesIndex.HasKey(v)) ; exact match (filenames AND comments are the same)
		If (SourceFiles[SourceFilesIndex[v]].Comment = TargetFiles[TargetFilesIndex[v]].Comment)
			{
			 If Skip
				Continue
			 LV_Add("" , v, v, SourceFiles[SourceFilesIndex[v]].Comment) ; 100% match file and comment = blue, unchecked
			 CLV.Row(++Row, 0xADD8E6, 0x000000)
			 Continue
			}
	If SourceFilesIndex.HasKey(v) ; we have a match, filenames are the same
		{
		 LV_Add("" "Check", v, SourceFiles[SourceFilesIndex[v]].FileName, SourceFiles[SourceFilesIndex[v]].Comment) ; 100% match = green
		 CLV.Row(++Row, 0x90ee90, 0x000000)
		}
	 else
		{ 
		 if Exact
			Continue
		 match:=StrSplit(Sift_Ngram(SourceFilesList, v),"`n").1             ; partial match, 1st result = grey
		 if (Match <> "")
			{ 
			 LV_Add("" "Check", v, match, SourceFiles[SourceFilesIndex[match]].Comment)
			 CLV.Row(++Row, 0xc0c0c0, 0x000000)
			}
		 else                                                               ; no match = red
			{
			 LV_Add("", v)
			 CLV.Row(++Row, 0xffd2a5, 0x000000) 
			}
		}
	}

LV_ModifyCol(1)
LV_ModifyCol(2)
GuiControl, +Redraw, LV
Return

CopySelectedComments:
Gui, Browse:Submit, NoHide
Gui, Browse:Default
NewComments:=""
CommentFiles:=""
RowNumber:=0
CommentCounter:=0
Loop
	{
	 RowNumber := LV_GetNext(RowNumber, "C")  ; Resume the search at the row after that found by the previous iteration.
	 if not RowNumber  ; The above returned zero, so there are no more selected rows.
		break
	 LV_GetText(TargetCommentFile, RowNumber, 1)
	 LV_GetText(comment, RowNumber, 3)
	 if InStr(TargetCommentFile, " ")
		TargetCommentFile:="""" TargetCommentFile """"
	 if InStr(comment,"\n")
		comment .= Chr(4) "Â"
;	 FileAppend, % TargetCommentFile " " comment "`n", % PathWrite
	 NewComments .= TargetCommentFile " " comment "`n"
	 CommentFiles .= TargetCommentFile "|"
	 CommentCounter++
	}
if !CommentCounter
	{
	 MsgBox,48, %AppTitle%: No comments, No files selected.
	 Return
	}
CommentFiles:=RTrim(CommentFiles,"|")
if Replace
	{
	 Loop, parse, TargetDescription, `n, `r
		{
		 if (A_LoopField = "")
			continue
		 if !RegExMatch(A_LoopField,"Ui)(" CommentFiles ")")
			NewComments .= A_LoopField "`n"
		}
	}
Sort, NewComments, U
if Backup
	{
;	 FileSetAttrib, -H, %PathWrite%.bak
;	 FileSetAttrib, -H, %PathWrite%
	 FileDelete, %PathWrite%.bak
	 FileMove, %PathWrite%, %PathWrite%.bak, 1
	}
FileAppend, %newcomments%, %PathWrite%
MsgBox,64, %AppTitle%: Done, %CommentCounter% comment(s) copied to %PathWrite%
CommentCounter:=0, NewComments:="", CommentFiles:=""
if Hidden
	FileSetAttrib, +H, %PathWrite%
Return

DeleteComment:
Gui, Browse:Submit, NoHide
Gui, Browse:Default
If (SelItem = "")
	{
	 Gui, Browse:Submit, NoHide
	 SelItem := LV_GetNext()
	 If (SelItem = 0)
		SelItem = 1
	}
LV_GetText(editfile, SelItem, 1)
MsgBox % SelItem ":" editfile
LV_Delete(SelItem)
GuiControl, +Redraw, LV
SelItem:="",editfile:=""
Return

EditCommentMouse:
If (A_GuiEvent <> "DoubleClick")
	Return
SelItem:=A_EventInfo

EditComment:
Gui, Browse:Default
If (SelItem = "")
	{
	 Gui, Browse:Submit, NoHide
	 SelItem := LV_GetNext()
	 If (SelItem = 0)
		SelItem = 1
	}
LV_GetText(comment, SelItem, 3)
LV_GetText(editfile, SelItem, 1)
Gosub, EditGui
Return


EditGui:
Gui Editor:Destroy
Gui Editor:Add, Text  , x4 y8, Edit comment for:`n%editfile%
;Gui Editor:Add, Button, x y288 w75 h23 gEditGuiHelp, Help
Gui Editor:Add, Button, x546 y288 w75 h23 gEditGuiCancel, Cancel
Gui Editor:Add, Button, x466 y288 w75 h23 gEditGuiOK, F2 OK
Gui Editor:Add, Edit  , x4 y40 w617 h241 vComment, % StrReplace(comment,"\n","`n")
Gui Editor:Show       , w625 h313, %AppTitle% - Edit File comment
Return

EditGuiOK:
Gui, Editor:Submit, Destroy
Gui, Browse:Default
LV_Modify(SelItem, "Col3", StrReplace(comment,"`n","`\n"))
LV_Modify(SelItem, "Check")
SelItem:="",Comment:=""
Return

EditGuiCancel:
Gui Editor:Destroy
Return

EditGuiHelp:
MsgBox Help
Return

#If WinActive(AppTitle " - Edit File comment")
Esc::Gosub, EditGuiCancel
F1::Gosub, EditGuiHelp
F2::Gosub, EditGuiOK
#If

BrowseGuiClose:
Gui, Browse:Submit, NoHide
WinGetPos, X, Y, , , %AppTitle%
VarSetCapacity( rect, 16, 0) ; get proper width/height
DllCall("GetClientRect", uint, MyGuiHWND := WinExist(), uint, &rect)
W:=NumGet( rect, 8, "int")
H:=NumGet( rect, 12, "int")
W:=Round(W/dpifactor)
H:=Round(H/dpifactor)
IniWrite, %X%        , %ini%, Position, X
IniWrite, %Y%        , %ini%, Position, Y
IniWrite, %W%        , %ini%, Position, W
IniWrite, %H%        , %ini%, Position, H
IniWrite, %Exact%    , %ini%, Settings, Exact
IniWrite, %Skip%     , %ini%, Settings, Skip
IniWrite, %Backup%   , %ini%, Settings, Backup
IniWrite, %Replace%  , %ini%, Settings, Replace
IniWrite, %Hidden%   , %ini%, Settings, Hidden
IniWrite, %FCurrent% , %ini%, Settings, FCurrent
IniWrite, %FTarget%  , %ini%, Settings, FTarget
IniWrite, %FAllFiles%, %ini%, Settings, FAllFiles

Gui, Browse:Destroy
ExitApp
Return

GetFileComment(line)
	{
	 static q:=""""
	 if (SubStr(line,1,1) = q)
			{
			 FileName:=Trim(SubStr(line,1,InStr(line,q,,2)),q)
			 Comment:=Trim(SubStr(line,InStr(line,q,,2)),q " ")
			}
		 else
			{
			 FileName:=Trim(SubStr(line,1,InStr(line," ")))
			 Comment:=SubStr(line,InStr(line," ")+1)
			}
	 obj:=[]
	 if !Comment
		MsgBox % ">" FileName
	 if InStr(Comment,Chr(4)) ; we need to remove EOT (Chr(4) and Â)
		{
		 Comment:=SubStr(Comment,1,StrLen(Comment)-2)
		}
	
	 obj["FileName"]:=FileName
	 obj["Comment"]:=Comment
	 Return obj
	}


; ---------------------------------------------------------------------------------
; LV_Colors

; ======================================================================================================================
; Namespace:	  LV_Colors
; Function:       Individual row and cell coloring for AHK ListView controls.
; Testted with:   AHK 1.1.20.03 (A32/U32/U64)
; Tested on:      Win 8.1 (x64)
; Changelog:
;     1.1.00.00/2015-03-27/just me - added AlternateRows and AlternateCols, revised code.
;     1.0.00.00/2015-03-23/just me - new version using new AHK 1.1.20+ features
;     0.5.00.00/2014-08-13/just me - changed 'static mode' handling
;     0.4.01.00/2013-12-30/just me - minor bug fix
;     0.4.00.00/2013-12-30/just me - added static mode
;     0.3.00.00/2013-06-15/just me - added "Critical, 100" to avoid drawing issues
;     0.2.00.00/2013-01-12/just me - bugfixes and minor changes
;     0.1.00.00/2012-10-27/just me - initial release
; ======================================================================================================================
; CLASS LV_Colors
;
; The class provides six public methods to set individual colors for rows and/or cells, to clear all colors, to
; prevent/allow sorting and rezising of columns dynamically, and to remove/add a message handler for WM_NOTIFY messages.
;
; The message handler for WM_NOTIFY messages will be activated for the specified ListView whenever a new instance is
; created. If you want to use an own message handler, set the OnMessage parameter to False when creating the new
; instance or call MyNewInstance.OnMessage(False) after the new instance has been created.
; ======================================================================================================================
Class LV_Colors {
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; META FUNCTIONS ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; -------------------------------------------------------------------------------------------------------------------
   ; __New()         Create a new LV_Colors instance for the given ListView
   ; Parameters:     HWND        -  ListView's HWND.
   ;                 Optional ------------------------------------------------------------------------------------------
   ;                 OnMessage   -  Add a message handler for WM_NOTIFY messages for this ListView.
   ;                                Values:  True/False
   ;                                Default: True
   ;                 StaticMode  -  Static color assignment, i.e. the colors will be assigned permanently to a row
   ;                                rather than to a row number.
   ;                                Values:  True/False
   ;                                Default: False
   ;                 NoSort      -  Prevent sorting by click on a header item.
   ;                                Values:  True/False
   ;                                Default: True
   ;                 NoSizing    -  Prevent resizing of columns.
   ;                                Values:  True/False
   ;                                Default: True
   ; -------------------------------------------------------------------------------------------------------------------
   __New(HWND, OnMessage := True, StaticMode := False, NoSort := True, NoSizing := True) {
      If (This.Base.Base.__Class) ; do not instantiate instances
         Return False
      If This.Attached[HWND] ; HWND is already attached
         Return False
      If !DllCall("IsWindow", "Ptr", HWND) ; invalid HWND
         Return False
      VarSetCapacity(Class, 512, 0)
      DllCall("GetClassName", "Ptr", HWND, "Str", Class, "Int", 256)
      If (Class <> "SysListView32") ; HWND doesn't belong to a ListView
         Return False
      ; ----------------------------------------------------------------------------------------------------------------
      ; Set LVS_EX_DOUBLEBUFFER (0x010000) style to avoid drawing issues.
      SendMessage, 0x1036, 0x010000, 0x010000, , % "ahk_id " . HWND ; LVM_SETEXTENDEDLISTVIEWSTYLE
      ; Get the default colors
      SendMessage, 0x1025, 0, 0, , % "ahk_id " . HWND ; LVM_GETTEXTBKCOLOR
      This.BkClr := ErrorLevel
      SendMessage, 0x1023, 0, 0, , % "ahk_id " . HWND ; LVM_GETTEXTCOLOR
      This.TxClr := ErrorLevel
      ; Get the header control
      SendMessage, 0x101F, 0, 0, , % "ahk_id " . HWND ; LVM_GETHEADER
      This.Header := ErrorLevel
      ; Set other properties
      This.HWND := HWND
      This.IsStatic := !!StaticMode
      This.AltCols := False
      This.AltRows := False
      If (NoSort)
         This.NoSort()
      If (NoSizing)
         This.NoSizing()
      This.OnMessage(!!OnMessage)
      This.Attached[HWND] := True
   }
   ; -------------------------------------------------------------------------------------------------------------------
   __Delete() {
      This.Attached.Remove(HWND, "")
      This.OnMessage(False)
      WinSet, Redraw, , % "ahk_id " . This.HWND
   }
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; PRIVATE PROPERTIES  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   Static Attached := {}
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; PRIVATE METHODS +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   On_WM_NOTIFY(W, L, M, H) {
      ; Notifications: NM_CUSTOMDRAW = -12, LVN_COLUMNCLICK = -108, HDN_BEGINTRACKA = -306, HDN_BEGINTRACKW = -326
      Critical, % LV_Colors.Critical
      If ((HCTL := NumGet(L + 0, 0, "UPtr")) = This.HWND) || (HCTL = This.Header) {
         Code := NumGet(L + (A_PtrSize * 2), 0, "Int")
         If (Code = -12)
            Return This.On_NM_CUSTOMDRAW(H, L)
         If This.NoSort && (Code = -108)
            Return 0
         If This.NoSizing && ((Code = -306) || (Code = -326))
            Return True
      }
   }
   ; -------------------------------------------------------------------------------------------------------------------
   On_NM_CUSTOMDRAW(H, L) {
      ; Return values: 0x00 (CDRF_DODEFAULT), 0x20 (CDRF_NOTIFYITEMDRAW / CDRF_NOTIFYSUBITEMDRAW)
      Static SizeNMHDR := A_PtrSize * 3                  ; Size of NMHDR structure
      Static SizeNCD := SizeNMHDR + 16 + (A_PtrSize * 5) ; Size of NMCUSTOMDRAW structure
      Static OffItem := SizeNMHDR + 16 + (A_PtrSize * 2) ; Offset of dwItemSpec (NMCUSTOMDRAW)
      Static OffCT :=  SizeNCD                           ; Offset of clrText (NMLVCUSTOMDRAW)
      Static OffCB := OffCT + 4                          ; Offset of clrTextBk (NMLVCUSTOMDRAW)
      Static OffSubItem := OffCB + 4                     ; Offset of iSubItem (NMLVCUSTOMDRAW)
      ; ----------------------------------------------------------------------------------------------------------------
      DrawStage := NumGet(L + SizeNMHDR, 0, "UInt")
      , Row := NumGet(L + OffItem, 0, "UPtr") + 1
      , Col := NumGet(L + OffSubItem, 0, "Int") + 1
      , Item := Row - 1
      If This.IsStatic
         Row := This.MapIndexToID(H, Row)
      ; CDDS_SUBITEMPREPAINT = 0x030001 --------------------------------------------------------------------------------
      If (DrawStage = 0x030001) {
         UseAltCol := !(Col & 1) && (This.AltCols)
         , ColColors := This["Cells", Row, Col]
         , ColB := (ColColors.B <> "") ? ColColors.B : UseAltCol ? This.ACB : This.RowB
         , ColT := (ColColors.T <> "") ? ColColors.T : UseAltCol ? This.ACT : This.RowT
         , NumPut(ColT, L + OffCT, 0, "UInt"), NumPut(ColB, L + OffCB, 0, "UInt")
         Return (!This.AltCols && !This.HasKey(Row) && (Col > This["Cells", Row].MaxIndex())) ? 0x00 : 0x20
      }
      ; CDDS_ITEMPREPAINT = 0x010001 -----------------------------------------------------------------------------------
      If (DrawStage = 0x010001) {
         UseAltRow := (Item & 1) && (This.AltRows)
         , RowColors := This["Rows", Row]
         , This.RowB := RowColors ? RowColors.B : UseAltRow ? This.ARB : This.BkClr
         , This.RowT := RowColors ? RowColors.T : UseAltRow ? This.ART : This.TxClr
         If (This.AltCols || This["Cells"].HasKey(Row))
            Return 0x20
         NumPut(This.RowT, L + OffCT, 0, "UInt"), NumPut(This.RowB, L + OffCB, 0, "UInt")
         Return 0x00
      }
      ; CDDS_PREPAINT = 0x000001 ---------------------------------------------------------------------------------------
      Return (DrawStage = 0x000001) ? 0x20 : 0x00
   }
   ; -------------------------------------------------------------------------------------------------------------------
   MapIndexToID(Row) { ; provides the unique internal ID of the given row number
      SendMessage, 0x10B4, % (Row - 1), 0, , % "ahk_id " . This.HWND ; LVM_MAPINDEXTOID
      Return ErrorLevel
   }
   ; -------------------------------------------------------------------------------------------------------------------
   BGR(Color, Default := "") { ; converts colors to BGR
      Static Integer := "Integer" ; v2
      ; HTML Colors (BGR)
      Static HTML := {AQUA: 0xFFFF00, BLACK: 0x000000, BLUE: 0xFF0000, FUCHSIA: 0xFF00FF, GRAY: 0x808080, GREEN: 0x008000
                    , LIME: 0x00FF00, MAROON: 0x000080, NAVY: 0x800000, OLIVE: 0x008080, PURPLE: 0x800080, RED: 0x0000FF
                    , SILVER: 0xC0C0C0, TEAL: 0x808000, WHITE: 0xFFFFFF, YELLOW: 0x00FFFF}
      If Color Is Integer
         Return ((Color >> 16) & 0xFF) | (Color & 0x00FF00) | ((Color & 0xFF) << 16)
      Return (HTML.HasKey(Color) ? HTML[Color] : Default)
   }
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; PUBLIC PROPERTIES  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   Static Critical := 100
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; PUBLIC METHODS ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   ; ===================================================================================================================
   ; Clear()         Clears all row and cell colors.
   ; Parameters:     AltRows     -  Reset alternate row coloring (True / False)
   ;                                Default: False
   ;                 AltCols     -  Reset alternate column coloring (True / False)
   ;                                Default: False
   ; Return Value:   Always True.
   ; ===================================================================================================================
   Clear(AltRows := False, AltCols := False) {
      If (AltCols)
         This.AltCols := False
      If (AltRows)
         This.AltRows := False
      This.Remove("Rows")
      This.Remove("Cells")
      Return True
   }
   ; ===================================================================================================================
   ; AlternateRows() Sets background and/or text color for even row numbers.
   ; Parameters:     BkColor     -  Background color as RGB color integer (e.g. 0xFF0000 = red) or HTML color name.
   ;                                Default: Empty -> default background color
   ;                 TxColor     -  Text color as RGB color integer (e.g. 0xFF0000 = red) or HTML color name.
   ;                                Default: Empty -> default text color
   ; Return Value:   True on success, otherwise false.
   ; ===================================================================================================================
   AlternateRows(BkColor := "", TxColor := "") {
      If !(This.HWND)
         Return False
      This.AltRows := False
      If (BkColor = "") && (TxColor = "")
         Return True
      BkBGR := This.BGR(BkColor)
      TxBGR := This.BGR(TxColor)
      If (BkBGR = "") && (TxBGR = "")
         Return False
      This["ARB"] := (BkBGR <> "") ? BkBGR : This.BkClr
      This["ART"] := (TxBGR <> "") ? TxBGR : This.TxClr
      This.AltRows := True
      Return True
   }
   ; ===================================================================================================================
   ; AlternateCols() Sets background and/or text color for even column numbers.
   ; Parameters:     BkColor     -  Background color as RGB color integer (e.g. 0xFF0000 = red) or HTML color name.
   ;                                Default: Empty -> default background color
   ;                 TxColor     -  Text color as RGB color integer (e.g. 0xFF0000 = red) or HTML color name.
   ;                                Default: Empty -> default text color
   ; Return Value:   True on success, otherwise false.
   ; ===================================================================================================================
   AlternateCols(BkColor := "", TxColor := "") {
      If !(This.HWND)
         Return False
      This.AltCols := False
      If (BkColor = "") && (TxColor = "")
         Return True
      BkBGR := This.BGR(BkColor)
      TxBGR := This.BGR(TxColor)
      If (BkBGR = "") && (TxBGR = "")
         Return False
      This["ACB"] := (BkBGR <> "") ? BkBGR : This.BkClr
      This["ACT"] := (TxBGR <> "") ? TxBGR : This.TxClr
      This.AltCols := True
      Return True
   }
   ; ===================================================================================================================
   ; Row()           Sets background and/or text color for the specified row.
   ; Parameters:     Row         -  Row number
   ;                 Optional ------------------------------------------------------------------------------------------
   ;                 BkColor     -  Background color as RGB color integer (e.g. 0xFF0000 = red) or HTML color name.
   ;                                Default: Empty -> default background color
   ;                 TxColor     -  Text color as RGB color integer (e.g. 0xFF0000 = red) or HTML color name.
   ;                                Default: Empty -> default text color
   ; Return Value:   True on success, otherwise false.
   ; ===================================================================================================================
   Row(Row, BkColor := "", TxColor := "") {
      If !(This.HWND)
         Return False
      If This.IsStatic
         Row := This.MapIndexToID(Row)
      This["Rows"].Remove(Row, "")
      If (BkColor = "") && (TxColor = "")
         Return True
      BkBGR := This.BGR(BkColor)
      TxBGR := This.BGR(TxColor)
      If (BkBGR = "") && (TxBGR = "")
         Return False
      This["Rows", Row, "B"] := (BkBGR <> "") ? BkBGR : This.BkClr
      This["Rows", Row, "T"] := (TxBGR <> "") ? TxBGR : This.TxClr
      Return True
   }
   ; ===================================================================================================================
   ; Cell()          Sets background and/or text color for the specified cell.
   ; Parameters:     Row         -  Row number
   ;                 Col         -  Column number
   ;                 Optional ------------------------------------------------------------------------------------------
   ;                 BkColor     -  Background color as RGB color integer (e.g. 0xFF0000 = red) or HTML color name.
   ;                                Default: Empty -> row's background color
   ;                 TxColor     -  Text color as RGB color integer (e.g. 0xFF0000 = red) or HTML color name.
   ;                                Default: Empty -> row's text color
   ; Return Value:   True on success, otherwise false.
   ; ===================================================================================================================
   Cell(Row, Col, BkColor := "", TxColor := "") {
      If !(This.HWND)
         Return False
      If ThisIsStatic
         Row := This.MapIndexToID(Row)
      This["Cells", Row].Remove(Col, "")
      If (BkColor = "") && (TxColor = "")
         Return True
      BkBGR := This.BGR(BkColor)
      TxBGR := This.BGR(TxColor)
      If (BkBGR = "") && (TxBGR = "")
         Return False
      If (BkBGR <> "")
         This["Cells", Row, Col, "B"] := BkBGR
      If (TxBGR <> "")
         This["Cells", Row, Col, "T"] := TxBGR
      Return True
   }
   ; ===================================================================================================================
   ; NoSort()        Prevents/allows sorting by click on a header item for this ListView.
   ; Parameters:     Apply       -  True/False
   ;                                Default: True
   ; Return Value:   True on success, otherwise false.
   ; ===================================================================================================================
   NoSort(Apply := True) {
      If !(This.HWND)
         Return False
      If (Apply)
         This.NoSort := True
      Else
         This.NoSort := False
      Return True
   }
   ; ===================================================================================================================
   ; NoSizing()      Prevents/allows resizing of columns for this ListView.
   ; Parameters:     Apply       -  True/False
   ;                                Default: True
   ; Return Value:   True on success, otherwise false.
   ; ===================================================================================================================
   NoSizing(Apply := True) {
      Static OSVersion := DllCall("GetVersion", "UChar")
      If !(This.Header)
         Return False
      If (Apply) {
         If (OSVersion > 5)
            Control, Style, +0x0800, , % "ahk_id " . This.Header ; HDS_NOSIZING = 0x0800
         This.NoSizing := True
      }
      Else {
         If (OSVersion > 5)
            Control, Style, -0x0800, , % "ahk_id " . This.Header ; HDS_NOSIZING
         This.NoSizing := False
      }
      Return True
   }
   ; ===================================================================================================================
   ; OnMessage()     Adds/removes a message handler for WM_NOTIFY messages for this ListView.
   ; Parameters:     Apply       -  True/False
   ;                                Default: True
   ; Return Value:   Always True
   ; ===================================================================================================================
   OnMessage(Apply := True) {
      If (Apply) && !This.HasKey("OnMessageFunc") {
         This.OnMessageFunc := ObjBindMethod(This, "On_WM_Notify")
         OnMessage(0x004E, This.OnMessageFunc) ; add the WM_NOTIFY message handler
      }
      Else If !(Apply) && This.HasKey("OnMessageFunc") {
         OnMessage(0x004E, This.OnMessageFunc, 0) ; remove the WM_NOTIFY message handler
         This.OnMessageFunc := ""
         This.Remove("OnMessageFunc")
      }
      WinSet, Redraw, , % "ahk_id " . This.HWND
      Return True
   }
}

; ---------------------------------------------------------------------------------
; Source @ AutoHotkey Forum: https://www.autohotkey.com/boards/viewtopic.php?t=7302
;{ Sift
; Fanatic Guru
; 2015 04 30
; Version 1.00
;
; LIBRARY to sift through a string or array and return items that match sift criteria.
;
; ===================================================================================================================================================
;
; Functions:
; 
; ===================================================================================================================================================
; Sift_Regex(Haystack, Needle, Options, Delimiter)
;
;   Parameters:
;   1) {Haystack}	String or array of information to search, ByRef for efficiency but Haystack is not changed by function
;
;   2) {Needle}		String providing search text or criteria, ByRef for efficiency but Needle is not changed by function
;
;	3) {Options}
;			IN		Needle anywhere IN Haystack item (Default = IN)
;			LEFT	Needle is to LEFT or beginning of Haystack item
;			RIGHT	Needle is to RIGHT or end of Haystack item
;			EXACT	Needle is an EXACT match to Haystack item
;			REGEX	Needle is an REGEX expression to check against Haystack item
;			OC		Needle is ORDERED CHARACTERS to be searched for even non-consecutively but in the given order in Haystack item 
;			OW		Needle is ORDERED WORDS to be searched for even non-consecutively but in the given order in Haystack item
;			UC		Needle is UNORDERED CHARACTERS to be search for even non-consecutively and in any order in Haystack item
;			UW		Needle is UNORDERED WORDS to be search for even non-consecutively and in any order in Haystack item
;
;			If an Option is all lower case then the search will be case insensitive
;
;	4)  {Delimiter}	Single character Delimiter of each item in a Haystack string (Default = `n)
;
;	Returns: 
;		If Haystack is string then a string is returned of found Haystack items delimited by the Delimiter
; 		If Haystack is an array then an array is returned of found Haystack items
;
; 	Note:
;		Sift_Regex searchs are all RegExMatch seaches with Needles crafted based on the options chosen
;
; ===================================================================================================================================================
; Sift_Ngram(Haystack, Needle, Delta, Haystack_Matrix, Ngram Size, Format)
;
;	Parameters:
;	1) {Haystack}		String or array of information to search, ByRef for efficiency but Haystack is not changed by function
;
;   2) {Needle}			String providing search text or criteria, ByRef for efficiency but Needle is not changed by function
;
;	3) {Delta}			(Default = .7) Fuzzy match coefficient, 1 is a prefect match, 0 is no match at all, only results above the Delta are returned
;
;	4) {Haystack_Matrix} (Default = false)	
;			An object containing the preprocessing of the Haystack for Ngrams content
;			If a non-object is passed the Haystack is processed for Ngram content and the results are returned by ByRef
;			If an object is passed then that is used as the processed Ngram content of Haystack
;			If multiply calls to the function are made with no change to the Haystack then a previous processing of Haystack for Ngram content 
;				can be passed back to the function to avoid reprocessing the same Haystack again in order to increase efficiency.
;
;	5) {Ngram Size}		(Default = 3) The length of Ngram used.  Generally Ngrams made of 3 letters called a Trigram is good
;
;	6) {Format}			(Default = S`n)
;			S				Return Object with results Sorted
;			U				Return Object with results Unsorted
;			S%%%			Return Sorted string delimited by characters after S
;			U%%%			Return Unsorted string delimited by characters after U
;								Sorted results are by best match first
;
;	Returns:
;		A string or array depending on Format parameter.
;		If string then it is delimited based on Format parameter.
;		If array then an array of object is returned where each element is of the structure: {Object}.Delta and {Object}.Data
;			Example Code to access object returned:
;				for key, element in Sift_Ngram(Data, QueryText, NgramLimit, Data_Ngram_Matrix, NgramSize)
;						Display .= element.delta "`t" element.data "`n"
;
;	Dependencies: Sift_Ngram_Get, Sift_Ngram_Compare, Sift_Ngram_Matrix, Sift_SortResults
;		These are helper functions that are generally not called directly.  Although Sift_Ngram_Matrix could be useful to call directly to preprocess a large static Haystack
;
; 	Note:
;		The string "dog house" would produce these Trigrams: dog|og |g h| ho|hou|ous|use
;		Sift_Ngram breaks the needle and each item of the Haystack up into Ngrams.
;		Then all the Needle Ngrams are looked for in the Haystack items Ngrams resulting in a percentage of Needle Ngrams found
;
; ===================================================================================================================================================
;
Sift_Regex(ByRef Haystack, ByRef Needle, Options := "IN", Delimit := "`n")
{
	Sifted := {}
	if (Options = "IN")		
		Needle_Temp := "\Q" Needle "\E"
	else if (Options = "LEFT")
		Needle_Temp := "^\Q" Needle "\E"
	else if (Options = "RIGHT")
		Needle_Temp := "\Q" Needle "\E$"
	else if (Options = "EXACT")		
		Needle_Temp := "^\Q" Needle "\E$"
	else if (Options = "REGEX")
		Needle_Temp := Needle
	else if (Options = "OC")
		Needle_Temp := RegExReplace(Needle,"(.)","\Q$1\E.*")
	else if (Options = "OW")
		Needle_Temp := RegExReplace(Needle,"( )","\Q$1\E.*")
	else if (Options = "UW")
		Loop, Parse, Needle, " "
			Needle_Temp .= "(?=.*\Q" A_LoopField "\E)"
	else if (Options = "UC")
		Loop, Parse, Needle
			Needle_Temp .= "(?=.*\Q" A_LoopField "\E)"

	if Options is lower
		Needle_Temp := "i)" Needle_Temp
	
	if IsObject(Haystack)
	{
		for key, Hay in Haystack
			if RegExMatch(Hay, Needle_Temp)
				Sifted.Insert(Hay)
	}
	else
	{
		Loop, Parse, Haystack, %Delimit%
			if RegExMatch(A_LoopField, Needle_Temp)
				Sifted .= A_LoopField Delimit
		Sifted := SubStr(Sifted,1,-1)
	}
	return Sifted
}

Sift_Ngram(ByRef Haystack, ByRef Needle, Delta := .7, ByRef Haystack_Matrix := false, n := 3, Format := "S`n" )
{
	if !IsObject(Haystack_Matrix)
		Haystack_Matrix := Sift_Ngram_Matrix(Haystack, n)
	Needle_Ngram := Sift_Ngram_Get(Needle, n)
	if IsObject(Haystack)
	{
		Search_Results := {}
		for key, Hay_Ngram in Haystack_Matrix
		{
			Result := Sift_Ngram_Compare(Hay_Ngram, Needle_Ngram)
			if !(Result < Delta)
				Search_Results[key,"Delta"] := Result, Search_Results[key,"Data"] := Haystack[key]
		}
	}
	else
	{
		Search_Results := {}
		Loop, Parse, Haystack, `n, `r
		{
			Result := Sift_Ngram_Compare(Haystack_Matrix[A_Index], Needle_Ngram)
			if !(Result < Delta)
				Search_Results[A_Index,"Delta"] := Result, Search_Results[A_Index,"Data"] := A_LoopField
		}
	}
	if (Format ~= "i)^S")
		Sift_SortResults(Search_Results)
	if RegExMatch(Format, "i)^(S|U)(.+)$", Match)
	{
		for key, element in Search_Results
			String_Results .= element.data Match2
		return SubStr(String_Results,1,-StrLen(Match2))
	}
	else
		return Search_Results
}

Sift_Ngram_Get(ByRef String, n := 3)
{
	Pos := 1, Grams := {}
	Loop, % (1 + StrLen(String) - n)
		gram := SubStr(String, A_Index, n), Grams[gram] ? Grams[gram] ++ : Grams[gram] := 1
	return Grams
} 

Sift_Ngram_Compare(ByRef Hay, ByRef Needle)
{
	for gram, Needle_Count in Needle
	{
		Needle_Total += Needle_Count
		Match += (Hay[gram] > Needle_Count ? Needle_Count : Hay[gram])
	}
	return Match / Needle_Total
}

Sift_Ngram_Matrix(ByRef Data, n := 3)
{
	if IsObject(Data)
	{
		Matrix := {}
		for key, string in Data
			Matrix.Insert(Sift_Ngram_Get(string, n))
	}
	else
	{
		Matrix := {}
		Loop, Parse, Data, `n
			Matrix.Insert(Sift_Ngram_Get(A_LoopField, n))
	}
	return Matrix
}

Sift_SortResults(ByRef Data)
{
	Data_Temp := {}
	for key, element in Data
		Data_Temp[element.Delta SubStr("0000000000" key, -9)] := element
	Data := {}
	for key, element in Data_Temp
		Data.InsertAt(1,element)
	return
}


; =================================================================================
; Function: AutoXYWH
;   Move and resize control automatically when GUI resizes.
; Parameters:
;   DimSize - Can be one or more of x/y/w/h  optional followed by a fraction
;             add a '*' to DimSize to 'MoveDraw' the controls rather then just 'Move', this is recommended for Groupboxes
;   cList   - variadic list of ControlIDs
;             ControlID can be a control HWND, associated variable name, ClassNN or displayed text.
;             The later (displayed text) is possible but not recommend since not very reliable 
; Examples:
;   AutoXYWH("xy", "Btn1", "Btn2")
;   AutoXYWH("w0.5 h 0.75", hEdit, "displayed text", "vLabel", "Button1")
;   AutoXYWH("*w0.5 h 0.75", hGroupbox1, "GrbChoices")
; ---------------------------------------------------------------------------------
; Version: 2015-5-29 / Added 'reset' option (by tmplinshi)
;          2014-7-03 / toralf
;          2014-1-2  / tmplinshi
; requires AHK version : 1.1.13.01+
; =================================================================================
AutoXYWH(DimSize, cList*){       ; http://ahkscript.org/boards/viewtopic.php?t=1079
  static cInfo := {}
 
  If (DimSize = "reset")
    Return cInfo := {}
 
  For i, ctrl in cList {
    ctrlID := A_Gui ":" ctrl
    If ( cInfo[ctrlID].x = "" ){
        GuiControlGet, i, %A_Gui%:Pos, %ctrl%
        MMD := InStr(DimSize, "*") ? "MoveDraw" : "Move"
        fx := fy := fw := fh := 0
        For i, dim in (a := StrSplit(RegExReplace(DimSize, "i)[^xywh]")))
            If !RegExMatch(DimSize, "i)" dim "\s*\K[\d.-]+", f%dim%)
              f%dim% := 1
        cInfo[ctrlID] := { x:ix, fx:fx, y:iy, fy:fy, w:iw, fw:fw, h:ih, fh:fh, gw:A_GuiWidth, gh:A_GuiHeight, a:a , m:MMD}
    }Else If ( cInfo[ctrlID].a.1) {
        dgx := dgw := A_GuiWidth  - cInfo[ctrlID].gw  , dgy := dgh := A_GuiHeight - cInfo[ctrlID].gh
        For i, dim in cInfo[ctrlID]["a"]
            Options .= dim (dg%dim% * cInfo[ctrlID]["f" dim] + cInfo[ctrlID][dim]) A_Space
        GuiControl, % A_Gui ":" cInfo[ctrlID].m , % ctrl, % Options
} } }
