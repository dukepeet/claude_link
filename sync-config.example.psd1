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
}
