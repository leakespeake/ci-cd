# RSYNC BACKUPS
rsync is a fast and very versatile file copying tool. It can copy locally, to/from another host over any remote shell, or to/from a remote rsync daemon. It offers a large number of options that control every aspect of its behavior and permit very flexible specification of the set of files to be copied. 

It is famous for its delta-transfer algorithm, which reduces the amount of data sent over the network by sending only the differences between the source files and the existing files in the destination. rsync can be used for mirroring data, incremental backups, copying files between systems and as a superior and faster replacement for scp, sftp, and cp commands.

## NAS Considerations
For the homelab scenario, most will be utilizing their NAS device as their rsync backup destination of choice. For a Terramaster, some pre-requisities will be;

- before you enable rsync on the NAS, you first need to enable the SSH service because rsync uses the SSH protocol for syncing files between your computer and the NAS
- create a new Shared Folder on the NAS with appropriate permissions - /rsync-backups/
- create a new user 'rsync' with read/write to /rsync-backups/
- enable the Rsync Server on the NAS - setting 'rsync' account creds and authorized directory as /rsync-backups/
- enable telnet on the NAS temporarily, then use `telnet 10.1.1.10` to test our 'rsync' account and verify the full folder path (we see that rsync-backups exists at /mnt/rsync-backups/)
- you may also need to add the 'rsync' user to the `AllowUsers` line in **/etc/ssh/sshd_config** then restart ssh daemon by turning it off and on again via the UI
- turn off telnet and ssh services when not in use

## Usage
First append the `-n` flag to perform a dry run to test that the rsync command is working - the NAS should prompt you for the 'rsync' password;
```
rsync -avhn --progress -e 'ssh -p 9222' /home/$USER/tmp/ rsync@10.1.1.10:/mnt/rsync-backups/tmp/
```
Note `-p 9222` as we are using a non-standard ssh port on the NAS for security.

Then the real deal, first FULL backup - the rest are incremental;
```
rsync -avh --progress -e 'ssh -p 9222' /home/$USER/tmp/ rsync@10.1.1.10:/mnt/rsync-backups/tmp/
```
Use `man rsync` for the full options summary of flags to use with the rsync command to tailor it to any given scenario. The most commonly used are;
- **-a** (archive) - run recursively and retain file metadata such as timestamp, owner and group permissions, and symbolic links (if any)
- **-v** (verbose) - to see everything rsync is doing in the terminal

## Example - Git Repository Backup 
DRY RUN
```
rsync -avhn --progress -e 'ssh -p 9222' /mnt/c/Users/$USER/Documents/github-leakespeake/ansible/ rsync@10.1.1.10:/mnt/rsync-backups/github-leakespeake/ansible/
```
FIRST FULL BACKUP (prior to subsequent incremental backups)
```
rsync -avh --progress -e 'ssh -p 9222' /mnt/c/Users/$USER/Documents/github-leakespeake/ansible/ rsync@10.1.1.10:/mnt/rsync-backups/github-leakespeake/ansible/
```
OTHER DIRECTORIES
```
rsync -avh --progress -e 'ssh -p 9222' /mnt/c/Users/$USER/Documents/github-leakespeake/docker/ rsync@10.1.1.10:/mnt/rsync-backups/github-leakespeake/docker/
rsync -avh --progress -e 'ssh -p 9222' /mnt/c/Users/$USER/Documents/github-leakespeake/packer/ rsync@10.1.1.10:/mnt/rsync-backups/github-leakespeake/packer/
```
EXCLUDING PARTICULAR FILES AND FILE TYPES (useful for Terraform repos with its .exe plugin architecture)
```
rsync -avh --exclude '*.exe' --exclude '*terraform.txt' -e 'ssh -p 9222' /mnt/c/Users/$USER/Documents/github-leakespeake/terraform-projects/ rsync@10.1.1.10:/mnt/rsync-backups/github-leakespeake/terraform-projects

rsync -avh --exclude '*.exe' --exclude '*terraform.txt' -e 'ssh -p 9222' /mnt/c/Users/$USER/Documents/github-leakespeake/terraform-reusable-modules/ rsync@10.1.1.10:/mnt/rsync-backups/github-leakespeake/terraform-reusable-modules/
```