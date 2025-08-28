# Installing Cybereason Version 23.1 and Later on Windows Server 2019

This guide provides step-by-step instructions for installing Cybereason version 23.1 or later on Windows Server 2019. It includes prerequisites, required Windows updates, certificate management, and automation scripts.

---

## Quick Start

If the server has internet access and you want everything handled automatically, open **PowerShell as Administrator** in this folder and run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ./Combined_Certificate_Windows_Update_Installation_Script.ps1
```

The combined script downloads the required Windows updates and trusted root certificates, installs them, and prepares the system for Cybereason installation.

---

## Repository Contents

- **Combined_Certificate_Windows_Update_Installation_Script.ps1**  
  One-click automation that downloads and installs both Windows KBs and the required root certificates.

- **Install_Win_Updates_Windows_2019.ps1**  
  Installs the Servicing Stack Update (SSU) and the Latest Cumulative Update (LCU) to bring Windows Server 2019 to the minimum supported build.

- **install_certs.ps1**  
  Installs the required trusted root CAs into the Local Machine Trusted Root store.

- **DigiCertGlobalRootCA.cer**, **GeoTrustRSACA2018.cer**, **MicrosoftIdentityVerificationRootCA2020.cer**  
  Certificates required for sensor installation and operation.

---

## Prerequisites

1. **Windows OS Requirements**
   - Minimum OS Build: `17763.2210`
   - To check the current OS version, run:
     ```powershell
     systeminfo | findstr /B /C:"OS Version"
     ```
   - If the build is below `17763.2210`, follow **Step 1**.

2. **Certificates Required**
   - Microsoft Identity Verification Root Certificate Authority 2020  
   - DigiCertGlobalRootCA.cer  
   - GeoTrustRSACA2018.cer  

---

## Step 1: Updating Windows OS Build (only if below 17763.2210)

You can update Windows manually or use the provided script.

### Manual Update

1. **Install Servicing Stack Update (SSU)**  
   August 10, 2021 SSU (KB5005112)  
   [Download KB5005112](https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/secu/2021/08/windows10.0-kb5005112-x64_81d09dc6978520e1a6d44b3b15567667f83eba2c.msu)

2. **Install Latest Cumulative Update (LCU)**  
   September 21, 2021 (KB5005625)  
   [Download KB5005625](https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/updt/2021/09/windows10.0-kb5005625-x64_9a7d6abe389d940e08d759243c981670c33c71f5.msu)

### Using Script (Recommended)

Run the included script to install the required updates automatically:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ./Install_Win_Updates_Windows_2019.ps1
```

---

## Step 2: Installing Certificates

You can install certificates manually or use the provided script.

### Manual Certificate Installation

1. Verify the following certificates are installed:
   - Microsoft Identity Verification Root Certificate Authority 2020  
   - DigiCertGlobalRootCA.cer  
   - GeoTrustRSACA2018.cer  

2. If missing, download from:
   - [DigiCert Trusted Root Authority Certificates](https://www.digicert.com/kb/digicert-root-certificates.htm)  
   - [Sectigo Root & Intermediate Certificates](https://support.sectigo.com/articles/Knowledge/Sectigo-Intermediate-Certificates)  
   - [Microsoft Identity Verification Root Certificate Authority 2020](https://www.microsoft.com/pkiops/certs/microsoft%20identity%20verification%20root%20certificate%20authority%202020.crt)

3. Install certificates manually with:
   ```powershell
   certutil -addstore "Root" "<certificate_path>"
   ```

### Using Script (Recommended)

Run the certificate installation script:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ./install_certs.ps1
```

---

## Step 3: Combined Installation Option

For convenience, you can run the **Combined Certificate & Update Installation Script**, which will automatically download and install both the certificates and Windows KB updates:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ./Combined_Certificate_Windows_Update_Installation_Script.ps1
```

This ensures all prerequisites are handled in a single step.

---

## Step 4: Installing Cybereason

After ensuring the OS build is updated and certificates are installed, run the Cybereason installer and follow the standard installation process for version 23.1 or later.

---

## Troubleshooting

- Verify all prerequisites are completed before starting the installation.  
- If issues persist, check the [Cybereason Knowledge Base](https://www.nest.cybereason.com).

---

> **Tip:** You can run scripts individually (Step 1 and Step 2) or use the combined script for full automation.
