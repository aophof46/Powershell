. (Join-Path -Path (Split-Path $profile) -ChildPath Microsoft.PowerShell_profile.ps1)


# $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.VSCode_profile.ps1

# Command taken from https://www.reddit.com/r/PowerShell/comments/6oesbz/visual_studio_code_script_signing/
Register-EditorCommand -Name SignCurrentScript -DisplayName 'Sign Current Script' -ScriptBlock {
    $cert = (Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
    $currentFile = $psEditor.GetEditorContext().CurrentFile.Path
    Set-AuthenticodeSignature -Certificate $cert -FilePath $currentFile
}
