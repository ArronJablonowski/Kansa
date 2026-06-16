Get-WmiObject win32_process | ForEach-Object {

    # Create a custom object with the given properties. If Select-Object doesn't find given property it'll create an empty `NoteProperty` with the given name
    $processInfo = $_ | Select-Object creationdate,ws,ProcessName,ProcessID,ParentProcessID, ParentProcessName,Path,CommandLine,ParentProcessPath
    $p = (Get-Process -Id $_.ParentProcessId -ErrorAction SilentlyContinue) 

    if ($null -ne $p){
        # Parent process exists lets fill up the empty properties
        $processInfo.ParentProcessName = $p.Name
        $processInfo.ParentProcessPath = $p.Path
    }

    $processInfo # Return this value to the pipeline
} 