# Quickstart

## Quick Index
- [Mac OS](#mac-os)
- [Windows](#windows)
- [Linux and Unix](#linux-and-unix)
- [Verifying the OCI CLI Installation](#verifying-the-oci-cli-installation)
- [Setting up the Configuration File](#setting-up-the-configuration-file)


This section documents how to quickly install and configure the OCI Command Line Interface (CLI).

## Installing the CLI 🔗

### Mac OS 🔗

[Back to top](#quickstart)


You can use [Homebrew](https://docs.brew.sh/Installation) to install, upgrade, and uninstall the CLI on Mac OS.

To install the CLI on Mac OS with Homebrew:

Copy

```bash
brew update && brew install oci-cli
```

To upgrade your CLI install on Mac OS using Homebrew:

Copy

```bash
brew update && brew upgrade oci-cli
```

To uninstall the CLI on Mac OS using Homebrew:

Copy

```bash
brew uninstall oci-cli
```

### Windows 🔗

[Back to top](#quickstart)


You can install the CLI on Windows by using the MSI installer or by using PowerShell.

**To install the CLI on Windows using the MSI installer:**

**Note**  
  
The MSI CLI installer will overwrite any existing versions of the CLI on your Windows system. If you need to install multiple versions of the CLI, for subsequent installs create a virtual environment and use the manual installation method. For more information, see [Manual and Offline Installations](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/climanualinst.htm#climanualinst_intro).

1.  Download the latest [OCI CLI MSI installer](https://github.com/oracle/oci-cli/releases/download/v3.63.3/oci-cli-3.63.3-Windows-Server-Installer.msi) for Windows from [GitHub](https://github.com/oracle/oci-cli/releases).
2.  Run the downloaded installer executable.
3.  Select the local directory on your system where you want to install the CLI, and then select **Next**.
4.  When the installer is finished, select **Finish**.

**To install the CLI on Windows using PowerShell:**

1.  Open the PowerShell console using the **Run as Administrator** option.
2.  The installer enables auto-complete by installing and running a script. To allow this script to run, you must enable the RemoteSigned execution policy.
    
```bash
To configure the remote execution policy for PowerShell, run the following command.
```
    
```bash
Copy
```
    
```bash
Set-ExecutionPolicy RemoteSigned
```
    
3.  Force PowerShell to use TLS 1.2 for Windows 2012 and Windows 2016:
    
```bash
Copy
```
    
```bash
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```
    
4.  Download the installer script:
    
```bash
Copy
```
    
```bash
Invoke-WebRequest https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.ps1 -OutFile install.ps1
```
    
5.  Run the installer script with or without prompts:
```bash
1.  To run the installer script _with_ prompts, run the following command:
```
        
```bash
Copy
```
        
```bash
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.ps1'))
```
        
```bash
Respond to the [Installation Script Prompts](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#InstallingCLI__PromptsInstall).
```
        
```bash
2.  To run the installer script _without_ prompting the user, accepting the default settings, run the following command:
```
        
```bash
Copy
```
        
```bash
./install.ps1 -AcceptAllDefaults
```
        

### Linux and UNIX 🔗

[Back to top](#quickstart)


**Note**  
  
The installer script automatically installs the CLI and its dependencies, Python and virtualenv. Before running the installer, be sure you meet the [requirements](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm#Requirements).

**Note**  
  
Oracle Linux 8 and Oracle Linux Cloud Developer 7 have the CLI pre-installed.

1.  Open a terminal.
2.  To run the installer script, run the following command:
    
```bash
Copy
```
    
```bash
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```
    
```bash
**Note**
```
      
```bash
To run a 'silent' install that accepts all default values with no prompts, use the `--accept-all-defaults` parameter.
```
    
3.  Respond to the [Installation Script Prompts](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#InstallingCLI__PromptsInstall).

### Verifying the OCI CLI Installation 🔗

[Back to top](#quickstart)


1.  From a command prompt, run the following command:
    
```bash
oci --version
```
    

## Setting up the Configuration File 🔗

[Back to top](#quickstart)


Before using the CLI, you must create a configuration file that contains the required credentials for working with Oracle Cloud Infrastructure. You can create this file using a setup dialog or manually using a text editor.

### Use the Setup Dialog 🔗

To have the CLI guide you through the first-time setup process, use the `setup config` command:

```bash
oci setup config
```

This command prompts you for the information required to create the configuration file and the API public and private keys. The setup dialog uses this information to generate an API key pair and creates the configuration file. After API keys are created, [upload the public key using the Console](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#three).

For more information about how to find the required information, see:

-   [Required Keys and OCIDs.](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#Required_Keys_and_OCIDs)
-   [Where to Get the Tenancy's OCID and User's OCID](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five)
-   [Regions and Availability Domains](https://docs.oracle.com/iaas/Content/General/Concepts/regions.htm)

### Manual Setup

If you want to set up the API public/private keys yourself and write your own config file, see [SDK and Tool Configuration](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdkconfig.htm#SDK_and_CLI_Configuration_File).

**Tip**  
  

Use the `oci setup keys` command to generate a key pair to include in the config file.

### Verifying the Configuration File 🔗

**Make Sure Your Configuration File Is Complete**

A proper configuration file should have at least one profile name (such as `[DEFAULT]`) and the entries specified in the [File Entries](https://docs.oracle.com/iaas/Content/API/Concepts/sdkconfig.htm#File_Entries) section: user, fingerprint, key\_file, tenancy, region, and an optional pass\_phrase.

**Note**  
  
See the [Example Configuration](https://docs.oracle.com/iaas/Content/API/Concepts/sdkconfig.htm#Example_Configuration) section for an example configuration file.

**Confirm Your User and Fingerprint Information**

You can confirm your user and fingerprint information by logging onto the OCI console, opening the profile menu in the upper right, and then selecting your user name.

Once you selected your user name, you will see your OCID in the User Information panel. This OCID should be the user entry in your configuration file.

You can find your fingerprint by navigating to the **API Keys** section under the **Resources** column on the lower left.

**Adding Comments to the Configuration File**

Be sure not to add in-line comments to your configuration file. Add all comments on a new line. For example:

```bash
[DEFAULT]
```
```bash
user=ocid1.user.oc1..<unique_ID>
```
```bash
fingerprint=<your_fingerprint>
```
```bash
key_file=~/.oci/oci_api_key.pem
```
```bash
tenancy=ocid1.tenancy.oc1..<unique_ID>
```
```bash
# Some comment
```
```bash
region=us-ashburn-1
```
