# Check for failed logins 
GET-EVENTLOG -Logname Security | where { $_.EntryType -eq 'FailureAudit' }