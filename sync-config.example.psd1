@{
  # Your private data repo, as owner/repo.
  repo = 'you/your-context-data'

  # project folder in the data repo  ->  where it lands on this PC
  map = @{
    example = 'C:\path\to\wherever\you\want\it'
  }

  # Extra files a destination holds that the data repo does not, beyond the four
  # the script already protects. /MIR deletes anything in a destination that is
  # not in the matching contexts/ folder and not listed here.
  keep = @()

  # Where this machine fetches pull-context.ps1 on every run. Omit this key for
  # the default, which is the public claude_link repo -- meaning the script
  # updates itself from code you do not control.
  #
  #   engineUrl = ''                          pin the current script, never update
  #   engineUrl = 'https://raw.git.../...'    update from your own copy instead
  #
  # This lives here, not in the script, because the script overwrites itself.
}
