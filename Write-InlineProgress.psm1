<#
.SYNOPSIS
   Module for writing progress, particularly for the VS Code Host which currently does not support Write-Progress
.DESCRIPTION
   Use this module to write progress of scripts.  It will write progress inline when the host is VS Code and execute Write-Progress when
   in native PowerShell
.EXAMPLE
    Write-InlineProgress -Activity $Activity -PercentComplete $percentcomplete

    This is my Activity statement: 80%
.PARAMETER Activity
	This parameter is manadatory and is in the form of a string

    $Activity = "This is my Activity statement:"
.PARAMETER PercentComplete
    This paramater is mandatory and is in the form of an integer

    $PercentComplete = 80
.NOTES
	Author: Travis M Knight; tmknight
	Date: 2017-10-25: tmknight: Inception
	Date: 2017-11-30: tmknight: Set percent complete to two decimal places
	Date: 2018-04-02: tmknight: Account for vscode-powershell 2.x which now supports Write-Progress
	Date: 2019-07-08: tmknight: Account for vscode-powershell-preview which now supports Write-Progress
	Date: 2020-10-14: tmknight: Number format to zero places.  Assessment of $PSHOME to match windows directory path format
.LINK
    https://msdn.microsoft.com/en-us/library/system.console(v=vs.110).aspx
#>

function Write-InlineProgress {
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$Activity,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [int]$PercentComplete
    )

    begin {
        ## Set percent value to two decimal places
        $perc = "{0:N0}" -f $PercentComplete

        ## Capture current console colors
        $curBackgroundColor = [System.Console]::BackgroundColor
        $curForegroundColor = [System.Console]::ForegroundColor
        if ($PSHOME -match "\:\\") {
            $tmpColors = "$env:TEMP\ConsoleColor.csv"
        }
        else {
            $tmpColors = "/tmp/ConsoleColor.csv"
        }

        [PSCustomObject]@{
            BackgroundColor = $curBackgroundColor
            ForegroundColor = $curForegroundColor
        } | Export-Csv -Path $tmpColors -NoTypeInformation -Force -Confirm:$false
    }
    process {
        $ErrorActionPreference = "Stop"
        try {
            switch ($host.Name) {
                "Visual Studio Code Host" {
                    ## Code PS Host Preview supports Write-Progress
                    if ($psEditor.EditorServicesVersion -ge "2.0.0.0") {
                        Write-Progress -Activity $Activity -PercentComplete $perc -Status "$perc%"
                    }
                    else {
                        $val = " $Activity $perc%    "
                        $CursorY = $host.UI.RawUI.CursorPosition.Y
                        [System.Console]::BackgroundColor = [System.ConsoleColor]::Cyan
                        [System.Console]::ForegroundColor = [System.ConsoleColor]::Black
                        [System.Console]::SetCursorPosition(0, $CursorY)
                        [System.Console]::Write($val)
                    }
                }
                Default {
                    Write-Progress -Activity $Activity -PercentComplete $perc -Status "$perc%"
                }
            }
        }
        catch {
            $_
        }
    }
    end {
        switch ($host.Name) {
            "Visual Studio Code Host" {
                ## Clear progress line in keeping with Write-Progress
                if ($psEditor.EditorServicesVersion -lt "2.0.0.0") {
                    $colors = Import-Csv -Path $tmpColors
                    $CursorY = $host.UI.RawUI.CursorPosition.Y
                    [System.Console]::BackgroundColor = [System.ConsoleColor]::($colors.BackgroundColor).ToString()
                    [System.Console]::ForegroundColor = [System.ConsoleColor]::($colors.ForegroundColor).ToString()
                    [System.Console]::SetCursorPosition(0, $CursorY)
                    [System.Console]::Write("")
                }
            }
        }
        ## Remove temp color file
        Remove-Item -Path $tmpColors -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}
