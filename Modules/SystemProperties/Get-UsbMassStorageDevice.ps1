# This Script will get Mass Storage Device Info 
#
# Description             DeviceID
# -----------             --------
# USB Mass Storage Device USB\VID_0DD8&PID_3200\<serial number displayed here>


gwmi Win32_USBControllerDevice |%{[wmi]($_.Dependent)} | Where-Object {($_.Description -like '*mass*')} | Sort Description,DeviceID | ft Description,DeviceID –auto