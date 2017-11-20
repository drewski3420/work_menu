function Time {
    Invoke-Expression $([string]::Format("{0} -PS1 '{1}' -TXT '{2}' -SQL '{3}'",$Settings.Settings.Paths.Run,$Settings.Settings.Time.PS1,$Settings.Settings.Time.TXT, $Settings.Settings.Time.SQL))
}

function APOD {
    Start-Process $Settings.Settings.Paths.APOD
}

function Backup {
    Start-Process $Settings.Settings.Paths.Backup
}

function Searching ($arg1) {
    $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    Invoke-Expression $([string]::Format("{0} -searchfor '{1}'",$Settings.Settings.Paths.Search,$arg1))
    $frm.Cursor = [System.Windows.Forms.Cursors]::Default
}

function LaunchIt ($arg1) {
    $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    Invoke-Expression $([string]::Format("{0} -process '{1}' -exe '{2}'",$Settings.Settings.Paths.Launch,$arg1.Process,$arg1.EXE))
    $frm.Cursor = [System.Windows.Forms.Cursors]::Default
}

function KillIt ($arg1) {
    $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    Invoke-Expression $([string]::Format("{0} -process '{1}'",$Settings.Settings.Paths.Kill,$arg1.Process))
    $frm.Cursor = [System.Windows.Forms.Cursors]::Default
}    

function Launching ($selection) {
    $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $programs = $Items.Items.Programs
    if ($selection.Length -eq 1) {
		foreach($item in $programs.Program) {
			if (($item.Abbreviation -eq $selection) -or (($selection -eq $allvar) -and ($item.Abbreviation -ne ""))) {
				LaunchIt -arg1 $item
            }
        }
    }
    else {
        foreach ($item in $programs.Program) {
            foreach ($keyword in $item.Keywords.Keyword) {
                if ($keyword -eq $selection) {
                    LaunchIt -arg1 $item
                    break
                }
            }
        }
    }
    ##Start-Sleep -m 1500
    $frm.Cursor = [System.Windows.Forms.Cursors]::Default
}

function Killing ($selection) {
    $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $programs = $Items.Items.Programs
    if ($selection.Length -eq 1) {
		foreach ($item in $programs.Program) {
			if (($item.Abbreviation -eq $selection) -or (($selection -eq $allvar) -and ($item.Abbreviation -ne ""))) { 
				KillIt -arg1 $item
            }
        }
    }
    else {
        foreach ($item in $programs.Program) {
            foreach ($keyword in $item.Keywords.Keyword) {
                if ($keyword -eq $selection) {
                    Killit -arg1 $item
                    break
                }
            }
        }
    }
    $frm.Cursor = [System.Windows.Forms.Cursors]::Default
}

function funcCmbChanged {
    $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    $txtFollowupDate.Text = ""
    $chkInactive.Checked = $false
    $txtLastComment.Text = ""
    $txtComment.Text = ""
    if ($cmbBITR.Text -in  $cmbBITR.Items) {
        foreach ($BITR in $xmldoc.Items.BITR | Where-Object {$_.ID -eq $cmbBITR.Text} ) {
            $txtFollowupDate.Text = $BITR.followupdate
            $chkInactive.Checked = $(if ($BITR.active -eq "1") {$false} else {$true})
            foreach ($Comment in $BITR.Comment | Sort-Object $_.date -Descending) {
                $txtLastComment.Text = [string]::Format("{0}: {1}",$($(get-date $Comment.date -Format "yyyy-MM-dd")) ,$Comment.text)
            }
        }
    }
    $frm.Cursor = [System.Windows.Forms.Cursors]::Default
}

function funcActive {
    $frm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    
    [xml]$Settings = Get-Content -Path (Join-Path $PSScriptRoot "Resources\config.xml")
    [xml]$Items = Get-Content -Path (Join-Path $PSScriptRoot "Resources\items.xml")
    $input = $txtMain.Text
    $i = $input.split(" ")
    if ($i[0] -eq $rebootvar) {
        shutdown /s /f /t 10
        exit
    }
    elseif ($i[0] -eq $backupvar) {
        Backup
    }
    elseif ($i[0] -eq $bitrvar) {
        BITRing
    }
    elseif ($i[0] -eq $timevar) {
        Time
    }
    elseif ($i[0] -eq $APODVar) {
        APOD
    }
    elseif ($i[0].Length -ne 1) {
        [System.Windows.MessageBox]::Show("Provide a valid command","Failure")
    }
    elseif ($i[1].Length -eq 0) {
        [System.Windows.MessageBox]::Show("Provide a valid keyword","Failure")
    }
    else {
        switch ($i[0]) {
            $launchvar {
                Launching -selection $i[1]
            }
            $killvar {
                Killing -selection $i[1]
            }
            $searchvar {
                foreach ($term in $i[1..($i.Length-1)]) {
                    if (($term).Length -in 1,2) {
                        [System.Windows.MessageBox]::Show("Search Term must be 3 characters or more","Failure")
                        $waserror = 1
                        break
                    }
                }
                if ($waserror -ne 1) {
                    Searching -arg1 $([string]$i)
                }
            }
        }
    } 
    $txtMain.Text = ""
    $txtMain.Focus()
    $frm.Cursor = [System.Windows.Forms.Cursors]::Default
}


function NotesForm {
    Invoke-Expression $([string]::Format("powershell -WindowStyle Hidden -file {0}",$Settings.Settings.Paths.Notes))
    $txtMain.Focus()
}

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
[xml]$Settings = Get-Content -Path (Join-Path $PSScriptRoot "Resources\config.xml")
[xml]$Items = Get-Content -Path (Join-Path $PSScriptRoot "Resources\items.xml")
Add-Type -AssemblyName PresentationCore,PresentationFramework

#Global vars
$launchvar  = $Settings.Settings.Vars.LaunchVar
$killvar    = $Settings.Settings.Vars.KillVar
$searchvar  = $Settings.Settings.Vars.SearchVar
$quitvar    = $Settings.Settings.Vars.QuitVar
$allvar     = $Settings.Settings.Vars.AllVar
$rebootvar  = $Settings.Settings.Vars.RebootVar
$backupvar  = $Settings.Settings.Vars.BackupVar
$APODvar    = $Settings.Settings.Vars.APODVar
$timevar    = $Settings.Settings.Vars.TimeVar

APOD
Backup
Time

##################################################BUILD FORM##################################################
Add-Type -AssemblyName System.Windows.Forms
$frm = New-Object system.Windows.Forms.Form
$frm.Text = $Settings.Settings.MenuGui.Text
$frm.TopMost = $Settings.Settings.MenuGui.TopMost
$frm.Width =  $Settings.Settings.MenuGui.Width
$frm.Height = $Settings.Settings.MenuGui.Height
$frm.FormBorderStyle = $Settings.Settings.MenuGui.FormBorderStyle
$frm.StartPosition = $Settings.Settings.MenuGui.StartPosition
foreach ($s in [system.windows.forms.screen]::AllScreens) {
    if ($s.Primary -eq $true) {
        write-host $s.WorkingArea.Height
        write-host $Settings.Settings.Height
        $top = $s.WorkingArea.Height - $Settings.Settings.MenuGui.Height
        $left = $s.WorkingArea.Width - $Settings.Settings.MenuGui.Width
    }
}
$frm.Location = new-object system.drawing.point($left,$top)
$frm.KeyPreview = $true


########################Buttons########################
$btn = New-Object system.windows.Forms.Button
$btn.Name = "btnGo"
$btn.Text = "&Process"
$btn.Width = 100
$btn.Height = 30
$btn.location = new-object system.drawing.point(50,60)
$btn.Font = "Microsoft Sans Serif,10"
$btn.add_Click({funcActive})
#$btn.TabIndex = 2
$btn.TabStop = $false
$frm.controls.Add($btn)

$btn = New-Object system.windows.Forms.Button
$btn.Name = "btnNotes"
$btn.Text = "&Notes"
$btn.Width = 100
$btn.Height = 30
$btn.location = new-object system.drawing.point(50,95)
$btn.Font = "Microsoft Sans Serif,10"
$btn.add_Click({NotesForm})
#$btn.TabIndex = 2
$btn.TabStop = $false
$frm.controls.Add($btn)

########################TextBox########################
#Followup Date
$txt = New-Object system.windows.Forms.TextBox
$txt.Name = "txtMain"
$txt.Width = 150
$txt.Height = 30
$txt.Multiline = $false
$txt.location = new-object system.drawing.point(25, 20)
$txt.Font = "Microsoft Sans Serif,10"
$txt.TabIndex = 1
$txt.TabStop = $true
$frm.controls.Add($txt)

$txtMain = [System.Windows.Forms.TextBox]$frm.Controls.Item("txtMain")
$btnGo = [System.Windows.Forms.Button]$frm.Controls.Item("btnGo")
$frm.AcceptButton = $btnGo

$frm.ShowDialog()