# Load the required assembly
[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\WpfAnimatedGif.dll") | Out-Null
# Credits to - https://github.com/XamlAnimatedGif/WpfAnimatedGif

# Add necessary types
Add-Type -AssemblyName PresentationFramework, WindowsBase, PresentationCore

# Function to check if the current user is an administrator
function IsAdministrator {
    try {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        Write-Warning "Unable to determine if the session is running as administrator."
        return $false
    }
}

# Function to disable or enable user input
function Disable-UserInput {
    [CmdletBinding()]
    param(
        [switch]$On,
        [switch]$Off
    )

    $code = @'
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
'@

    $userInput = Add-Type -MemberDefinition $code -Name Blocker -Namespace UserInput -PassThru

    if ($On) {
        $null = $userInput::BlockInput($true)
    } elseif ($Off) {
        $null = $userInput::BlockInput($false)
    }
}

# Function to start the splashWizard
function Start-SplashWizard {
    [CmdletBinding()]
    param(
        [switch]$TopMost,
        [switch]$NoCursor,
        [string]$HeaderText = "Starting...",
        [string]$BodyText = "Initializing...",
        [string]$StatusText = "..."
    )

    $currentDirectory = Get-Variable -Name PSScriptRoot -ValueOnly

    # Create and configure the PowerShell runspace
    $Global:syncHash = [hashtable]::Synchronized(@{})
    $newRunspace = [runspacefactory]::CreateRunspace()
    $newRunspace.ApartmentState = "STA"
    $newRunspace.ThreadOptions = "ReuseThread"
    $newRunspace.Open()
    $newRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)

    # Create the PowerShell script block with the formatted XAML
    $psCmd = [PowerShell]::Create().AddScript({
        [XML]$xaml = @"
<Window 
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  xmlns:sys="clr-namespace:System;assembly=mscorlib"
  xmlns:gif="http://wpfanimatedgif.codeplex.com"
  Title="SplashWizard"
  Cursor="Wait"
  Width="400" Height="200"
  WindowStartupLocation="CenterScreen"
  WindowStyle="None"
  AllowsTransparency="True"
  WindowState="Maximized"
  ShowInTaskbar="False" 
  Background="#FFFFFF"
  Foreground="#161616">
  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/>
      <RowDefinition Height="75"/>
    </Grid.RowDefinitions>
    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
      <TextBlock x:Name="TextMessageHeader" Text="$HeaderText" FontSize="32" FontWeight="Bold" TextAlignment="Center" />
      <TextBlock x:Name="TextMessageBody" Text="$BodyText" FontSize="16" TextWrapping="Wrap" TextAlignment="Center" FontStyle="Italic" Margin="0,20,0,20" />
      <TextBlock x:Name="TextMessageStatus" Text="$StatusText" FontSize="18" FontWeight="Bold" TextAlignment="Center"/>
      <Image x:Name="Spinner" VerticalAlignment="Center" Margin="30" Height="64" Width="64" Visibility="Hidden" />
    </StackPanel>
  </Grid>
</Window>
"@

        # Load XAML and create the window
        $reader = (New-Object System.Xml.XmlNodeReader $xaml)
        $syncHash.Window = [Windows.Markup.XamlReader]::Load($reader)

        $syncHash.TextMessageHeader = $syncHash.Window.FindName("TextMessageHeader")
        $syncHash.TextMessageBody = $syncHash.Window.FindName("TextMessageBody")
        $syncHash.TextMessageStatus = $syncHash.Window.FindName("TextMessageStatus")
        $syncHash.ImageView = $syncHash.Window.FindName("Spinner")

        $syncHash.TextMessageHeader.Text = $HeaderText
        $syncHash.TextMessageBody.Text = $BodyText
        $syncHash.TextMessageStatus.Text = $StatusText

        $syncHash.Window.ShowDialog() | Out-Null
        $syncHash.Error = $Error
    })

    $psCmd.Runspace = $newRunspace
    $data = $psCmd.BeginInvoke()

    Start-Sleep 1

    if ($TopMost) {
        $syncHash.Window.Dispatcher.Invoke([action]{$syncHash.Window.TopMost = $true}, "Render")
        if (IsAdministrator) {
            Disable-UserInput -On
        }
    }

    if ($NoCursor) {
        $syncHash.Window.Dispatcher.Invoke([action]{$syncHash.Window.Cursor = "None"}, "Render")
    }

    # Load animated gif
    $gifPath = "$currentDirectory\spinner.gif"
    $syncHash.Window.Dispatcher.Invoke([action]{
        [WpfAnimatedGif.ImageBehavior]::SetAnimatedSource($syncHash.ImageView, [System.Windows.Media.Imaging.BitmapImage]::new([System.Uri]::new($gifPath)))
    }, "Normal")

    Update-SplashWizard -HeaderText $HeaderText -BodyText $BodyText -StatusText $StatusText

    Start-Sleep 5
}

# Function to update the splash screen text blocks
function Update-SplashWizard {
    param (
        [string]$HeaderText,
        [string]$BodyText,
        [string]$StatusText
    )

    $syncHash.Window.Dispatcher.Invoke([action]{
        $syncHash.ImageView.Visibility = "Visible"
        $syncHash.TextMessageHeader.Text = $HeaderText
        $syncHash.TextMessageBody.Text = $BodyText
        $syncHash.TextMessageStatus.Text = $StatusText
    }, "Normal")
}

# Function to close the splash screen
function Close-SplashWizard {
    param (
        [string]$HeaderText,
        [string]$BodyText,
        [string]$StatusText,
        [int]$Countdown
    )

    if (($Countdown -eq $null) -or ($Countdown -eq 0)) {
        $syncHash.TextMessageBody.Dispatcher.Invoke([action]{
            $syncHash.TextMessageHeader.Text = $HeaderText
            $syncHash.TextMessageBody.Text = $BodyText
            $syncHash.TextMessageStatus.Text = $StatusText
        }, "Normal")

        $syncHash.Window.Dispatcher.Invoke([action]{$syncHash.Window.Close()}, "Normal")
        Disable-UserInput -Off
    } elseif ($Countdown -gt 0) {
        while ($Countdown -gt 0) {
            Start-Sleep -Seconds 1
            $Countdown--

            $syncHash.TextMessageBody.Dispatcher.Invoke([action]{
                $syncHash.TextMessageHeader.Text = "Rebooting in : $Countdown"
                $syncHash.TextMessageBody.Text = ""
                $syncHash.TextMessageStatus.Text = ""
            }, "Normal")
        }

        $syncHash.Window.Dispatcher.Invoke([action]{$syncHash.Window.Close()}, "Normal")
        Disable-UserInput -Off
    }
}
