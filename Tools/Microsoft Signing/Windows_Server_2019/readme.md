# Installing Cybereason Version 23.1 and Later on Windows Server 2019

This guide provides step-by-step instructions for installing Cybereason version 23.1 or later on Windows Server 2019. It includes prerequisites, necessary updates, and guidance on managing required certificates.

---

## **Prerequisites**

1. **Windows OS Requirements:**
   - **Minimum OS Build:** `17763.2210`
   - To check the current OS version, run the following command in PowerShell:
     ```powershell
     systeminfo | findstr /B /C:"OS Version"
     ```
   - If the build is below `17763.2210`, follow the update process outlined in **Step 1**.

2. **Certificates Required:**
   - **Microsoft Identity Verification Root Certificate Authority 2020**
   - **DigiCertGlobalRootCA.cer**
   - **GeoTrustRSACA2018.cer**

---

## **Step 1: Updating Windows OS Build - only if below 17763.2210**

1. **Check and Install Servicing Stack Update (SSU):**
   - Ensure the **August 10, 2021 SSU (KB5005112)** is installed.  
     Download and install it from [KB5005112](https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/secu/2021/08/windows10.0-kb5005112-x64_81d09dc6978520e1a6d44b3b15567667f83eba2c.msu).

2. **Install Latest Cumulative Update (LCU):**
   - Install the **September 21, 2021 (KB5005625)** LCU to upgrade your build to `17763.2210`.
     - Download from [KB5005625](https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/updt/2021/09/windows10.0-kb5005625-x64_9a7d6abe389d940e08d759243c981670c33c71f5.msu).

---

## **Step 2: Installing Certificates**

1. **Verify Existing Certificates:**
   - Check for the following certificates on the endpoint:
     - **Microsoft Identity Verification Root Certificate Authority 2020**
     - **DigiCertGlobalRootCA.cer**
     - **GeoTrustRSACA2018.cer**
   - If any are missing, download them from:
     - [DigiCert Trusted Root Authority Certificates](https://www.digicert.com/kb/digicert-root-certificates.htm)
     - [Sectigo Root & Intermediate Certificates](https://support.sectigo.com/articles/Knowledge/Sectigo-Intermediate-Certificates)
     - [Microsoft Identity Verification Root Certificate Authority 2020](https://www.microsoft.com/pkiops/certs/microsoft%20identity%20verification%20root%20certificate%20authority%202020.crt)

2. **Install Missing Certificates:**
   - Use the provided `.bat` script (attached to this repository) to automate certificate installation:
     ```batch
     certutil -addstore "Root" "<certificate_path>"
     ```
   - Replace `<certificate_path>` with the location of the downloaded `.cer` files.
  
   - Or use the added script: 
     ```
     powershell.exe -ExecutionPolicy Bypass -File ./install_certs.ps1
     ```

---

## **Step 3: Installing Cybereason**

1. After ensuring the OS build is updated and certificates are installed:
   - Run the Cybereason installer and follow the standard installation process for version 23.1 or later.

---

## **Troubleshooting**

- Ensure all prerequisites are met before starting the Cybereason installation.  
- If issues persist, refer to the [Cybereason Knowledge Base](https://www.nest.cybereason.com) for additional support.

---

> **Disclaimer:** For any issues with certificate downloads or updates, contact your system administrator or Cybereason support.
