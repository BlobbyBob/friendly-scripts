# Friendly Scripts

Just some nice scripts that might help you in your everyday life.

## Contents

#### AudioSwitch

The AudioSwitch can be assigned to a shortcut and cycles through the speakers of your choice.

#### Backup

The backup scripts consist of three files:
- `backup.service`: Systemd unit running on shutdown, calling `backup-sched.sh`
- `backup-sched.sh`: Calling `backup.sh` depending on the time passed since last backup
- `backup.sh`: Performing an incremental or full backup on a certain partition
