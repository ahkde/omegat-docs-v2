﻿#NoEnv
SetBatchLines, -1
SetWorkingDir, % A_ScriptDir

FileGetTime, LastSaveTime, tmx_ahk_docs_2-omegat.tmx
TotalProcessedFiles := 0
Loop, target\*.htm,, 1
{
    ; Get number of processed files to determine whether only one or all documents was created:
    
    FileGetTime, ModifyTime, % A_LoopFileLongPath
    DiffTime := LastSaveTime
    EnvSub, DiffTime, %ModifyTime%, seconds
    if (DiffTime < 0)
        TotalProcessedFiles++
    
    ; read content
    
    FileEncoding, UTF-8-RAW
    FileRead, content_orig, % A_LoopFileLongPath
    content := content_orig
    
    ; skip sites
    
    if (A_LoopFileFullPath ~= "target\\search\.htm")
      continue

    ; add more infos about the translation 

    if (A_LoopFileFullPath = "target\AutoHotkey.htm")
    {
        content := RegExReplace(content, "<p><a.*?</a></p>", "<p>Eine deutsche &Uuml;bersetzung von <a href=""https://lexikos.github.io/v2/docs/"">https://lexikos.github.io/v2/docs/</a> (siehe <a href=""https://autohotkey.com/boards/viewtopic.php?f=9&amp;t=43"">hier</a> f&uuml;r mehr Details).</p>")
    }

    ; add google analytics

    If RegExMatch(content, "O)link href=""(.*)static/theme.css""", m)
        pre := m[1]

    replace  =
    ( LTrim Join`r`n
    <script src="%pre%static/content.js" type="text/javascript"></script>
    <script src="%pre%static/ga.js" type="text/javascript"></script>
    )

    if !InStr(content, replace)
        content := RegExReplace(content, "<script.*content.js.*?>.*</script>", replace)
    
    replace  =
    ( LTrim Join`r`n
    <meta name="robots" content="noindex, nofollow">
    <link href="%pre%static/theme.css" rel="stylesheet" type="text/css" />
    )

    if !InStr(content, replace)
        content := RegExReplace(content, "<link.*theme.css.*?>", replace)

    ; change doctype to html5

    if (content != content_orig)
    {
        file := FileOpen(A_LoopFileLongPath, "w")
        if !file
            msgbox % A_LoopFileLongPath
        file.Write(content)
        file.Close()
    }
    
}

; Skip the rest below if only one file was processed since the file was only created for testing purposes:

if (TotalProcessedFiles = 1)
    ExitApp

; create search index

; RunWait, % A_AhkPath "/../v2-alpha/AutoHotkeyU32.exe" " """ A_ScriptDir "/target/static/source/build_search.ahk"""

; compile docs to chm

RunWait, % A_ScriptDir "/target/compile_chm.ahk"

; compress chm into zip file

SmartZip(A_ScriptDir "\target\AutoHotkey.chm", A_ScriptDir "\temp.zip")
FileMove, % A_ScriptDir "\temp.zip", % A_ScriptDir "\AutoHotkey2Help_DE.zip", 1

/*
SmartZip()
   Smart ZIP/UnZIP files
Parameters:
   s, o   When compressing, s is the dir/files of the source and o is ZIP filename of object. When unpressing, they are the reverse.
   t      The options used by CopyHere method. For availble values, please refer to: http://msdn.microsoft.com/en-us/library/windows/desktop/bb787866
Link:
http://www.autohotkey.com/forum/viewtopic.php?p=523649#523649
*/

SmartZip(s, o, t = 4)
{
    IfNotExist, %s%
        return, -1        ; The souce is not exist. There may be misspelling.
    
    oShell := ComObjCreate("Shell.Application")
    
    if (SubStr(o, -3) = ".zip") ; Zip
    {
        IfNotExist, %o%        ; Create the object ZIP file if it's not exist.
            CreateZip(o)
        
        Loop, %o%, 1
            sObjectLongName := A_LoopFileLongPath

        oObject := oShell.NameSpace(sObjectLongName)
        
        Loop, %s%, 1
        {
            if (sObjectLongName = A_LoopFileLongPath)
            {
                continue
            }
            ToolTip, Zipping %A_LoopFileName% ..
            oObject.CopyHere(A_LoopFileLongPath, t)
            SplitPath, A_LoopFileLongPath, OutFileName
            Loop
            {
                oObject := "", oObject := oShell.NameSpace(sObjectLongName) ; This doesn't affect the copyhere above.
                if oObject.ParseName(OutFileName)
                    break
            }
        }
        ToolTip
    }
    else if InStr(FileExist(o), "D") or (!FileExist(o) and (SubStr(s, -3) = ".zip"))    ; Unzip
    {
        if !o
            o := A_ScriptDir        ; Use the working dir instead if the object is null.
        else IfNotExist, %o%
            FileCreateDir, %o%
        
        Loop, %o%, 1
            sObjectLongName := A_LoopFileLongPath
        
        oObject := oShell.NameSpace(sObjectLongName)
        
        Loop, %s%, 1
        {
            oSource := oShell.NameSpace(A_LoopFileLongPath)
            oObject.CopyHere(oSource.Items, t)
        }
    }
}

CreateZip(n)    ; Create empty Zip file
{
    ZIPHeader1 := "PK" . Chr(5) . Chr(6)
    VarSetCapacity(ZIPHeader2, 18, 0)
    ZIPFile := FileOpen(n, "w")
    ZIPFile.Write(ZIPHeader1)
    ZIPFile.RawWrite(ZIPHeader2, 18)
    ZIPFile.close()
}
