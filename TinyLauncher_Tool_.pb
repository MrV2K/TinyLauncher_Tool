;- TinyLauncher Tool
;
; Version 0.2 Alpha
;
; © 2021 Paul Vince (MrV2k)
;
; https://easymame.mameworld.info
;
; [ PB V5.7x/V6.x / 32Bit / 64Bit / Windows / DPI ]
;
; A converter for TinyLauncher DB files.
;
; ====================================================================
;
; Initial Release
;
; ====================================================================
;
; Version 0.2
;
; Fixed bug if game folders are in the root of the drive path
; Added ability to save in different cases
;
; ====================================================================
;
;- ### Enumerations ###

EnableExplicit

Enumeration
  #MAIN_WINDOW
  #MAIN_LIST
  #LOAD_BUTTON
  #SAVE_BUTTON
  #FIX_BUTTON
  #CLEAR_BUTTON
  #HELP_BUTTON
  #TAG_BUTTON
  #UNDO_BUTTON
  #HELP_WINDOW
  #LOADING_WINDOW
  #HELP_EDITOR
  #SHORT_NAME_CHECK
  #DUPE_CHECK
  #UNKNOWN_CHECK
  #FTP 
  #EDIT_WINDOW
  #EDIT_NAME
  #EDIT_SHORT
  #EDIT_SLAVE
  #CASE_COMBO
EndEnumeration

;- ### Structures ###

Structure IG_Data
  IG_Name.s
  IG_Path.s
  IG_Genre.s
  IG_Slave.s
  IG_Short.s
  IG_Icon.s
  IG_Folder.s
  IG_Filtered.b
  IG_Unknown.b
EndStructure

Structure Comp_Data
  C_Name.s
  C_Short.s
  C_Slave.s
  C_Folder.s
  C_Genre.s
  C_Icon.s
EndStructure

;- ### Lists ###

Global NewList IG_Database.IG_Data()
Global NewList Undo_Database.IG_Data()
Global NewList Comp_Database.Comp_Data()
Global NewList Filtered_List.i()

;- ### Global Variables ###

Global Prog_Title.s="TinyLauncher Tool"
Global Version.s="0.1 Alpha"
Global Keep_Data.b=#True
Global Short_Names.b=#False
Global Filter.b=#False
Global Unknown.b=#False
Global event, gadget, close.b
Global Name.s, CSV_Path.s
Global Home_Path.s=GetCurrentDirectory()
Global Prefs_Type=0
Global Output_Case.i=0

;- ### Macros ###

Macro Pause_Window(window)
  SendMessage_(WindowID(window),#WM_SETREDRAW,#False,0)
EndMacro

Macro Resume_Window(window)
  SendMessage_(WindowID(window),#WM_SETREDRAW,#True,0)
  RedrawWindow_(WindowID(window),#Null,#Null,#RDW_INVALIDATE)
EndMacro

Macro Message_Window(message)
  OpenWindow(#LOADING_WINDOW,0,0,150,50,message,#PB_Window_Tool|#PB_Window_WindowCentered,WindowID(#MAIN_WINDOW))
  TextGadget(#PB_Any,10,12,130,25,"Please Wait...", #PB_Text_Center)
EndMacro

Macro Backup_Database(state)
  
  CopyList(IG_Database(),Undo_Database())
  DisableGadget(#UNDO_BUTTON,state)
  
EndMacro

;- ### Procedures ###

Procedure Save_CSV()
      
  Protected igfile, output$, path.s, response
  Protected path$, slave$, title$
  path=""
  
  If FileSize(CSV_Path)>-1
    response=MessageRequester("Warning","Overwrite Old Game List?"+Chr(10)+"Select 'No' to create a new file.",#PB_MessageRequester_YesNoCancel|#PB_MessageRequester_Warning)
    Select response
      Case #PB_MessageRequester_Yes : path=CSV_Path
      Case #PB_MessageRequester_No : path=OpenFileRequester("New File", "", "TinyLauncher File (*.db)|*.db",0)
    EndSelect 
  EndIf
  
  If GetExtensionPart(path)<>"db" : path+".db" : EndIf
  
  If response<>#PB_MessageRequester_Cancel And path<>""
    If CreateFile(igfile, path,#PB_Ascii)     
      ForEach IG_Database()
        path$=LSet(IG_Database()\IG_Path+Chr(1),128) 
        slave$=LSet(IG_Database()\IG_Slave+Chr(1),42)
        Select Output_Case
          Case 0 : title$=LSet(IG_Database()\IG_Short+Chr(1),48)
          Case 1 : title$=LCase(LSet(IG_Database()\IG_Short+Chr(1),48))
          Case 2 : title$=UCase(LSet(IG_Database()\IG_Short+Chr(1),48))       
        EndSelect
        output$+path$+slave$+title$  
      Next
      WriteStringN(igfile,output$)
      FlushFileBuffers(igfile)
      CloseFile(igfile)  
    EndIf
  EndIf
  
EndProcedure

Procedure Load_CSV()

  Protected CSV_File.i, Text_Data.s, Text_String.s
  Protected Count.i, I.i, Backslashes.i, Text_Line.s, Full_String.s, Game_Name.s, Slave_Name.s, Path_Name.s
  
  CSV_Path=OpenFileRequester("Open TinyLauncher","Games.db","TinyLauncher File (*.db)|*.db",0)
  
  If CSV_Path<>""
    
    CSV_File=ReadFile(#PB_Any,CSV_Path,#PB_Ascii)
    
    If CSV_File<>-1
      
      Message_Window("Loading Game List...")
      
      While Not Eof(CSV_File)
        Text_String=ReadString(CSV_File,#PB_Ascii,218)
        Text_Data+Text_String+#LF$
        While WindowEvent() : Wend
      Wend
      
      If Text_Data="" : Goto Proc_Exit : EndIf
      
      CloseFile(CSV_File)  
      
      Count=CountString(Text_Data,#LF$)
      
      ClearList(IG_Database())
      
      For i=1 To count
        Path_Name=Mid(StringField(Text_Data,i,#LF$),1,128)
        Slave_Name=Mid(StringField(Text_Data,i,#LF$),129,42)
        Game_Name=Mid(StringField(Text_Data,i,#LF$),171,48)
        Path_Name=Trim(RemoveString(Path_Name,Chr(1)))
        Slave_Name=Trim(RemoveString(Slave_Name,Chr(1)))
        Game_Name=Trim(RemoveString(Game_Name,Chr(1)))
        AddElement(IG_Database())
        IG_Database()\IG_Slave=Slave_Name
        IG_Database()\IG_Name=Game_Name
        IG_Database()\IG_Path=Path_Name
        If CountString(IG_Database()\IG_Path,"/")>1
          Backslashes=CountString(IG_Database()\IG_Path,"/")
          IG_Database()\IG_Folder=StringField(IG_Database()\IG_Path,Backslashes+1,"/")
        Else
          Backslashes=CountString(IG_Database()\IG_Path,":")
          IG_Database()\IG_Folder=StringField(IG_Database()\IG_Path,Backslashes+1,":")
          IG_Database()\IG_Folder=RemoveString(IG_Database()\IG_Folder,"/")
        EndIf
      Next
      
      DisableGadget(#FIX_BUTTON,#False)
      DisableGadget(#CLEAR_BUTTON,#False)
      DisableGadget(#TAG_BUTTON,#False)
      DisableGadget(#DUPE_CHECK,#False)
      
      CloseWindow(#LOADING_WINDOW)
      
    EndIf
    
  Else
    MessageRequester("Error", "No File Selected!", #PB_MessageRequester_Error|#PB_MessageRequester_Ok)
  EndIf  
  
  SortStructuredList(IG_Database(),#PB_Sort_Ascending|#PB_Sort_NoCase,OffsetOf(IG_Data\IG_Name),TypeOf(IG_Data\IG_Name))

  Backup_Database(#True)
  
  Proc_Exit:
  
EndProcedure

Procedure Filter_List()
   
  Protected Previous.s
  
  ClearList(Filtered_List())
  
  ForEach IG_Database()  
    IG_Database()\IG_Filtered=#False
    If Filter
      If IG_Database()\IG_Name=Previous   
        IG_Database()\IG_Filtered=#True
        PreviousElement(IG_Database())
        IG_Database()\IG_Filtered=#True
        NextElement(IG_Database())
      EndIf     
      previous=IG_Database()\IG_Name
    EndIf
    If Unknown
      If IG_Database()\IG_Unknown=#True
        IG_Database()\IG_Filtered=#True
      EndIf
    EndIf
  Next
  
  ForEach IG_Database()
    If IG_Database()\IG_Filtered=#True
      AddElement(Filtered_List())
      Filtered_List()=ListIndex(IG_Database())
    EndIf
  Next
    
EndProcedure

Procedure Load_DB()
  
  Protected CSV_File.i, Path.s, Text_Data.s, Text_String.s
  Protected Count.i, I.i, Backslashes.i, Text_Line.s
  
  path=Home_Path+"IG_Data"
  
  If path<>""
    
    If ReadFile(CSV_File,Path,#PB_Ascii)
      Repeat
        Text_String=ReadString(CSV_File)
        Text_Data+Text_String+#LF$
      Until Eof(CSV_File)
      CloseFile(CSV_File)  
    EndIf

    Count=CountString(Text_Data,#LF$)
    
    For i=1 To count
      AddElement(Comp_Database())
      Text_Line=StringField(Text_Data,i,#LF$)
      Comp_Database()\C_Slave=LCase(StringField(Text_Line,1,";"))
      Comp_Database()\C_Folder=StringField(Text_Line,2,";")
      Comp_Database()\C_Genre=StringField(Text_Line,3,";")
      Comp_Database()\C_Name=StringField(Text_Line,4,";")
      Comp_Database()\C_Short=StringField(Text_Line,5,";")
      Comp_Database()\C_Icon=StringField(Text_Line,6,";")
    Next
    
  EndIf  
  
  SortStructuredList(IG_Database(),#PB_Sort_Ascending|#PB_Sort_NoCase,OffsetOf(IG_Data\IG_Name),TypeOf(IG_Data\IG_Name))
  
EndProcedure

Procedure Draw_List()
  
  Protected Text.s, File.s
  Protected Count
  
  Pause_Window(#MAIN_WINDOW)
  
  ClearGadgetItems(#MAIN_LIST)
  
  ClearList(Filtered_List())
  
  If filter Or unknown
    Filter_List()
  Else
    ForEach IG_Database()
      IG_Database()\IG_Filtered=#False
      AddElement(Filtered_List())
      Filtered_List()=ListIndex(IG_Database())
    Next
  EndIf

  ForEach Filtered_List()
    SelectElement(IG_Database(),Filtered_List())
    If IG_Database()\IG_Slave<>"" : File=IG_Database()\IG_Slave : EndIf
    If IG_Database()\IG_Icon<>"" : File=IG_Database()\IG_Icon : EndIf
    If Short_Names
      Text=IG_Database()\IG_Short+Chr(10)+File+Chr(10)+IG_Database()\IG_Path+Chr(10)+IG_Database()\IG_Genre
    Else
      Text=IG_Database()\IG_Name+Chr(10)+File+Chr(10)+IG_Database()\IG_Path+Chr(10)+IG_Database()\IG_Genre
    EndIf
    AddGadgetItem(#MAIN_LIST,-1,text)
    If ListIndex(IG_Database())>1
      If GetGadgetItemText(#MAIN_LIST, ListIndex(Filtered_List())-1,0)=IG_Database()\IG_Name
        SetGadgetItemColor(#MAIN_LIST, ListIndex(Filtered_List()), #PB_Gadget_FrontColor,#Red)
        SetGadgetItemColor(#MAIN_LIST, ListIndex(Filtered_List())-1, #PB_Gadget_FrontColor,#Red)
      EndIf
    EndIf 
    If IG_Database()\IG_Unknown=#True : SetGadgetItemColor(#MAIN_LIST, ListIndex(Filtered_List()), #PB_Gadget_FrontColor,#Blue) : EndIf
  Next
  
  For Count=0 To CountGadgetItems(#MAIN_LIST) Step 2
    SetGadgetItemColor(#MAIN_LIST,Count,#PB_Gadget_BackColor,$eeeeee)
  Next
  
  SetWindowTitle(#MAIN_WINDOW, Prog_Title+" "+Version+" (Showing "+Str(CountGadgetItems(#MAIN_LIST))+" of "+Str(ListSize(IG_Database()))+" Games)")
  
  SetGadgetState(#MAIN_LIST,0)
  SetActiveGadget(#MAIN_LIST)
  
  If ListSize(Filtered_List())<>0
    DisableGadget(#TAG_BUTTON,#False)
  Else
    DisableGadget(#TAG_BUTTON,#True)
  EndIf
    
  Resume_Window(#MAIN_WINDOW)
  
EndProcedure

Procedure Fix_List()
  
  Backup_Database(#False)
  
  Message_Window("Fixing Game List...")
  
  Protected NewMap Comp_Map.i()
  
  Protected File.s
  
  Load_DB()
    
  ForEach Comp_Database()
    Comp_Map(LCase(Comp_Database()\C_Folder+"_"+Comp_Database()\C_Slave))=ListIndex(Comp_Database())
  Next
  
  ForEach IG_Database() 
    If FindMapElement(Comp_Map(),LCase(IG_Database()\IG_Folder+"_"+IG_Database()\IG_Slave))
      SelectElement(Comp_Database(),Comp_Map())
      IG_Database()\IG_Name=Comp_Database()\C_Name
      IG_Database()\IG_Short=Comp_Database()\C_Short
    EndIf
    If Not FindMapElement(Comp_Map(),LCase(IG_Database()\IG_Folder+"_"+IG_Database()\IG_Slave))
      IG_Database()\IG_Unknown=#True
    EndIf
  Next
  
  FreeMap(Comp_Map())
  ClearList(Comp_Database())
  
  SortStructuredList(IG_Database(),#PB_Sort_Ascending|#PB_Sort_NoCase,OffsetOf(IG_Data\IG_Name),TypeOf(IG_Data\IG_Name))
  
  DisableGadget(#SHORT_NAME_CHECK,#False)
  DisableGadget(#UNKNOWN_CHECK,#False)
  DisableGadget(#SHORT_NAME_CHECK,#False)
  DisableGadget(#SAVE_BUTTON,#False)
  Short_Names=#True
  SetGadgetState(#SHORT_NAME_CHECK,Short_Names)

  CloseWindow(#LOADING_WINDOW)
  
EndProcedure

Procedure Tag_List()
  
  Backup_Database(#False)
  
  Protected NewList Tags.i()
  Protected NewList Lines.i()
  
  Protected i, tag_entry.s
  
  For i=0 To CountGadgetItems(#MAIN_LIST)
    If GetGadgetItemState(#MAIN_LIST,i)=#PB_ListIcon_Selected
      SelectElement(Filtered_List(),i)
      SelectElement(IG_Database(),Filtered_List())
      AddElement(Tags())
      Tags()=ListIndex(IG_Database())
      AddElement(Lines())
      Lines()=i
    EndIf
  Next
  
  tag_entry=InputRequester("Add Tag", "Enter a new tag", "")
  
  If tag_entry<>""
    ForEach Tags()
      SelectElement(IG_Database(),Tags())
      IG_Database()\IG_Name=IG_Database()\IG_Name+" ("+tag_entry+")"
      SelectElement(Lines(),ListIndex(Tags()))
      SetGadgetItemText(#MAIN_LIST,Lines(),IG_Database()\IG_Name,0)
    Next
    ;Draw_List()
  EndIf
  
  FreeList(Tags())
  FreeList(Lines())
    
EndProcedure

Procedure Help_Window()
  
  Protected output$, output2$
  
  output$=""
  output$+"*** About ***"+Chr(10)
  output$+""+Chr(10)
  output$+"TinyLauncher Tool is a small utility that uses a small database to add better names to TinyLauncher DB files. TinyLauncher Tool is not perfect and "
  output$+"isn't clever enough to find some files and will still duplicate some entries, but it is still better than the default list. There is some basic editing "
  output$+"that can be done to the entries to help repair any errors."+Chr(10)
  output$+""+Chr(10)
  output$+"*** Instructions ***"+Chr(10)
  output$+""+Chr(10)
  output$+"1. Copy the Games.db / Demos.db files from the S:TinyLauncher drawer on your Amiga to your PC. Also... MAKE A BACKUP!"+Chr(10)
  output$+"2. Press the 'Load DB' button to open your TinyLauncher DB file."+Chr(10)
  output$+"3. Press the 'Fix List' button to fix the game names. The game names will default to short names as TinyLauncher uses a low res screen and some of the full names will be cropped."
  output$+" You can change this back by de-selecting the 'Use Short Names' box."+Chr(10)
  output$+"4. Make any other changes."+Chr(10)
  output$+"5. Press the 'Save DB' button to save the new DB file. You can overwrite the old game list or save as a new file."+Chr(10)
  output$+"6. Copy the new list back to the S:TinyLauncher drawer on your Amiga drive."+Chr(10)
  output$+""+Chr(10)
  output$+"*** Games List ***"+Chr(10)
  output$+""+Chr(10)
  output$+"Duplicate entries are highlighted in red and unknown entries are highlighted in blue. Missing entries will only be highlighted after you have pressed the 'Fix List' button."+Chr(10)
  output$+""+Chr(10)
  output$+"*** Editing ***"+Chr(10)
  output$+""+Chr(10)
  output$+"To edit a name, double click the entry on the list and change it's name in the new window."+Chr(10)
  output$+""+Chr(10)
  output$+"'Quick Tag' allows you can add multiple tags to the list entries. Just type the tag name into the new window and it will add it to the end of the game name."
  output$+" You can easily reduce any duplicate entries by using this button. Quick Tag will work with multiple selected entries. Use Ctrl or Shift when you click"
  output$+" the list to select multiple entries."+Chr(10)
  output$+""+Chr(10)
  output$+"'Undo' will reverse the last change that was made."+Chr(10)
  output$+""+Chr(10)
  output$+"*** Database ***"+Chr(10)
  output$+""+Chr(10)
  output$+"'Use Short Names' replaces the game name with a 26 character short version."+Chr(10)
  output$+""+Chr(10)
  output$+"*** Filter ***"+Chr(10)
  output$+""+Chr(10)
  output$+"'Show Duplicates' filters the list and shows duplicate entries."+Chr(10)
  output$+""+Chr(10)
  output$+"'Show Unknown' filters the list and shows unknown entries. If an entry is marked as unknown, it may be worth checking to see it the slave has been updated."+Chr(10)
  
  If OpenWindow(#HELP_WINDOW,0,0,400,450,"Help",#PB_Window_SystemMenu|#PB_Window_WindowCentered,WindowID(#MAIN_WINDOW))
    EditorGadget(#HELP_EDITOR,0,0,400,450,#PB_Editor_ReadOnly|#PB_Editor_WordWrap)
    DestroyCaret_()
  EndIf
  
  If IsGadget(#HELP_EDITOR)
    SetGadgetText(#HELP_EDITOR,output$)
  EndIf
  
  SetActiveWindow(#HELP_WINDOW)
  
EndProcedure 

Procedure Edit_Window()
  
  Backup_Database(#False)
  
  If OpenWindow(#EDIT_WINDOW,0,0,300,95,"Edit",#PB_Window_SystemMenu|#PB_Window_WindowCentered,WindowID(#MAIN_WINDOW))
    
    TextGadget(#PB_Any,5,8,50,24,"Name",#PB_Text_Center)
    StringGadget(#EDIT_NAME,55,5,240,24,IG_Database()\IG_Name)
    
    TextGadget(#PB_Any,5,38,50,24,"Short",#PB_Text_Center)
    StringGadget(#EDIT_SHORT,55,35,240,24,IG_Database()\IG_Short)
    If IG_Database()\IG_Short="" : DisableGadget(#EDIT_SHORT,#True) : EndIf
    
    TextGadget(#PB_Any,5,68,50,24,"Slave",#PB_Text_Center)
    StringGadget(#EDIT_SLAVE,55,65,240,24,IG_Database()\IG_Slave)
    
  EndIf
  
EndProcedure

Procedure Main_Window()

  If OpenWindow(#MAIN_WINDOW,0,0,900,600,Prog_Title+" "+Version,#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
    
    Pause_Window(#MAIN_WINDOW)
    
    ListIconGadget(#MAIN_LIST,0,0,900,550,"Name",340,#PB_ListIcon_GridLines|#PB_ListIcon_FullRowSelect|#PB_ListIcon_MultiSelect)
    SetGadgetColor(#MAIN_LIST,#PB_Gadget_BackColor,#White)
    AddGadgetColumn(#MAIN_LIST,1,"Slave",200)
    AddGadgetColumn(#MAIN_LIST,2,"Path",340)

    ButtonGadget(#LOAD_BUTTON,5,555,80,40,"Load DB")
    ButtonGadget(#FIX_BUTTON,90,555,80,40,"Fix List")
    ButtonGadget(#SAVE_BUTTON,175,555,80,40,"Save DB")
    ButtonGadget(#TAG_BUTTON,260,555,80,40,"Quick Tag")
    ButtonGadget(#CLEAR_BUTTON,345,555,80,40,"Clear List")
    ButtonGadget(#UNDO_BUTTON,430,555,80,40,"Undo")
    ButtonGadget(#HELP_BUTTON,815,555,80,40,"Help")
    
    CheckBoxGadget(#SHORT_NAME_CHECK,535,553,120,22,"Use Short Names")
    CheckBoxGadget(#DUPE_CHECK,660,553,105,22,"Show Duplicates")
    CheckBoxGadget(#UNKNOWN_CHECK,535,573,105,22,"Show Unknown")
    
    ComboBoxGadget(#CASE_COMBO,660,575,105,20)
    AddGadgetItem(#CASE_COMBO,-1,"Ignore Case")
    AddGadgetItem(#CASE_COMBO,-1,"Lower Case")
    AddGadgetItem(#CASE_COMBO,-1,"Upper Case")

    SetGadgetState(#CASE_COMBO,Output_Case)
    SetGadgetState(#SHORT_NAME_CHECK,Short_Names)
    SetGadgetState(#DUPE_CHECK,Filter)
    
    DisableGadget(#FIX_BUTTON,#True)
    DisableGadget(#SAVE_BUTTON,#True)

    DisableGadget(#SHORT_NAME_CHECK,#True)
    DisableGadget(#CLEAR_BUTTON,#True)
    DisableGadget(#UNKNOWN_CHECK,#True)
    DisableGadget(#DUPE_CHECK,#True)
    DisableGadget(#TAG_BUTTON,#True)
    DisableGadget(#UNDO_BUTTON,#True)
    
    Resume_Window(#MAIN_WINDOW)
    
  EndIf
  
EndProcedure

Main_Window()

Repeat
  
  event=WaitWindowEvent()
  gadget=EventGadget()
  
  Select event
      
    Case #PB_Event_CloseWindow
      If EventWindow()=#HELP_WINDOW
        CloseWindow(#HELP_WINDOW)
      EndIf
      If EventWindow()=#EDIT_WINDOW
        CloseWindow(#EDIT_WINDOW)
        Define Text.s
        If Short_Names
          Text=IG_Database()\IG_Short+Chr(10)+IG_Database()\IG_Slave+Chr(10)+IG_Database()\IG_Path
        Else
          Text=IG_Database()\IG_Name+Chr(10)+IG_Database()\IG_Slave+Chr(10)+IG_Database()\IG_Path
        EndIf
        SetGadgetItemText(#MAIN_LIST,GetGadgetState(#MAIN_LIST),Text)
      EndIf
      If EventWindow()=#MAIN_WINDOW
        If MessageRequester("Exit TinyLauncher Tool", "Do you want to quit?",#PB_MessageRequester_YesNo|#PB_MessageRequester_Warning)=#PB_MessageRequester_Yes
          close=#True
        EndIf  
      EndIf
            
      Case #PB_Event_Gadget
      
      Select gadget
          
        Case #LOAD_BUTTON
          If ListSize(IG_Database())>0
            ClearList(IG_Database())
            Pause_Window(#MAIN_WINDOW)
            ClearGadgetItems(#MAIN_LIST)
            Resume_Window(#MAIN_WINDOW)
          EndIf
          SetWindowTitle(#MAIN_WINDOW,Prog_Title+" "+Version)
          Load_CSV()
          Draw_List()
          
        Case #SAVE_BUTTON
          Save_CSV()
          
        Case #UNDO_BUTTON
          If MessageRequester("Warning","Undo Last Change?",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo)=#PB_MessageRequester_Yes
            ClearList(IG_Database())
            CopyList(Undo_Database(),IG_Database())
            DisableGadget(#UNDO_BUTTON,#True)
            Draw_List()
          EndIf
          
        Case #FIX_BUTTON
          Fix_List()
          Draw_List()
          
        Case #TAG_BUTTON
          Tag_List()
                    
        Case #CLEAR_BUTTON
          If MessageRequester("Warning","Clear All Data?",#PB_MessageRequester_YesNo|#PB_MessageRequester_Warning)=#PB_MessageRequester_Yes
          FreeList(Undo_Database())
          FreeList(IG_Database())
          FreeList(Filtered_List())
          Pause_Window(#MAIN_WINDOW)
          ClearGadgetItems(#MAIN_LIST)
          DisableGadget(#FIX_BUTTON,#True)
          DisableGadget(#SAVE_BUTTON,#True)
          DisableGadget(#DUPE_CHECK,#True)
          DisableGadget(#SHORT_NAME_CHECK,#True)
          DisableGadget(#CLEAR_BUTTON,#True)
          DisableGadget(#TAG_BUTTON,#True)
          DisableGadget(#UNKNOWN_CHECK,#True)
          DisableGadget(#UNDO_BUTTON,#True)
          Unknown=#False
          Filter=#False
          Short_Names=#False
          SetGadgetState(#DUPE_CHECK,Filter)
          SetGadgetState(#UNKNOWN_CHECK,Unknown)
          SetGadgetState(#SHORT_NAME_CHECK,Short_Names)
          SetWindowTitle(#MAIN_WINDOW,Prog_Title+" "+Version)
          Global NewList IG_Database.IG_Data()
          Global NewList Undo_Database.IG_Data()
          Global NewList Filtered_List.i()
          Resume_Window(#MAIN_WINDOW)
          EndIf
          
        Case #HELP_BUTTON
          Help_Window()
          
        Case #SHORT_NAME_CHECK
          Short_Names=GetGadgetState(#SHORT_NAME_CHECK)
          If ListSize(IG_Database())>0
            Draw_List()
          EndIf
          
        Case #DUPE_CHECK
          Filter=GetGadgetState(#DUPE_CHECK)
          Draw_List()
          
        Case #UNKNOWN_CHECK
          Unknown=GetGadgetState(#UNKNOWN_CHECK)
          Draw_List()
          
        Case #CASE_COMBO
          If EventType()=#PB_EventType_Change
            Output_Case=GetGadgetState(#CASE_COMBO)
          EndIf
          
        Case #EDIT_NAME
          If EventType()=#PB_EventType_Change
            IG_Database()\IG_Name=GetGadgetText(#EDIT_NAME)
          EndIf
          
        Case #EDIT_SHORT
          If EventType()=#PB_EventType_Change
            IG_Database()\IG_Short=GetGadgetText(#EDIT_SHORT)
          EndIf
          
        Case #EDIT_SLAVE
          If EventType()=#PB_EventType_Change
            IG_Database()\IG_Slave=GetGadgetText(#EDIT_SLAVE)
          EndIf
          
        Case #MAIN_LIST
          If EventType()=#PB_EventType_LeftDoubleClick
            If ListSize(Filtered_List())>0
              SelectElement(Filtered_List(),GetGadgetState(#MAIN_LIST))
              SelectElement(IG_Database(),Filtered_List())
              Edit_Window()
            EndIf
            
          EndIf
          
      EndSelect
             
      
  EndSelect
  
Until close=#True

End
; IDE Options = PureBasic 6.00 Alpha 3 (Windows - x64)
; CursorPosition = 670
; FirstLine = 207
; Folding = AA9
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; UseIcon = boing.ico
; Executable = TinyLauncher_Tool_64.exe
; Compiler = PureBasic 6.00 Alpha 3 (Windows - x64)
; Debugger = Standalone
; IncludeVersionInfo
; VersionField0 = 0,0,0,2
; VersionField1 = 0,0,0,2
; VersionField2 = MrV2K
; VersionField3 = IGame Tool
; VersionField4 = 0.2 Alpha
; VersionField5 = 0.2 Alpha
; VersionField6 = IGame Conversion Tool
; VersionField7 = IG_Tool
; VersionField8 = IGame_Tool.exe
; VersionField9 = 2021 Paul Vince
; VersionField15 = VOS_NT
; VersionField16 = VFT_APP
; VersionField17 = 0809 English (United Kingdom)