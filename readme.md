# TCSyncComments - copy file comments from descript.ion file(s)

## DESCRIPT.ION

> ... **[Total Commander]** use[s] the file DESCRIPT.ION to store file descriptions.  
> This file is created as a hidden file in each subdirectory which has  
> descriptions, and deleted when all descriptions are removed or when all  
> files with descriptions are deleted. If you remove the hidden attribute  
> from the file, it will not be hidden again.  
> ... **[Total Commander]** will copy, delete, or move all the information on a  
> line in DESCRIPT.ION, including information owned by other programs, when  
> performing the same action on the corresponding file. They will also  
> change the name if a file is renamed.  
> -- Source https://web.archive.org/web/20160318122322/https://jpsoft.com/ascii/descfile.txt

## Total Commander (TC)

- Edit file comments with Ctrl+Z; or Files menu, Edit File Comment.
- Comments can be displayed with Show - Comments (Ctrl+Shift+F2)[1] within the file lists, or by moving the mouse over a file name. For the latter, you need to enable Win32-style tips in Configuration - Display.
- In "Configuration, Operation": Set the preferred format + Turn "Copy comments with files" on or off.

Refer to TC Help file for further information.

[1] Tip: Setup a Auto Switch Mode rule to automatically "Show comments" when you enter a folder which has descript.ion file.

## Purpose of TCSyncComments:

Copy file comments (descript.ion format only) from:

- Source to Target folder
- Current Folder (trying to find matching file names using Sift Ngram)
- Select or All Files

+ Edit file comments before copying

This script will not copy, move or alter (selected) files - only the comments stored or added to a descript.ion  

Note: 

- it does not (yet) try to use the "set type" file encoding from TC.
- use at your own risk, backup descript.ion when in doubt. 

## Use case

With "Copy comments with files" turned off, file comments are not copied when copying, moving, or renaming a file.

TCSyncComments copies file comments it can find in descript.ion **or** try to add "new" ones based on file name "match",
either in the current or target folder. (Target folder is source of descript.ion to use)

Always make sure the panel where you want to UPDATE descript.ion is the active one. This is the "current" panel below.


c:\data\project: (target panel)

<table>
<tr><th>Name</th><th>Comment</th></tr>
<tr><td>Apple.txt </td><td>Edible fruit produced by an apple tree</td></tr>
<tr><td>Banana.txt</td><td>Botanically a berry</td></tr>
<tr><td>Cherry.txt</td><td>A fleshy stone fruit</td></tr>
</table>

c:\data\project\backup: (current panel)

<table>
<tr><th>Name</th><th>Comment</th></tr>
<tr><td>01_Apple.txt</td><td><i>has no file comment</i></td></tr>
<tr><td>Apple.txt   </td><td><i>has no file comment</i></td></tr>
</table>

1. Select c:\data\project\backup\Apple.txt
2. Start TCSyncComments
3. It will read the comments from c:\data\project\descript.ion
4. If it finds a match for Apple.txt, suggest to copy this to c:\data\project\backup\descript.ion
5. Press F5 to copy the file comment.

There are various combinations to try and find or skip a match (see animation below)

Colours used in the listview:

- Green: **Exact** match in file name(s) where no file comment is present in the current folder.
- Grey:  Allow **partially matched** file name(s) using Sift Ngram ("best guess") where no file comment is present in the current folder.
- Blue:  **Exact** match in file name(s) where the same file comment is already present in the current folder, skipped by default.

Use check marks to select which file comment(s) to copy.

Result after copying file comments (Sift Ngram):

c:\data\project\backup: (current folder)

<table>
<tr><th>Name</th><th>Comment</th></tr>
<tr><td>01_Apple.txt</td><td><i>has no file comment</i>[1]</td></tr>
<tr><td>Apple.txt   </td><td><i>Edible fruit produced by an apple tree</i></td></tr>
</table>

[1] Select "Sift Ngram" and "All files" to also copy the file comment to "01_Apple.txt"

Animation:

![TCSyncComments example animation](https://raw.githubusercontent.com/hi5/_resources/master/tctest1.gif)

## Options

Match files:

- Exact: file name(s) have to match - (green rows)
- SIFT Ngram: Allow **partially matched** file name(s) - (grey rows)
- Skip Identical: (un)hide Identical files from the listview - (blue rows)

descript.ion:

- Replace comments: replace current file comment if present in current descript.ion
- Backup (bak): create a backup (.bak) of original descript.ion (if present) before updating it
- Keep hidden: set Hidden attribute when creating a new descript.ion

Folder:

- Current: Active panel in TC = where file comments are to be copied to
- Target: Source panel in TC = where file comments from descript.ion to use are read from
- All files: toggle between processing selected and all files in current or target folder

Actions:

- F4 Edit: Edit current comment
- F8 Del: Remove file from listview
- Help: Open this readme.md in notepad (or GH if it can't find readme.md)
- Cancel: Close TCSyncComments
- F5 Copy Comments: copy selected file comment(s) to (new) descript.ion

## Setup

* Add a button to the TC Button bar
* Add a Start menu
* Add a [User-defined command](https://www.ghisler.ch/wiki/index.php/User-defined_command)

```
Command    : path-to\TCSyncComments.ahk 
Parameters : %T %P %S
```

Reference: (source TC Help file)

```
%T inserts the current target path.
%P causes the source path to be inserted into the command line, including a backslash (\) at the end.
%S insert the names of all selected files into the command line.
   Names containing spaces will be surrounded by double quotes.
   Please note the maximum command line length of 32767 characters.
```

# Settings.ini

TCSyncComments stores the windows position and last used settings in Settings.ini 
located in TCSyncComments (script) folder.

### INI Icons

To use different icons add a section to `TCSyncComments.ini`

```ini
[Settings]
IconFile=\WCMICONS.DLL
DescIcon=29
FileIcon=63
FolderIcon=36
```

Notes:

* The IconFile path is set to `Commander_Path + IconFile`, so make it relative to the Total Commander program folder.
* DescIcon used for "descript.ion" (icon number in DLL)
* FileIcon used for "Match files" (icon number in DLL)
* FolderIcon used for "Folder" (icon number in DLL)

### Credits

* LV_Colors by just me - Source: https://github.com/AHK-just-me/Class_LV_Colors
* Sift (Ngram) by Fanatic Guru - Source: https://www.autohotkey.com/boards/viewtopic.php?t=7302
* AutoXYWH by toralf/tmplinshi - Source: http://ahkscript.org/boards/viewtopic.php?t=1079

### TC forum (ghisler.ch)

* [TCSyncComments thread](https://www.ghisler.ch/board/viewtopic.php?f=6&t=73131) - TC Plugins and addons: devel.+support (English)
* [Manual option to copy file comment descript.ion F5/F6, Shift+F5](https://ghisler.ch/board/viewtopic.php?f=14&t=72059) - TC Suggestions 

### License

See [The MIT License (MIT)](license.txt)
