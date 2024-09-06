# SplashWizard

SplashWizard is a PowerShell script designed to display a customizable splash screen during script execution. It includes features such as topmost window display, cursor hiding, and animated GIF support.

# Features
* Display a splash screen with customizable header, body, and status text.  
* Option to make the splash screen topmost.
* Option to hide the cursor.  
* Support for animated GIFs.  
* Ability to disable user input while the splash screen is active.  
# Prerequisites
PowerShell 5.0 or later.  
.NET Framework 4.5 or later.   
WpfAnimatedGif.dll (included in the script directory) Credit to https://github.com/XamlAnimatedGif/WpfAnimatedGif  
# Installation
Download the SplashWizard.ps1 script and place it in your desired directory.
Ensure WpfAnimatedGif.dll is in the same directory as the script.
Usage
Basic Usage
To display the splash screen with default text:

.\SplashWizard.ps1

# Initialising the SplashWizard
You can customize the header, body, and status text:

#### Start-SplashWizard -HeaderText "Welcome!" -BodyText "Loading resources..." -StatusText "Please wait..."

**Topmost Window**  
To make the splash screen always on top, if run in Administrator context it will also disable user input:

Start-SplashWizard -TopMost

**Hide Cursor**  
To hide the cursor while the splash screen is displayed:

Start-SplashWizard -NoCursor

**Full Example**
A full example with all options:

Start-SplashWizard -HeaderText "Welcome!" -BodyText "Loading resources..." -StatusText "Please wait..." -TopMost -NoCursor

### Functions
**Start-SplashWizard -HeaderText "Welcome!" -BodyText "Loading resources..." -StatusText "Please wait..." -TopMost -NoCursor**  
Starts the splash screen with the specified parameters.
 

**Update-SplashWizard -HeaderText "Updating!" -BodyText "Updating somethings..." -StatusText "Please wait..."**  
Updates the text on the splash screen.

**Close-SplashWizard  -HeaderText "Updating!" -BodyText "Updating somethings..." -StatusText "Please wait... -Countdown 10"**  
Closes the splash screen, optionally with a countdown.

Example Script
Here’s an example script that uses SplashWizard: 

        .\SplashWizard.ps1

        # Load the splash screen
        Start-SplashWizard -HeaderText "Starting Up" -BodyText "Initializing components..." -StatusText "Loading..." -TopMost -NoCursor
        
        # Simulate some work
        Start-Sleep -Seconds 10
        
        # Update the splash screen
        Update-SplashWizard -HeaderText "Almost There" -BodyText "Finalizing setup..." -StatusText "Just a moment..."
        
        # Simulate more work
        Start-Sleep -Seconds 5
        
        # Close the splash screen
        Close-SplashWizard -HeaderText "Done!" -BodyText "Setup complete." -StatusText "Ready to go!" -Countdown 3

License
This project is licensed under the MIT License.

Contributing
Feel free to submit issues or pull requests if you have suggestions or improvements.

Contact
For any questions or feedback, please contact.
