Option Explicit
Dim app

Call dowork

'shut down the app
If not (app Is Nothing) Then
    app.Quit
    Set app = Nothing
End If


Sub dowork()
    On Error Resume Next
    '----
    ' Start up Enterprise Guide using the project name
    '----
    Dim prjName
    Dim prjObject

    prjName = "D:\Dropbox\GitHub\CRSP_local\SAS_study.egp"    'Project Name
      
    Set app = CreateObject("SASEGObjectModel.Application.6.1")
    If Checkerror("CreateObject") = True Then
        Exit Sub
    End If
    
    '-----
    ' open the project
    '-----
    Set prjObject = app.Open(prjName,"")
    If Checkerror("app.Open") = True Then
        Exit Sub
    End If
    
        
    '-----
    ' run the project
    '-----
    prjObject.run
    If Checkerror("Project.run") = True Then
        Exit Sub
    End If
    
            
    '-----
    ' Save the new project
    '-----
    prjObject.Save
    If Checkerror("Project.Save") = True Then
        Exit Sub
    End If
    
    '-----
    ' Close the project
    '-----
    prjObject.Close
    If Checkerror("Project.Close") = True Then
        Exit Sub
    End If
       
End Sub

Function Checkerror(fnName)
    Checkerror = False
    
    Dim strmsg
    Dim errNum
    
    If Err.Number <> 0 Then
        strmsg = "Error #" & Hex(Err.Number) & vbCrLf & "In Function " & fnName & vbCrLf & Err.Description
        'MsgBox strmsg  'Uncomment this line if you want to be notified via MessageBox of Errors in the script.
        Checkerror = True
    End If
         
End Function
