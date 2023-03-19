# cheat codes 2

a sample playground for norns

### hard requirements:

- norns (221214 or later)

### encouraged (any or all):

- grid (64 or 128, all editions -- 256 works as well, just half)
- arc 4 (works with 2, but only two banks of control)
- Launchpad (X, Pro or Mini MK3) for [midigrid compatibility](https://github.com/jaggednz/midigrid)
- MIDI keyboard, MIDI button box, OP-Z (see below)
- [TouchOSC (mk1)](https://llllllll.co/uploads/short-url/k2XPQ0ehvcj6W9DuEYu1vlRo60P.touchosc)
- Midi Fighter Twister ([template](https://llllllll.co/uploads/short-url/so1QoxfHVWn29a4YNkybdVEIQgi.mfs))
- Max for Live ([device](https://llllllll.co/uploads/short-url/cckkpyWjH3ywfaHfYzOmV27GS3m.amxd))
- crow for pad-to-trigger or Just Friends + w/ note output
- [any of the `nb` library mods](https://llllllll.co/t/n-b-et-al-v0-1/60374)

### [documentation](https://github.com/dndrks/cheat-codes-docs/raw/main/assets/images/pdf/cheat_codes_2.pdf)

### [discussion](https://l.llllllll.co/cheat-codes-2)

---

#### OP-Z setup notes

you’ll need to make some adjustments to OP-Z’s MIDI settings, so grab a screen and navigate to the OP-Z’s MIDI SETUP menus!

for globals, make only the following active:

*MIDI IN ENABLE*  
*MIDI OUT ENABLE*  
*CLOCK IN ENABLE*  
*CLOCK OUT ENABLE*  

then, you’ll want to choose three tracks to control the three banks of cheat codes. how you set that up will depend on your end-goals, but make sure you take note of the midi channels for each track. if you’ve never edited the MIDI channel assignments for the tracks on your OP-Z, they’re likely set up as 1-16 – double check in the app, though!

you may also want to disable the OP-Z feature where changing tracks make a little “preview” sound of the instrument. if you connect to OP-Z using disk mode, there’s a config > general.json file you can edit. change "disable track preview" to true !

plug your op-z into norns using the USB-C charge cable. you should see OP-Z in your SYSTEM > DEVICES > MIDI list. please take note of which port it’s on (1/2/3/4).

in cc2’s PARAMS, go to MIDI setup :

enable MIDI control? yes  
MIDI control device whatever port your OP-Z is on  
enable MIDI echo? yes, this allows the encoders on OP-Z to be used like arc!  

from there, you’ll want to set the bank MIDI channels to match the tracks from the OP-Z. they’re defaulted to 1/2/3, which on a factory-set OP-Z are the first, second, and third tracks.
