$SettingsFile = (Join-Path $PSScriptRoot "Resources\config.xml")
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
[xml]$Settings = Get-Content -Path $SettingsFile
[xml]$Items = Get-Content -Path (Join-Path $PSScriptRoot "Resources\items.xml")
$fileName = $Settings.Settings.Notes.XML
$xmlDoc = [System.Xml.XmlDocument](Get-Content $fileName)


function RunQuery {
    $sql = (join-path $Settings.Settings.Paths.SQLScript $Settings.Settings.Notes.SQLScript)
    $a = (Invoke-Sqlcmd -InputFile $sql -ServerInstance $Settings.Settings.Server.ServerInstance -Database $Settings.Settings.Server.Database)
    $theCnt = 0

    #make sure that all BITRs have entries in the file.
    do {
        $theCnt += 1
        foreach ($row in $a) {
            $matchFlag = 0
            foreach ($BITR in $xmlDoc.Items.BITR) {
                if ($row.ID -eq $BITR.ID) {
                    if ($row.Name -ne $BITR.name) {
                        $BITR.SetAttribute("name",$row.name)
                    }
                    if ($row.Description -ne $BITR.description) {
                        $BITR.SetAttribute("description",$row.Description)
                    }
                    if ($row.Owner -ne $BITR.owner) {
                        $BITR.SetAttribute("owner",$row.Owner)
                    }
                    if ($row."Current Status" -ne $BITR.owner) {
                        $BITR.SetAttribute("status",$row."Current Status")
                    }
                    $matchFlag = 1
                    break
                }
            }
            if ($matchFlag -ne 1) { #not found, so add the initial item
                $newXMLBITR = $xmlDoc.Items.AppendChild($xmlDoc.CreateElement("BITR"))
                $newXMLBITR.SetAttribute("id",$row.ID)
                $newXMLBITR.SetAttribute("active",1)
                $newXMLBITR.SetAttribute("name","")
                $newXMLBITR.SetAttribute("description","")
                $newXMLBITR.SetAttribute("owner","")
                $newXMLBITR.SetAttribute("status","")
            }
        }
    } until ($theCnt -ge 2)
    $xmlDoc.Save($fileName)
}

function SyncBITRandNotes ($forceReRun) {
    $minSinceQuery = $($($(NEW-TIMESPAN –Start $([datetime]$($Settings.Settings.Notes.LastQueryDateTime)) -End $(get-date)).TotalMinutes) -as [int])
    if (($minSinceQuery -gt $($Settings.Settings.Notes.MaxMinutesSinceLastQuery -as [int])) -or ($forceReRun -eq "1")) {
        RunQuery
        funcPopulateCombobox
        $Settings.Settings.Notes.LastQueryDateTime = $($(get-date).ToString("yyyy-MM-dd HH:mm:ss"))
        $Settings.Save($SettingsFile)
        $script:Settings = Get-Content -Path $SettingsFile
    }   
}

function DisplayNotes ($activeOnly, $forceReRun, $openFile) {
    SyncBITRandNotes -forceReRun $forceReRun
    Invoke-Expression $([string]::Format("{0} -activeOnly '{1}' -openFile '{2}'",$Settings.Settings.Paths.DisplayNotes,$activeOnly, $openFile))
}

function funcActive {
    $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    DisplayNotes -activeOnly 1 -forceReRun "0" -openFile "1"
    $frm.Cursor = [System.Windows.Forms.Cursors]::Default
}

function funcAll {
    $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    DisplayNotes -activeOnly 0 -forceReRun "0" -openFile "1"
    $frm.Cursor = [System.Windows.Forms.Cursors]::Default
}

function funcRerun {
    $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    DisplayNotes -activeOnly 1 -forceReRun "1" -openFile "1"
    $frm.Cursor = [System.Windows.Forms.Cursors]::Default
}
function funcCancel {
}

function funcSave {
    $BITRID = $cmbBITR.Text
    if ($BITRID) {
        $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $FollowUpDate = $txtFollowupDate.Text
        if ($FollowUpDate) {
            $days = "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday","Mon","Tue","Wed","Thu","Fri","Sat","Sun","Tom","Tomorrow" #for f/u date
            if ($FollowUpDate -in $days) {
                $dt = get-date
                do {
                    $dt = $dt.AddDays(1)
                    if (($dt.DayOfWeek -eq $FollowUpDate) -or ($dt.ToString("ddd") -eq $FollowUpDate) -or ($FollowUpDate -in "Tom","Tomorrow")) {
                        $FollowUpDate = $dt
                        break
                    }
                } until ($false)
            }
            $FollowUpDate = $(get-date $FollowUpDate).AddDays($(if ($(get-date $followupdate).DayOfWeek -eq "Saturday") {2} elseif ($(get-date $followupdate).DayOfWeek -eq "Sunday") {1} else {0}))
        }
        $Comment = $txtComment.Text
    
        foreach ($BITR in $xmldoc.Items.BITR | Where-Object {$_.ID -eq $cmbBITR.Text} ) {
            #active 
            $BITR.SetAttribute("active",$(if($chkInactive.Checked -eq $true) {0} {1})) 

            #f/u date
            if ($FollowUpDate) {$BITR.SetAttribute("followupdate",$(Get-Date $FollowUpDate -Format "yyyy-MM-dd"))}
        
            #Comment
            if ($Comment) {
                $newBITR = $BITR.AppendChild($xmlDoc.CreateElement("Comment"))
                $newBITR.SetAttribute("date",$(get-date))
                $newBITR.SetAttribute("text",$Comment)
            }
            break
        }
        $xmlDoc.Save($fileName)
        $txtFollowupDate.Text = ""
        $chkInactive.Checked = $false
        $txtLastComment.Text = ""
        $txtComment.Text = ""
        $cmbBITR.Text = ""
        DisplayNotes -activeOnly "1" -forceReRun "0" -openFile "0"
        [System.Windows.Forms.MessageBox]::Show("BITR Saved!","Success")
        $frm.Cursor = [System.Windows.Forms.Cursors]::Default
        $cmbBITR.Focus()
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Invalid BITR# Provided!","Failure")
    }
}

function funcCmbChanged {
    $txtFollowupDate.Text = ""
    $chkInactive.Checked = $false
    $txtLastComment.Text = ""
    $txtComment.Text = ""
    if ($cmbBITR.Text -in  $cmbBITR.Items) {
        foreach ($BITR in $xmldoc.Items.BITR | Where-Object {$_.ID -eq $cmbBITR.Text} ) {
            $txtFollowupDate.Text = $BITR.followupdate
            $chkInactive.Checked = $(if ($BITR.active -eq "1") {$false} else {$true})
            foreach ($Comment in $BITR.Comment | Sort-Object date -Descending) {
                $txtLastComment.Text = [string]::Format("{0}: {1}",$($(get-date $Comment.date -Format "yyyy-MM-dd")) ,$Comment.text)
                break
            }
        }
    }
}

function funcPopulateCombobox {
    $cmbBITR.Items.Clear()
    foreach ($BITR in $xmlDoc.Items.BITR | Sort-Object ID) {
        [void]$cmbBITR.Items.Add($BITR.ID)
    }
}

##################################################BUILD FORM##################################################
Add-Type -AssemblyName System.Windows.Forms
$frm = New-Object system.Windows.Forms.Form
$frm.Text = $Settings.Settings.NotesGUI.Text
$frm.TopMost = $Settings.Settings.NotesGUI.TopMost
$frm.Width =  $Settings.Settings.NotesGUI.Width
$frm.Height = $Settings.Settings.NotesGUI.Height
$frm.FormBorderStyle = $Settings.Settings.NotesGUI.FormBorderStyle
$frm.StartPosition = $Settings.Settings.NotesGUI.StartPosition
$frm.KeyPreview = $true

########################Buttons########################
#Active
$btn = New-Object system.windows.Forms.Button
$btn.Name = "btnActive"
$btn.Text = "Acti&ve Notes"
$btn.Width = 100
$btn.Height = 30
$btn.location = new-object system.drawing.point(25,360)
$btn.Font = "Microsoft Sans Serif,10"
$btn.add_Click({funcActive})
$btn.TabIndex = 6
$btn.TabStop = $true
$frm.controls.Add($btn)

#ALL
$btn = New-Object system.windows.Forms.Button
$btn.Name = "btnAll"
$btn.Text = "&All Notes"
$btn.Width = 100
$btn.Height = 30
$btn.location = new-object system.drawing.point(150,360)
$btn.Font = "Microsoft Sans Serif,10"
$btn.add_Click({funcAll})
$btn.TabIndex = 7
$btn.TabStop = $true
$frm.controls.Add($btn)

#ForceRerun
$btn = New-Object system.windows.Forms.Button
$btn.Name = "btnRerun"
$btn.Text = "Force &Rerun"
$btn.Width = 100
$btn.Height = 30
$btn.location = new-object system.drawing.point(275,360)
$btn.Font = "Microsoft Sans Serif,10"
$btn.add_Click({funcRerun})
$btn.TabIndex = 8
$btn.TabStop = $true
$frm.controls.Add($btn)

#Save
$btn = New-Object system.windows.Forms.Button
$btn.Name = "btnSave"
$btn.Text = "&Save"
$btn.Width = 100
$btn.Height = 30
$btn.location = new-object system.drawing.point(100,300)
$btn.Font = "Microsoft Sans Serif,10"
$btn.add_Click({funcSave})
$btn.TabIndex = 5
$btn.TabStop = $true
$frm.controls.Add($btn)

#Cancel
$btn = New-Object system.windows.Forms.Button
$btn.Name = "btnCancel"
$btn.Text = "&Cancel"
$btn.Width = 100
$btn.Height = 30
$btn.location = new-object system.drawing.point(225,300)
$btn.Font = "Microsoft Sans Serif,10"
$btn.add_Click({funcCancel})
$btn.TabStop = $false
$frm.controls.Add($btn)

########################Labels########################
#BITR
$lbl = New-Object system.windows.Forms.Label
$lbl.Name = "lblBITR"
$lbl.Text = "BITR:"
$lbl.Width = 100
$lbl.Height = 20
$lbl.Autosize = $false
$lbl.location = new-object system.drawing.point(25,25)
$lbl.Font = "Microsoft Sans Serif,10"
$lbl.TabStop = $false
$frm.controls.Add($lbl)

#Followup Date
$lbl = New-Object system.windows.Forms.Label
$lbl.Name = "lblFollowupDate"
$lbl.Text = "Follow up Date:"
$lbl.Width = 100
$lbl.Height = 20
$lbl.Autosize = $false
$lbl.location = new-object system.drawing.point(25,60)
$lbl.Font = "Microsoft Sans Serif,10"
$lbl.TabStop = $false
$frm.controls.Add($lbl)

#last Comment
$lbl = New-Object system.windows.Forms.Label
$lbl.Name = "lblLastComment"
$lbl.Text = "Last Comment:"
$lbl.Width = 100
$lbl.Height = 20
$lbl.Autosize = $false
$lbl.location = new-object system.drawing.point(25,95)
$lbl.Font = "Microsoft Sans Serif,10"
$lbl.TabStop = $false
$frm.controls.Add($lbl)

#Comment
$lbl = New-Object system.windows.Forms.Label
$lbl.Name = "lblComment"
$lbl.Text = "New Comment:"
$lbl.Width = 100
$lbl.Height = 20
$lbl.Autosize = $false
$lbl.location = new-object system.drawing.point(25,175)
$lbl.Font = "Microsoft Sans Serif,10"
$lbl.TabStop = $false
$frm.controls.Add($lbl)

#Inactive
$lbl = New-Object system.windows.Forms.Label
$lbl.Name = "lblinactive"
$lbl.Text = "Inactive:"
$lbl.Width = 100
$lbl.Height = 20
$lbl.Autosize = $false
$lbl.location = new-object system.drawing.point(25,260)
$lbl.Font = "Microsoft Sans Serif,10"
$lbl.TabStop = $false
$frm.controls.Add($lbl)

########################Combobox########################
#BITR
$cmb = New-Object System.Windows.Forms.ComboBox
$cmb.Name = "cmbBITR"
$cmb.Width = 150
$cmb.Height = 30
$cmb.Location = New-Object System.Drawing.Point(150,20)
$cmb.Font = "Microsoft Sans Serif,10"
$cmb.add_SelectedIndexChanged({funcCmbChanged})
$cmb.add_KeyUp({funcCmbChanged})
$cmb.TabIndex = 1
$cmb.TabStop = $true
$frm.Controls.Add($cmb)

########################TextBox########################
#Followup Date
$txt = New-Object system.windows.Forms.TextBox
$txt.Name = "txtFollowupDate"
$txt.Width = 150
$txt.Height = 30
$txt.Multiline = $false
$txt.location = new-object system.drawing.point(150, 55)
$txt.Font = "Microsoft Sans Serif,10"
$txt.TabIndex = 2
$txt.TabStop = $true
$frm.controls.Add($txt)

#Last Comment
$txt = New-Object system.windows.Forms.TextBox
$txt.Name = "txtLastComment"
$txt.Width = 225
$txt.Height = 80
$txt.Multiline = $true
$txt.location = new-object system.drawing.point(150, 90)
$txt.Font = "Microsoft Sans Serif,10"
$txt.TabStop = $false
$txt.ReadOnly = $true
$frm.controls.Add($txt)
   
#Comment
$txt = New-Object system.windows.Forms.TextBox
$txt.Name = "txtComment"
$txt.Width = 225
$txt.Height = 80
$txt.Multiline = $true
$txt.location = new-object system.drawing.point(150, 175)
$txt.Font = "Microsoft Sans Serif,10"
$txt.TabIndex = 3
$txt.TabStop = $true
$frm.controls.Add($txt)

########################Checkbox########################
#Inactive
$chk = New-Object system.windows.Forms.CheckBox
$chk.Name = "chkInactive"
$chk.Width = 20
$chk.Height = 20
$chk.location = new-object system.drawing.point(215, 260)
$chk.Font = "Microsoft Sans Serif,10"
$chk.TabIndex = 4
$chk.TabStop = $true
$frm.controls.Add($chk)


$cmbBITR = [System.Windows.Forms.ComboBox]$frm.Controls.Item("cmbBITR")
$txtFollowupDate = [System.Windows.Forms.TextBox]$frm.Controls.Item("txtFollowupDate")
$txtComment = [System.Windows.Forms.TextBox]$frm.Controls.Item("txtComment")
$txtLastComment = [System.Windows.Forms.TextBox]$frm.Controls.Item("txtLastComment")
$chkInactive = [System.Windows.Forms.Checkbox]$frm.Controls.Item("chkInactive")
$btnAll = [System.Windows.Forms.Button]$frm.Controls.Item("btnAll")
$btnActive = [System.Windows.Forms.Button]$frm.Controls.Item("btnActive")
$btnSave = [System.Windows.Forms.Button]$frm.Controls.Item("btnSave")
$btnCancel = [System.Windows.Forms.Button]$frm.Controls.Item("btnCancel")
$btnForceRerun = [System.Windows.Forms.Button]$frm.Controls.Item("btnForceRerun")
$frm.CancelButton = $btnCancel
$frm.AcceptButton = $btnSave

funcPopulateCombobox

[void]$frm.ShowDialog()