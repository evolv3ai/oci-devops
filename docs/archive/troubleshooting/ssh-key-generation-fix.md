# SSH Key Generation for Semaphore UI + Oracle Cloud

## The 400 Error Issue
The "Request failed with status code 400" happens because:
1. **Invalid key format** - Key must be proper OpenSSH format
2. **Missing headers** - Private keys need proper BEGIN/END markers
3. **Truncated content** - Your key appears incomplete

## Option 1: Git Bash (Easiest)
If you have Git installed:

1. Open **Git Bash**
2. Create SSH directory:
   ```bash
   mkdir -p ~/.ssh
   ```
3. Generate key pair:
   ```bash
   ssh-keygen -t rsa -b 2048 -f ~/.ssh/semaphore-oci-key -N ""
   ```
4. View private key:
   ```bash
   cat ~/.ssh/semaphore-oci-key
   ```
5. View public key:
   ```bash
   cat ~/.ssh/semaphore-oci-key.pub
   ```

## Option 2: PuTTY Key Generator

1. **Download PuTTY** from https://www.putty.org/
2. **Run PuTTYgen.exe**
3. **Settings:**
   - Type: RSA
   - Bits: 2048
4. **Click "Generate"** and move mouse
5. **Save private key** (click "Save private key", say No to passphrase)
6. **Convert to OpenSSH format:**
   - Copy the text from "Public key for pasting into OpenSSH authorized_keys file"
   - Use Conversions > Export OpenSSH key for private key

## Option 3: Online SSH Key Generator (Testing Only)
For testing purposes only:
1. Go to https://travistidwell.com/jsencrypt/demo/
2. Generate RSA key pair
3. Copy the PRIVATE KEY section

## Option 4: Windows Subsystem for Linux (WSL)
If you have WSL installed:
```bash
wsl ssh-keygen -t rsa -b 2048 -f ~/.ssh/semaphore-oci-key -N ""
```

## Proper Private Key Format
Your private key should look like this:

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAFwAAAAdz
c2gtcnNhAAAAAwEAAQAAAQEA2K8jQ9F5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5
[many more lines of base64 encoded data]
-----END OPENSSH PRIVATE KEY-----
```

## Public Key Format
Your public key should look like this:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY... user@hostname
```

## Troubleshooting Semaphore SSH Issues

### Fix the Container SSH Setup
After creating your keys, you'll need to fix the Semaphore container SSH setup:

```bash
# Find container ID
docker ps | grep semaphore

# Fix SSH directory (replace CONTAINER_ID)
docker exec CONTAINER_ID mkdir -p /home/semaphore/.ssh
docker exec CONTAINER_ID chown -R semaphore:semaphore /home/semaphore/.ssh
docker exec CONTAINER_ID chmod 700 /home/semaphore/.ssh
docker exec CONTAINER_ID touch /home/semaphore/.ssh/known_hosts
docker exec CONTAINER_ID chmod 644 /home/semaphore/.ssh/known_hosts
```

### Add OCI Host Keys
For each OCI instance IP:
```bash
docker exec CONTAINER_ID ssh-keyscan -H YOUR_OCI_IP >> /home/semaphore/.ssh/known_hosts
```

## Next Steps After Key Generation
1. **Add public key to OCI instances**
2. **Use private key content in Semaphore Key Store**
3. **Username should be "opc" for Oracle Linux**
4. **Leave passphrase empty**
5. **Run the SSH fix script**

## Testing Your Key
Before using in Semaphore, test the key:
```bash
ssh -i ~/.ssh/semaphore-oci-key opc@YOUR_OCI_IP
```
